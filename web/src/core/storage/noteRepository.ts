import { Note } from '../../domain/entities/types'
import { VNCFormat } from './vncFormat'

/**
 * Repository for note CRUD operations
 * Notes are stored in IndexedDB as .vnc encrypted files
 */
export class NoteRepository {
  private readonly dbName = 'VaultNote'
  private readonly storeName = 'notes'
  private db: IDBDatabase | null = null

  private key: Uint8Array | null = null
  private hmacKey: Uint8Array | null = null

  /**
   * Initialize the repository with encryption keys
   */
  setKeys(key: Uint8Array, hmacKey: Uint8Array): void {
    this.key = key
    this.hmacKey = hmacKey
  }

  /**
   * Initialize IndexedDB
   */
  async init(): Promise<void> {
    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, 1)

      request.onerror = () => reject(request.error)
      request.onsuccess = () => {
        this.db = request.result
        resolve()
      }

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result
        if (!db.objectStoreNames.contains(this.storeName)) {
          db.createObjectStore(this.storeName, { keyPath: 'id' })
        }
      }
    })
  }

  /**
   * Create a new note
   */
  async createNote(note: Note): Promise<void> {
    if (!this.key || !this.hmacKey) {
      throw new Error('Encryption keys not set')
    }

    const encryptedData = await VNCFormat.encryptNote(note, this.key, this.hmacKey)

    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('Database not initialized'))
        return
      }

      const transaction = this.db.transaction([this.storeName], 'readwrite')
      const store = transaction.objectStore(this.storeName)

      const request = store.put({
        id: note.id,
        data: encryptedData,
        modified: note.modified,
      })

      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Update an existing note
   */
  async updateNote(note: Note): Promise<void> {
    await this.createNote(note)
  }

  /**
   * Delete a note
   */
  async deleteNote(noteId: string): Promise<void> {
    return new Promise((resolve, reject) => {
      if (!this.db) {
        reject(new Error('Database not initialized'))
        return
      }

      const transaction = this.db.transaction([this.storeName], 'readwrite')
      const store = transaction.objectStore(this.storeName)

      const request = store.delete(noteId)

      request.onsuccess = () => resolve()
      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Get a single note by ID
   */
  async getNote(noteId: string): Promise<Note | null> {
    if (!this.key || !this.hmacKey) {
      throw new Error('Encryption keys not set')
    }

    return new Promise(async (resolve, reject) => {
      if (!this.db) {
        reject(new Error('Database not initialized'))
        return
      }

      const transaction = this.db.transaction([this.storeName], 'readonly')
      const store = transaction.objectStore(this.storeName)

      const request = store.get(noteId)

      request.onsuccess = async () => {
        if (!request.result) {
          resolve(null)
          return
        }

        try {
          const note = await VNCFormat.decryptNote(
            request.result.data,
            this.key!,
            this.hmacKey!
          )
          resolve(note)
        } catch (error) {
          reject(error)
        }
      }

      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Get all notes
   */
  async getAllNotes(): Promise<Note[]> {
    if (!this.key || !this.hmacKey) {
      throw new Error('Encryption keys not set')
    }

    return new Promise(async (resolve, reject) => {
      if (!this.db) {
        reject(new Error('Database not initialized'))
        return
      }

      const transaction = this.db.transaction([this.storeName], 'readonly')
      const store = transaction.objectStore(this.storeName)

      const request = store.getAll()

      request.onsuccess = async () => {
        try {
          const notes: Note[] = []

          for (const record of request.result) {
            try {
              const note = await VNCFormat.decryptNote(
                record.data,
                this.key!,
                this.hmacKey!
              )
              notes.push(note)
            } catch (error) {
              console.error('Error decrypting note:', error)
            }
          }

          // Sort: pinned first, then by modified date descending
          notes.sort((a, b) => {
            if (a.pinned && !b.pinned) return -1
            if (!a.pinned && b.pinned) return 1
            return new Date(b.modified).getTime() - new Date(a.modified).getTime()
          })

          resolve(notes)
        } catch (error) {
          reject(error)
        }
      }

      request.onerror = () => reject(request.error)
    })
  }

  /**
   * Get non-archived notes
   */
  async getActiveNotes(): Promise<Note[]> {
    const all = await this.getAllNotes()
    return all.filter((n) => !n.archived)
  }

  /**
   * Get archived notes
   */
  async getArchivedNotes(): Promise<Note[]> {
    const all = await this.getAllNotes()
    return all.filter((n) => n.archived)
  }

  /**
   * Search notes by text
   */
  async searchNotes(query: string): Promise<Note[]> {
    const all = await this.getActiveNotes()
    const lowerQuery = query.toLowerCase()

    return all.filter(
      (note) =>
        note.title.toLowerCase().includes(lowerQuery) ||
        note.body.toLowerCase().includes(lowerQuery) ||
        note.labels.some((l) => l.toLowerCase().includes(lowerQuery))
    )
  }

  /**
   * Get notes by label
   */
  async getNotesByLabel(label: string): Promise<Note[]> {
    const all = await this.getActiveNotes()
    return all.filter((n) => n.labels.includes(label))
  }

  /**
   * Export a note as .vnc bytes
   */
  async exportNote(noteId: string): Promise<Uint8Array> {
    const note = await this.getNote(noteId)
    if (!note) {
      throw new Error('Note not found')
    }

    if (!this.key || !this.hmacKey) {
      throw new Error('Encryption keys not set')
    }

    return VNCFormat.encryptNote(note, this.key, this.hmacKey)
  }

  /**
   * Import a note from .vnc bytes
   */
  async importNote(data: Uint8Array): Promise<Note> {
    if (!this.key || !this.hmacKey) {
      throw new Error('Encryption keys not set')
    }

    const note = await VNCFormat.decryptNote(data, this.key, this.hmacKey)
    await this.createNote(note)
    return note
  }
}
