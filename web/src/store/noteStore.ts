import { create } from 'zustand'
import { Note } from '../domain/entities/types'
import { NoteRepository } from '../core/storage/noteRepository'
import { useCryptoStore } from './cryptoStore'

interface NoteState {
  notes: Note[]
  filteredNotes: Note[]
  filterLabel: string | null
  searchQuery: string
  isLoading: boolean
  error: string | null

  // Actions
  loadNotes: () => Promise<void>
  createNote: (note: Note) => Promise<void>
  updateNote: (note: Note) => Promise<void>
  deleteNote: (noteId: string) => Promise<void>
  togglePin: (noteId: string) => Promise<void>
  archiveNote: (noteId: string, archive: boolean) => Promise<void>
  searchNotes: (query: string) => Promise<void>
  filterByLabel: (label: string | null) => void
  clearFilter: () => void
}

function getEncryptionKeys() {
  const { masterKey, hmacKey } = useCryptoStore.getState()
  if (!masterKey || !hmacKey) {
    throw new Error('Not unlocked')
  }
  return { masterKey, hmacKey }
}

export const useNoteStore = create<NoteState>((set, get) => ({
  notes: [],
  filteredNotes: [],
  filterLabel: null,
  searchQuery: '',
  isLoading: false,
  error: null,

  loadNotes: async () => {
    let keys
    try {
      keys = getEncryptionKeys()
    } catch {
      set({ error: 'Not unlocked', isLoading: false })
      return
    }

    set({ isLoading: true, error: null })

    try {
      const repo = new NoteRepository()
      repo.setKeys(keys.masterKey, keys.hmacKey)
      await repo.init()

      const notes = await repo.getActiveNotes()
      set({
        notes,
        filteredNotes: applyFilters(notes, get().filterLabel, get().searchQuery),
        isLoading: false,
      })
    } catch (error) {
      set({ isLoading: false, error: (error as Error).message })
    }
  },

  createNote: async (note: Note) => {
    let keys
    try {
      keys = getEncryptionKeys()
    } catch {
      set({ error: 'Not unlocked' })
      return
    }

    try {
      const repo = new NoteRepository()
      repo.setKeys(keys.masterKey, keys.hmacKey)
      await repo.init()
      await repo.createNote(note)
      await get().loadNotes()
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  updateNote: async (note: Note) => {
    let keys
    try {
      keys = getEncryptionKeys()
    } catch {
      set({ error: 'Not unlocked' })
      return
    }

    try {
      const repo = new NoteRepository()
      repo.setKeys(keys.masterKey, keys.hmacKey)
      await repo.init()
      await repo.updateNote(note)
      await get().loadNotes()
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  deleteNote: async (noteId: string) => {
    let keys
    try {
      keys = getEncryptionKeys()
    } catch {
      set({ error: 'Not unlocked' })
      return
    }

    try {
      const repo = new NoteRepository()
      repo.setKeys(keys.masterKey, keys.hmacKey)
      await repo.init()
      await repo.deleteNote(noteId)
      await get().loadNotes()
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  togglePin: async (noteId: string) => {
    const note = get().notes.find((n) => n.id === noteId)
    if (!note) return

    const updated: Note = {
      ...note,
      pinned: !note.pinned,
      modified: new Date().toISOString(),
    }

    await get().updateNote(updated)
  },

  archiveNote: async (noteId: string, archive: boolean) => {
    const note = get().notes.find((n) => n.id === noteId)
    if (!note) return

    const updated: Note = {
      ...note,
      archived: archive,
      modified: new Date().toISOString(),
    }

    await get().updateNote(updated)
  },

  searchNotes: async (query: string) => {
    set({ searchQuery: query })

    if (!query) {
      await get().loadNotes()
      return
    }

    let keys
    try {
      keys = getEncryptionKeys()
    } catch {
      set({ error: 'Not unlocked' })
      return
    }

    try {
      const repo = new NoteRepository()
      repo.setKeys(keys.masterKey, keys.hmacKey)
      await repo.init()

      const results = await repo.searchNotes(query)
      set({
        filteredNotes: applyLabelFilter(results, get().filterLabel),
        isLoading: false,
      })
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  filterByLabel: (label: string | null) => {
    set({ filterLabel: label })
    const notes = get().notes
    set({ filteredNotes: applyLabelFilter(notes, label) })
  },

  clearFilter: () => {
    set({ filterLabel: null, searchQuery: '' })
    set({ filteredNotes: get().notes })
  },
}))

function applyFilters(notes: Note[], filterLabel: string | null, searchQuery: string): Note[] {
  let result = notes

  if (filterLabel) {
    result = result.filter((n) => n.labels.includes(filterLabel))
  }

  if (searchQuery) {
    const query = searchQuery.toLowerCase()
    result = result.filter(
      (n) =>
        n.title.toLowerCase().includes(query) ||
        n.body.toLowerCase().includes(query) ||
        n.labels.some((l) => l.toLowerCase().includes(query))
    )
  }

  return result
}

function applyLabelFilter(notes: Note[], filterLabel: string | null): Note[] {
  if (!filterLabel) return notes
  return notes.filter((n) => n.labels.includes(filterLabel))
}
