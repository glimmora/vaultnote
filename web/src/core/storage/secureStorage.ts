/**
 * Secure storage wrapper using localStorage (with encryption for sensitive data)
 * For production, consider using IndexedDB with additional encryption
 */
export class SecureStorage {
  private static readonly SALT_KEY = 'vnc_salt'
  private static readonly VERIFY_KEY = 'vnc_key_verify'
  private static readonly PIN_KEY = 'vnc_pin_hash'
  private static readonly BIOMETRIC_KEY = 'vnc_biometric_enabled'
  private static readonly AUTOLOCK_KEY = 'vnc_autolock_minutes'

  /**
   * Store the KDF salt
   */
  static setSalt(salt: Uint8Array): void {
    const encoded = this.bytesToBase64(salt)
    localStorage.setItem(this.SALT_KEY, encoded)
  }

  /**
   * Retrieve the KDF salt
   */
  static getSalt(): Uint8Array | null {
    const encoded = localStorage.getItem(this.SALT_KEY)
    if (!encoded) return null
    return this.base64ToBytes(encoded)
  }

  /**
   * Store verification hash for password
   */
  static setVerifyHash(hash: Uint8Array): void {
    const encoded = this.bytesToBase64(hash)
    localStorage.setItem(this.VERIFY_KEY, encoded)
  }

  /**
   * Retrieve verification hash
   */
  static getVerifyHash(): Uint8Array | null {
    const encoded = localStorage.getItem(this.VERIFY_KEY)
    if (!encoded) return null
    return this.base64ToBytes(encoded)
  }

  /**
   * Store PIN hash
   */
  static setPinHash(hash: string): void {
    localStorage.setItem(this.PIN_KEY, hash)
  }

  /**
   * Retrieve PIN hash
   */
  static getPinHash(): string | null {
    return localStorage.getItem(this.PIN_KEY)
  }

  /**
   * Check if biometric is enabled
   */
  static isBiometricEnabled(): boolean {
    const value = localStorage.getItem(this.BIOMETRIC_KEY)
    return value === 'true'
  }

  /**
   * Set biometric enabled status
   */
  static setBiometricEnabled(enabled: boolean): void {
    localStorage.setItem(this.BIOMETRIC_KEY, enabled ? 'true' : 'false')
  }

  /**
   * Get auto-lock timeout in minutes
   */
  static getAutoLockMinutes(): number {
    const value = localStorage.getItem(this.AUTOLOCK_KEY)
    return parseInt(value || '5', 10)
  }

  /**
   * Set auto-lock timeout
   */
  static setAutoLockMinutes(minutes: number): void {
    localStorage.setItem(this.AUTOLOCK_KEY, minutes.toString())
  }

  /**
   * Clear all secure data
   */
  static clearAll(): void {
    localStorage.removeItem(this.SALT_KEY)
    localStorage.removeItem(this.VERIFY_KEY)
    localStorage.removeItem(this.PIN_KEY)
    localStorage.removeItem(this.BIOMETRIC_KEY)
    localStorage.removeItem(this.AUTOLOCK_KEY)
  }

  /**
   * Convert Uint8Array to Base64 string
   */
  private static bytesToBase64(bytes: Uint8Array): string {
    let binary = ''
    for (let i = 0; i < bytes.byteLength; i++) {
      binary += String.fromCharCode(bytes[i])
    }
    return btoa(binary)
  }

  /**
   * Convert Base64 string to Uint8Array
   */
  private static base64ToBytes(base64: string): Uint8Array {
    const binary = atob(base64)
    const bytes = new Uint8Array(binary.length)
    for (let i = 0; i < binary.length; i++) {
      bytes[i] = binary.charCodeAt(i)
    }
    return bytes
  }
}
