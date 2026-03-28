import { create } from 'zustand'
import { Argon2KDF } from '../core/crypto/argon2KDF'
import { AESGCM } from '../core/crypto/aesGCM'
import { HMACSHA256 } from '../core/crypto/hmacSHA256'
import { SecureStorage } from '../core/storage/secureStorage'
import { QREncoder, parseQRString } from '../core/qr/qrEncoder'
import { Note } from '../domain/entities/types'
import pako from 'pako'

interface CryptoState {
  isInitialized: boolean
  isUnlocked: boolean
  needsSetup: boolean
  error: string | null
  masterKey: Uint8Array | null
  hmacKey: Uint8Array | null

  // QR export
  qrChunks: string[]
  qrIndex: number

  // QR import
  qrSession: QRImportSession | null
  importedNote: Note | null

  // Actions
  initialize: () => Promise<void>
  setupNewPassword: (password: string) => Promise<boolean>
  unlockWithPassword: (password: string) => Promise<boolean>
  lock: () => void
  exportToQR: (note: any, password: string) => Promise<void>
  processScannedQR: (qrData: string) => void
  executeQRImport: (password: string) => Promise<boolean>
  resetQRImport: () => void
  clearError: () => void
}

interface QRImportSession {
  total: number
  chunks: Map<number, Uint8Array>
  isComplete: boolean
}

// Helper function
async function deriveHmacKey(masterKey: Uint8Array): Promise<Uint8Array> {
  const hmacKeySeed = new TextEncoder().encode('VNC_HMAC_KEY')
  return HMACSHA256.compute(hmacKeySeed, masterKey)
}

export const useCryptoStore = create<CryptoState>((set, get) => ({
  isInitialized: false,
  isUnlocked: false,
  needsSetup: false,
  error: null,
  masterKey: null,
  hmacKey: null,
  qrChunks: [],
  qrIndex: 0,
  qrSession: null,
  importedNote: null,

  initialize: async () => {
    try {
      const salt = SecureStorage.getSalt()
      if (!salt) {
        set({ needsSetup: true, isInitialized: true })
      } else {
        set({ isInitialized: true, needsSetup: false })
      }
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  setupNewPassword: async (password: string) => {
    try {
      const salt = Argon2KDF.generateSalt()
      const key = await Argon2KDF.deriveKey(password, salt)

      // Store salt
      SecureStorage.setSalt(salt)

      // Create and store verification hash
      const hmacKey = await deriveHmacKey(key)
      const testVector = await HMACSHA256.compute(
        new TextEncoder().encode('VNC_VERIFY'),
        key
      )
      SecureStorage.setVerifyHash(testVector)

      set({
        isInitialized: true,
        needsSetup: false,
        isUnlocked: true,
        masterKey: key,
        hmacKey: hmacKey,
      })

      return true
    } catch (error) {
      set({ error: (error as Error).message })
      return false
    }
  },

  unlockWithPassword: async (password: string) => {
    try {
      const salt = SecureStorage.getSalt()
      if (!salt) {
        set({ error: 'No password set up' })
        return false
      }

      const verifyHash = SecureStorage.getVerifyHash()
      const key = await Argon2KDF.deriveKey(password, salt)

      if (verifyHash) {
        const testVector = await HMACSHA256.compute(
          new TextEncoder().encode('VNC_VERIFY'),
          key
        )
        if (!Argon2KDF.constantTimeCompare(testVector, verifyHash)) {
          set({ error: 'Incorrect password' })
          return false
        }
      }

      const hmacKey = await deriveHmacKey(key)

      set({
        isUnlocked: true,
        error: null,
        masterKey: key,
        hmacKey: hmacKey,
      })

      return true
    } catch (error) {
      set({ error: (error as Error).message })
      return false
    }
  },

  lock: () => {
    set({
      isUnlocked: false,
      masterKey: null,
      hmacKey: null,
      qrChunks: [],
      qrIndex: 0,
      qrSession: null,
      importedNote: null,
    })
  },

  exportToQR: async (note: any, password: string) => {
    try {
      const encoder = new QREncoder()
      const chunks = await encoder.exportNoteAsQR(note, password)

      set({
        qrChunks: chunks,
        qrIndex: 0,
        error: null,
      })
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  processScannedQR: (qrData: string) => {
    try {
      const parsed = parseQRString(qrData)
      if (!parsed) {
        set({ error: 'Invalid QR format' })
        return
      }

      const { index, total, payload } = parsed

      let session = get().qrSession
      if (!session) {
        session = {
          total,
          chunks: new Map(),
          isComplete: false,
        }
      }

      session.chunks.set(index, payload)
      session.isComplete = session.chunks.size === session.total

      set({
        qrSession: session,
        qrIndex: session.chunks.size,
        error: null,
      })
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  executeQRImport: async (password: string) => {
    try {
      const session = get().qrSession
      if (!session || !session.isComplete) {
        set({ error: 'QR scan incomplete' })
        return false
      }

      // Combine all chunks
      const combined = new Uint8Array(
        Array.from(session.chunks.entries())
          .sort((a, b) => a[0] - b[0])
          .flatMap(([, data]) => Array.from(data))
      )

      // Extract components
      const salt = combined.slice(0, 32)
      const iv = combined.slice(32, 44)
      const ciphertext = combined.slice(44, combined.length - 32 - 16)
      const authTag = combined.slice(combined.length - 32 - 16, combined.length - 32)
      const storedHmac = combined.slice(combined.length - 32)

      // Verify HMAC
      const key = await Argon2KDF.deriveKey(password, salt)
      const hmacKey = await deriveHmacKey(key)
      const dataToHmac = new Uint8Array([...salt, ...iv, ...ciphertext, ...authTag])
      const computedHmac = await HMACSHA256.compute(dataToHmac, hmacKey)

      if (!Argon2KDF.constantTimeCompare(computedHmac, storedHmac)) {
        set({ error: 'HMAC verification failed' })
        return false
      }

      // Decrypt
      const decrypted = await AESGCM.decrypt(ciphertext, key, iv, authTag)

      // Decompress and parse
      const decompressed = pako.ungzip(decrypted)
      const jsonString = new TextDecoder().decode(decompressed)
      const note = JSON.parse(jsonString)

      set({
        importedNote: note,
        error: null,
      })

      return true
    } catch (error) {
      set({ error: (error as Error).message })
      return false
    }
  },

  resetQRImport: () => {
    set({
      qrSession: null,
      qrIndex: 0,
      importedNote: null,
      qrChunks: [],
    })
  },

  clearError: () => {
    set({ error: null })
  },
}))
