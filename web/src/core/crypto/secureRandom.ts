/**
 * Cryptographically secure random number generator
 */
export class SecureRandom {
  /**
   * Generate cryptographically secure random bytes
   */
  static bytes(length: number): Uint8Array {
    const array = new Uint8Array(length)
    crypto.getRandomValues(array)
    return array
  }

  /**
   * Generate a random integer in range [0, max)
   */
  static int(max: number): number {
    const array = new Uint32Array(1)
    crypto.getRandomValues(array)
    return array[0] % max
  }

  /**
   * Generate a random boolean
   */
  static bool(): boolean {
    const array = new Uint8Array(1)
    crypto.getRandomValues(array)
    return array[0] % 2 === 0
  }
}
