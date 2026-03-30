import { create } from 'zustand'
import { Label } from '../domain/entities/types'
import { v4 as uuidv4 } from 'uuid'
import { useNoteStore } from './noteStore'
import { useCryptoStore } from './cryptoStore'
import { NoteRepository } from '../core/storage/noteRepository'

interface LabelState {
  labels: Label[]
  isLoading: boolean
  error: string | null

  // Actions
  loadLabels: () => void
  createLabel: (name: string, color: string) => void
  updateLabel: (label: Label) => void
  deleteLabel: (labelId: string) => Promise<void>
}

export const useLabelStore = create<LabelState>((set, get) => ({
  labels: [],
  isLoading: false,
  error: null,

  loadLabels: () => {
    try {
      const stored = localStorage.getItem('vaultnote_labels')
      const labels: Label[] = stored ? JSON.parse(stored) : []
      set({ labels, isLoading: false })
    } catch (error) {
      set({ error: (error as Error).message })
    }
  },

  createLabel: (name: string, color: string) => {
    const newLabel: Label = {
      id: uuidv4(),
      name,
      color,
    }

    const labels = [...get().labels, newLabel]
    localStorage.setItem('vaultnote_labels', JSON.stringify(labels))
    set({ labels })
  },

  updateLabel: (label: Label) => {
    const labels = get().labels.map((l) => (l.id === label.id ? label : l))
    localStorage.setItem('vaultnote_labels', JSON.stringify(labels))
    set({ labels })
  },

  deleteLabel: async (labelId: string) => {
    const labelToDelete = get().labels.find(l => l.id === labelId)
    if (!labelToDelete) return

    // Remove label from labels list
    const labels = get().labels.filter((l) => l.id !== labelId)
    localStorage.setItem('vaultnote_labels', JSON.stringify(labels))
    set({ labels })

    // Remove label from all notes
    try {
      const { masterKey, hmacKey } = useCryptoStore.getState()
      if (masterKey && hmacKey) {
        const repo = new NoteRepository()
        repo.setKeys(masterKey, hmacKey)
        await repo.init()

        const allNotes = await repo.getAllNotes()
        for (const note of allNotes) {
          if (note.labels.includes(labelToDelete.name)) {
            const updatedNote = {
              ...note,
              labels: note.labels.filter(l => l !== labelToDelete.name),
              modified: new Date().toISOString(),
            }
            await repo.updateNote(updatedNote)
          }
        }

        // Reload notes to reflect changes
        useNoteStore.getState().loadNotes()
      }
    } catch (error) {
      console.error('Error removing label from notes:', error)
    }
  },
}))
