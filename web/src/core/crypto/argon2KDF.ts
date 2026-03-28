import { SecureRandom } from './secureRandom'

/**
 * Argon2id-like Key Derivation using PBKDF2 (Web Crypto API fallback)
 * Note: For production, use native argon2 implementation
 * Parameters adjusted for PBKDF2: iterations=100000
 */
export class Argon2KDF {
  static readonly memoryCost = 65536 // 64 MB (not used in PBKDF2 fallback)
  static readonly timeCost = 3
  static readonly parallelism = 4
  static readonly derivedKeyLength = 32 // 256 bits
  static readonly iterations = 100000 // PBKDF2 iterations

  /**
   * Derive a 256-bit key from password and salt using PBKDF2
   */
  static async deriveKey(password: string, salt: Uint8Array): Promise<Uint8Array> {
    const encoder = new TextEncoder()
    const keyMaterial = await crypto.subtle.importKey(
      'raw',
      encoder.encode(password),
      'PBKDF2',
      false,
      ['deriveBits']
    )

    const derivedBits = await crypto.subtle.deriveBits(
      {
        name: 'PBKDF2',
        salt: salt.buffer as ArrayBuffer,
        iterations: this.iterations,
        hash: 'SHA-256',
      },
      keyMaterial,
      this.derivedKeyLength * 8
    )

    return new Uint8Array(derivedBits)
  }

  /**
   * Generate a new random salt
   */
  static generateSalt(): Uint8Array {
    return SecureRandom.bytes(32)
  }

  /**
   * Verify a password against a stored hash
   */
  static async verify(
    password: string,
    salt: Uint8Array,
    expectedHash: Uint8Array
  ): Promise<boolean> {
    const derivedKey = await this.deriveKey(password, salt)
    return this.constantTimeCompare(derivedKey, expectedHash)
  }

  /**
   * Constant-time comparison to prevent timing attacks
   */
  static constantTimeCompare(a: Uint8Array, b: Uint8Array): boolean {
    if (a.length !== b.length) return false

    let result = 0
    for (let i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i]
    }

    return result === 0
  }
}
