import pako from 'pako'
import { Argon2KDF } from '../crypto/argon2KDF'
import { AESGCM } from '../crypto/aesGCM'
import { HMACSHA256 } from '../crypto/hmacSHA256'
import { SecureRandom } from '../crypto/secureRandom'
import { Note, NotePayload } from '../../domain/entities/types'

/**
 * .vnc file format parser and writer
 */
export class VNCFormat {
  static readonly magic = [0x56, 0x4e, 0x43, 0x01] // "VNC\x01"
  static readonly version = 1
  static readonly headerSize = 128
  static readonly kdfParamsSize = 16
  static readonly saltSize = 32
  static readonly ivSize = 12
  static readonly authTagSize = 16
  static readonly hmacSize = 32

  static readonly flagCompressed = 1
  static readonly flagHasLabel = 2
  static readonly flagContainer = 4

  /**
   * Encrypt and serialize a note to .vnc format
   */
  static async encryptNote(
    note: Note,
    key: Uint8Array,
    hmacKey: Uint8Array
  ): Promise<Uint8Array> {
    // Create payload
    const payload: NotePayload = {
      id: note.id,
      title: note.title,
      body: note.body,
      labels: note.labels,
      color: note.color,
      created: note.created,
      modified: note.modified,
      pinned: note.pinned,
      archived: note.archived,
    }

    const jsonString = JSON.stringify(payload)

    // Compress
    const compressed = pako.gzip(jsonString)

    // Generate fresh salt and IV per save
    const salt = SecureRandom.bytes(this.saltSize)
    const iv = SecureRandom.bytes(this.ivSize)

    // Encrypt
    const { ciphertext, authTag } = await AESGCM.encrypt(compressed, key, iv)

    // Build file without HMAC
    const fileWithoutHmac = this.buildFile(salt, iv, ciphertext, authTag, this.flagCompressed | this.flagHasLabel)

    // Compute HMAC over entire file
    const hmac = await HMACSHA256.compute(fileWithoutHmac, hmacKey)

    // Combine everything
    const result = new Uint8Array(fileWithoutHmac.length + this.hmacSize)
    result.set(fileWithoutHmac, 0)
    result.set(hmac, fileWithoutHmac.length)

    return result
  }

  /**
   * Decrypt and parse a note from .vnc format
   */
  static async decryptNote(
    data: Uint8Array,
    key: Uint8Array,
    hmacKey: Uint8Array
  ): Promise<Note> {
    const minSize = this.headerSize + this.kdfParamsSize + this.saltSize + this.ivSize + this.authTagSize + this.hmacSize

    if (data.length < minSize) {
      throw new Error('Invalid .vnc file: too short')
    }

    // Verify magic
    for (let i = 0; i < 4; i++) {
      if (data[i] !== this.magic[i]) {
        throw new Error('Invalid .vnc file: bad magic')
      }
    }

    // Extract HMAC (last 32 bytes)
    const storedHmac = data.slice(data.length - this.hmacSize)
    const dataWithoutHmac = data.slice(0, data.length - this.hmacSize)

    // Verify HMAC
    const hmacValid = await HMACSHA256.verify(dataWithoutHmac, hmacKey, storedHmac)
    if (!hmacValid) {
      throw new Error('Invalid .vnc file: HMAC verification failed - file may be tampered')
    }

    // Extract IV
    const iv = data.slice(this.headerSize + this.kdfParamsSize + this.saltSize, this.headerSize + this.kdfParamsSize + this.saltSize + this.ivSize)

    // Extract ciphertext and auth tag
    const ciphertextStart = this.headerSize + this.kdfParamsSize + this.saltSize + this.ivSize
    const ciphertextEnd = data.length - this.hmacSize - this.authTagSize
    const ciphertext = data.slice(ciphertextStart, ciphertextEnd)
    const authTag = data.slice(ciphertextEnd, data.length - this.hmacSize)

    // Decrypt
    const decrypted = await AESGCM.decrypt(ciphertext, key, iv, authTag)

    // Decompress
    const decompressed = pako.ungzip(decrypted)
    const jsonString = new TextDecoder().decode(decompressed)

    // Parse JSON
    const json = JSON.parse(jsonString) as NotePayload
    return {
      id: json.id,
      title: json.title,
      body: json.body,
      labels: json.labels,
      color: json.color,
      created: json.created,
      modified: json.modified,
      pinned: json.pinned,
      archived: json.archived,
    }
  }

  /**
   * Build file structure without HMAC
   */
  private static buildFile(
    salt: Uint8Array,
    iv: Uint8Array,
    ciphertext: Uint8Array,
    authTag: Uint8Array,
    flags: number
  ): Uint8Array {
    const totalSize = this.headerSize + this.kdfParamsSize + this.saltSize + this.ivSize + ciphertext.length + this.authTagSize
    const result = new Uint8Array(totalSize)
    let offset = 0

    // Header (128 bytes)
    // Magic
    for (let i = 0; i < 4; i++) {
      result[offset++] = this.magic[i]
    }

    // Version (uint16 LE)
    result[offset++] = this.version & 0xff
    result[offset++] = (this.version >> 8) & 0xff

    // Flags (uint32 LE)
    result[offset++] = flags & 0xff
    result[offset++] = (flags >> 8) & 0xff
    result[offset++] = (flags >> 16) & 0xff
    result[offset++] = (flags >> 24) & 0xff

    // Reserved (bytes 10-127)
    offset = this.headerSize

    // KDF Params (16 bytes)
    // m_cost (uint32 LE)
    const mCost = Argon2KDF.memoryCost
    result[offset++] = mCost & 0xff
    result[offset++] = (mCost >> 8) & 0xff
    result[offset++] = (mCost >> 16) & 0xff
    result[offset++] = (mCost >> 24) & 0xff

    // t_cost (uint32 LE)
    const tCost = Argon2KDF.timeCost
    result[offset++] = tCost & 0xff
    result[offset++] = (tCost >> 8) & 0xff
    result[offset++] = (tCost >> 16) & 0xff
    result[offset++] = (tCost >> 24) & 0xff

    // p_cost (uint32 LE)
    const pCost = Argon2KDF.parallelism
    result[offset++] = pCost & 0xff
    result[offset++] = (pCost >> 8) & 0xff
    result[offset++] = (pCost >> 16) & 0xff
    result[offset++] = (pCost >> 24) & 0xff

    // Reserved (4 bytes)
    offset += 4

    // Salt (32 bytes)
    result.set(salt, offset)
    offset += this.saltSize

    // IV (12 bytes)
    result.set(iv, offset)
    offset += this.ivSize

    // Ciphertext
    result.set(ciphertext, offset)
    offset += ciphertext.length

    // Auth Tag (16 bytes)
    result.set(authTag, offset)

    return result
  }

  /**
   * Extract salt from .vnc file
   */
  static extractSalt(data: Uint8Array): Uint8Array {
    return data.slice(this.headerSize + this.kdfParamsSize, this.headerSize + this.kdfParamsSize + this.saltSize)
  }
}
