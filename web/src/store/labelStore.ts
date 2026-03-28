import { create } from 'zustand'
import { Label } from '../domain/entities/types'
import { v4 as uuidv4 } from 'uuid'

interface LabelState {
  labels: Label[]
  isLoading: boolean
  error: string | null

  // Actions
  loadLabels: () => void
  createLabel: (name: string, color: string) => void
  updateLabel: (label: Label) => void
  deleteLabel: (labelId: string) => void
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

  deleteLabel: (labelId: string) => {
    const labels = get().labels.filter((l) => l.id !== labelId)
    localStorage.setItem('vaultnote_labels', JSON.stringify(labels))
    set({ labels })
  },
}))
