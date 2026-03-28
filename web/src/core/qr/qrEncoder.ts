import pako from 'pako'
import { Note } from '../../domain/entities/types'
import { Argon2KDF } from '../crypto/argon2KDF'
import { AESGCM } from '../crypto/aesGCM'
import { HMACSHA256 } from '../crypto/hmacSHA256'
import { SecureRandom } from '../crypto/secureRandom'

/**
 * QR Code encoder - converts note to encrypted QR chunks
 */
export class QREncoder {
  static readonly maxChunkSize = 600 // bytes per QR
  static readonly qrVersion = 'v1'

  /**
   * Export note as QR code strings
   */
  async exportNoteAsQR(note: Note, password: string): Promise<string[]> {
    // Serialize and compress
    const jsonString = JSON.stringify(note)
    const compressed = pako.gzip(jsonString)

    // Generate salt and IV
    const salt = SecureRandom.bytes(32)
    const iv = SecureRandom.bytes(12)

    // Derive key from password
    const key = await Argon2KDF.deriveKey(password, salt)

    // Encrypt
    const { ciphertext, authTag } = await AESGCM.encrypt(compressed, key, iv)

    // Compute HMAC
    const hmacKey = await this.deriveHmacKey(key)
    const dataToHmac = new Uint8Array([
      ...salt,
      ...iv,
      ...ciphertext,
      ...authTag,
    ])
    const hmac = await HMACSHA256.compute(dataToHmac, hmacKey)

    // Combine all data: salt + iv + ciphertext + authTag + hmac
    const fullData = new Uint8Array([
      ...salt,
      ...iv,
      ...ciphertext,
      ...authTag,
      ...hmac,
    ])

    // Split into chunks
    const chunks = this.splitIntoChunks(fullData, QREncoder.maxChunkSize)
    const total = chunks.length

    // Generate QR strings
    const qrStrings: string[] = []
    for (let i = 0; i < chunks.length; i++) {
      const header = `VNQ:${QREncoder.qrVersion}:${i + 1}/${total}`
      const encoded = this.base64UrlEncode(chunks[i])
      qrStrings.push(`${header}:${encoded}`)
    }

    return qrStrings
  }

  private splitIntoChunks(data: Uint8Array, chunkSize: number): Uint8Array[] {
    const chunks: Uint8Array[] = []
    for (let i = 0; i < data.length; i += chunkSize) {
      const end = Math.min(i + chunkSize, data.length)
      chunks.push(data.slice(i, end))
    }
    return chunks
  }

  private async deriveHmacKey(masterKey: Uint8Array): Promise<Uint8Array> {
    const hmacKeySeed = new TextEncoder().encode('VNC_HMAC_KEY')
    return HMACSHA256.compute(hmacKeySeed, masterKey)
  }

  private base64UrlEncode(data: Uint8Array): string {
    let binary = ''
    for (let i = 0; i < data.byteLength; i++) {
      binary += String.fromCharCode(data[i])
    }
    const base64 = btoa(binary)
    return base64.replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/, '')
  }
}

/**
 * Parse QR string and extract header info
 */
export function parseQRString(qrData: string): {
  version: string
  index: number
  total: number
  crc32: number
  payload: Uint8Array
} | null {
  try {
    const parts = qrData.split(':')
    if (parts.length < 4) return null

    if (parts[0] !== 'VNQ') return null

    const version = parts[1]
    const indexTotal = parts[2].split('/')
    if (indexTotal.length !== 2) return null

    const index = parseInt(indexTotal[0], 10) - 1 // 0-based
    const total = parseInt(indexTotal[1], 10)

    let crc32 = 0
    let payloadStr: string

    if (parts.length === 5) {
      crc32 = parseInt(parts[3], 10)
      payloadStr = parts[4]
    } else {
      payloadStr = parts[3]
    }

    // Base64URL decode
    let base64 = payloadStr.replace(/-/g, '+').replace(/_/g, '/')
    while (base64.length % 4) {
      base64 += '='
    }

    const binary = atob(base64)
    const payload = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      payload[i] = binary.charCodeAt(i)
    }

    return { version, index, total, crc32, payload }
  } catch (e) {
    return null
  }
}
