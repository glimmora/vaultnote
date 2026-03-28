import { SecureRandom } from './secureRandom'

/**
 * AES-256-GCM Encryption/Decryption using Web Crypto API
 */
export class AESGCM {
  static readonly keyLength = 32 // 256 bits
  static readonly ivLength = 12 // 96 bits
  static readonly authTagLength = 16

  /**
   * Encrypt plaintext using AES-256-GCM
   */
  static async encrypt(
    plaintext: Uint8Array,
    key: Uint8Array,
    iv?: Uint8Array
  ): Promise<{ ciphertext: Uint8Array; iv: Uint8Array; authTag: Uint8Array }> {
    if (key.length !== this.keyLength) {
      throw new Error('Key must be 32 bytes (256 bits)')
    }

    iv = iv || SecureRandom.bytes(this.ivLength)
    if (iv.length !== this.ivLength) {
      throw new Error('IV must be 12 bytes (96 bits)')
    }

    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      key.buffer as ArrayBuffer,
      'AES-GCM',
      false,
      ['encrypt']
    )

    const encrypted = await crypto.subtle.encrypt(
      {
        name: 'AES-GCM',
        iv: iv.buffer as ArrayBuffer,
      },
      cryptoKey,
      plaintext.buffer as ArrayBuffer
    )

    // Web Crypto API returns ciphertext with auth tag appended
    const encryptedBytes = new Uint8Array(encrypted)
    const ciphertext = encryptedBytes.slice(0, encryptedBytes.length - this.authTagLength)
    const authTag = encryptedBytes.slice(encryptedBytes.length - this.authTagLength)

    return { ciphertext, iv, authTag }
  }

  /**
   * Decrypt ciphertext using AES-256-GCM
   */
  static async decrypt(
    ciphertext: Uint8Array,
    key: Uint8Array,
    iv: Uint8Array,
    authTag: Uint8Array
  ): Promise<Uint8Array> {
    if (key.length !== this.keyLength) {
      throw new Error('Key must be 32 bytes (256 bits)')
    }

    if (iv.length !== this.ivLength) {
      throw new Error('IV must be 12 bytes (96 bits)')
    }

    if (authTag.length !== this.authTagLength) {
      throw new Error('Auth tag must be 16 bytes')
    }

    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      key.buffer as ArrayBuffer,
      'AES-GCM',
      false,
      ['decrypt']
    )

    // Combine ciphertext and auth tag
    const combined = new Uint8Array(ciphertext.length + this.authTagLength)
    combined.set(ciphertext, 0)
    combined.set(authTag, ciphertext.length)

    try {
      const decrypted = await crypto.subtle.decrypt(
        {
          name: 'AES-GCM',
          iv: iv.buffer as ArrayBuffer,
        },
        cryptoKey,
        combined.buffer as ArrayBuffer
      )

      return new Uint8Array(decrypted)
    } catch {
      throw new Error('Decryption failed: authentication tag verification failed')
    }
  }
}
