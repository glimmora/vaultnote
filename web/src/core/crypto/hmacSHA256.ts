/**
 * HMAC-SHA256 for integrity verification using Web Crypto API
 */
export class HMACSHA256 {
  static readonly keyLength = 32
  static readonly hashLength = 32

  /**
   * Compute HMAC-SHA256 of data
   */
  static async compute(data: Uint8Array, key: Uint8Array): Promise<Uint8Array> {
    if (key.length !== this.keyLength) {
      throw new Error('Key must be 32 bytes (256 bits)')
    }

    const cryptoKey = await crypto.subtle.importKey(
      'raw',
      key.buffer as ArrayBuffer,
      { name: 'HMAC', hash: 'SHA-256' },
      false,
      ['sign']
    )

    const signature = await crypto.subtle.sign('HMAC', cryptoKey, data.buffer as ArrayBuffer)
    return new Uint8Array(signature)
  }

  /**
   * Verify HMAC-SHA256
   */
  static async verify(
    data: Uint8Array,
    key: Uint8Array,
    expectedHmac: Uint8Array
  ): Promise<boolean> {
    const computedHmac = await this.compute(data, key)
    return this.constantTimeCompare(computedHmac, expectedHmac)
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
