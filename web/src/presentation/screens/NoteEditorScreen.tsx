import { useState, useEffect, useCallback, useRef } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import { useNoteStore } from '../../store/noteStore'
import { useLabelStore } from '../../store/labelStore'
import { Note } from '../../domain/entities/types'
import { v4 as uuidv4 } from 'uuid'

const NOTE_COLORS = [
  '#FFFFFF', '#F28B82', '#FDD663', '#81C995',
  '#78D9EC', '#7BAAF7', '#8793F9', '#FF8BCC', '#E8EAED'
]

const AUTO_SAVE_INTERVAL = 2000 // 2 seconds

export default function NoteEditorScreen() {
  const navigate = useNavigate()
  const { id } = useParams<{ id: string }>()

  const { notes, createNote, updateNote } = useNoteStore()
  const { labels } = useLabelStore()

  const [title, setTitle] = useState('')
  const [body, setBody] = useState('')
  const [selectedColor, setSelectedColor] = useState('#FFFFFF')
  const [selectedLabels, setSelectedLabels] = useState<string[]>([])
  const [isPinned, setIsPinned] = useState(false)
  const [showColorPicker, setShowColorPicker] = useState(false)
  const [showLabelPicker, setShowLabelPicker] = useState(false)
  const [hasChanges, setHasChanges] = useState(false)
  const [isSaving, setIsSaving] = useState(false)
  const [lastSaved, setLastSaved] = useState<Date | null>(null)

  const autoSaveTimerRef = useRef<NodeJS.Timeout | null>(null)

  // Cleanup on unmount
  useEffect(() => {
    return () => {
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current)
      }
    }
  }, [])

  // Load existing note
  useEffect(() => {
    if (id) {
      const existingNote = notes.find(n => n.id === id)
      if (existingNote) {
        setTitle(existingNote.title)
        setBody(existingNote.body)
        setSelectedColor(existingNote.color)
        setSelectedLabels(existingNote.labels)
        setIsPinned(existingNote.pinned)
        setHasChanges(false)
      }
    }
  }, [id, notes])

  // Auto-save effect
  useEffect(() => {
    if (hasChanges && autoSaveTimerRef.current) {
      clearTimeout(autoSaveTimerRef.current)
    }

    if (hasChanges) {
      autoSaveTimerRef.current = setTimeout(() => {
        handleSave()
      }, AUTO_SAVE_INTERVAL)
    }

    return () => {
      if (autoSaveTimerRef.current) {
        clearTimeout(autoSaveTimerRef.current)
      }
    }
  }, [hasChanges, title, body, selectedColor, selectedLabels, isPinned])

  const handleSave = useCallback(async () => {
    if (!title.trim() && !body.trim()) return
    if (!hasChanges) return

    setIsSaving(true)

    const now = new Date().toISOString()
    const note: Note = {
      id: id || uuidv4(),
      title: title.trim() || 'Untitled',
      body: body.trim(),
      labels: selectedLabels,
      color: selectedColor,
      created: id ? notes.find(n => n.id === id)?.created || now : now,
      modified: now,
      pinned: isPinned,
      archived: id ? notes.find(n => n.id === id)?.archived || false : false,
    }

    try {
      if (id) {
        await updateNote(note)
      } else {
        await createNote(note)
      }
      setHasChanges(false)
      setLastSaved(new Date())
    } catch (error) {
      console.error('Save error:', error)
    } finally {
      setIsSaving(false)
    }
  }, [title, body, selectedColor, selectedLabels, isPinned, id, notes, hasChanges, updateNote, createNote])

  const handleBack = async () => {
    if (hasChanges) {
      await handleSave()
    }
    navigate(-1)
  }

  const toggleLabel = (labelName: string) => {
    setSelectedLabels(prev =>
      prev.includes(labelName)
        ? prev.filter(l => l !== labelName)
        : [...prev, labelName]
    )
    setHasChanges(true)
  }

  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      {/* Header */}
      <header className="bg-white dark:bg-gray-800 shadow-sm sticky top-0 z-10">
        <div className="max-w-4xl mx-auto px-4">
          <div className="flex items-center justify-between h-14">
            <button
              onClick={handleBack}
              className="p-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
              </svg>
            </button>
            <div className="flex items-center space-x-2">
              {isSaving && (
                <span className="text-xs text-gray-500 dark:text-gray-400 flex items-center">
                  <svg className="animate-spin h-3 w-3 mr-1" viewBox="0 0 24 24">
                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                  </svg>
                  Saving...
                </span>
              )}
              {!isSaving && lastSaved && (
                <span className="text-xs text-gray-400 dark:text-gray-500">
                  Saved {lastSaved.toLocaleTimeString()}
                </span>
              )}
            </div>
            <h1 className="text-lg font-semibold text-gray-900 dark:text-white">
              {id ? 'Edit Note' : 'New Note'}
            </h1>
            <div className="flex items-center space-x-1">
              <button
                onClick={() => setIsPinned(!isPinned)}
                className={`p-2 rounded-lg ${isPinned ? 'text-indigo-600 bg-indigo-50 dark:bg-indigo-900/30' : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700'}`}
              >
                <svg className="w-5 h-5" fill={isPinned ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
                </svg>
              </button>
              <button
                onClick={() => setShowColorPicker(!showColorPicker)}
                className="p-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
              </button>
              <button
                onClick={() => setShowLabelPicker(!showLabelPicker)}
                className="p-2 text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg"
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      </header>

      {/* Color indicator */}
      <div className="h-1 w-full" style={{ backgroundColor: selectedColor }} />

      <main className="max-w-4xl mx-auto px-4 py-6">
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          {/* Title */}
          <input
            type="text"
            value={title}
            onChange={(e) => { setTitle(e.target.value); setHasChanges(true) }}
            placeholder="Title"
            className="w-full text-2xl font-bold bg-transparent border-none focus:ring-0 text-gray-900 dark:text-white placeholder-gray-400"
          />

          {/* Labels */}
          {selectedLabels.length > 0 && (
            <div className="flex flex-wrap gap-2 mt-4 mb-4">
              {selectedLabels.map((label) => (
                <span
                  key={label}
                  className="px-3 py-1 bg-indigo-100 dark:bg-indigo-900/30 text-indigo-700 dark:text-indigo-300 rounded-full text-sm flex items-center gap-1"
                >
                  {label}
                  <button
                    onClick={() => toggleLabel(label)}
                    className="hover:text-indigo-900 dark:hover:text-indigo-100"
                  >
                    <svg className="w-3 h-3" fill="currentColor" viewBox="0 0 20 20">
                      <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
                    </svg>
                  </button>
                </span>
              ))}
            </div>
          )}

          {/* Body */}
          <textarea
            value={body}
            onChange={(e) => { setBody(e.target.value); setHasChanges(true) }}
            placeholder="Note"
            rows={12}
            className="w-full bg-transparent border-none focus:ring-0 text-gray-900 dark:text-white placeholder-gray-400 resize-none"
          />
        </div>
      </main>

      {/* Color picker popover */}
      {showColorPicker && (
        <div className="fixed bottom-20 left-1/2 -translate-x-1/2 bg-white dark:bg-gray-800 rounded-lg shadow-xl p-4 z-20 animate-slide-up">
          <div className="flex gap-2">
            {NOTE_COLORS.map((color) => (
              <button
                key={color}
                onClick={() => { setSelectedColor(color); setShowColorPicker(false); setHasChanges(true) }}
                className={`w-8 h-8 rounded-full border-2 ${
                  selectedColor === color ? 'border-gray-900 dark:border-white' : 'border-gray-300 dark:border-gray-600'
                }`}
                style={{ backgroundColor: color }}
              />
            ))}
          </div>
        </div>
      )}

      {/* Label picker popover */}
      {showLabelPicker && (
        <div className="fixed bottom-20 left-1/2 -translate-x-1/2 bg-white dark:bg-gray-800 rounded-lg shadow-xl p-4 z-20 animate-slide-up min-w-[200px]">
          <h3 className="text-sm font-medium text-gray-900 dark:text-white mb-2">Select Labels</h3>
          <div className="flex flex-wrap gap-2">
            {labels.map((label) => (
              <button
                key={label.id}
                onClick={() => toggleLabel(label.name)}
                className={`px-3 py-1 rounded-full text-sm ${
                  selectedLabels.includes(label.name)
                    ? 'bg-indigo-600 text-white'
                    : 'bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
                }`}
              >
                {label.name}
              </button>
            ))}
            <button
              onClick={() => navigate('/labels')}
              className="px-3 py-1 rounded-full text-sm border border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-400"
            >
              + Manage
            </button>
          </div>
        </div>
      )}

      {/* Save button */}
      <button
        onClick={handleSave}
        disabled={!hasChanges}
        className="fixed bottom-6 right-6 w-14 h-14 bg-indigo-600 hover:bg-indigo-700 text-white rounded-full shadow-lg flex items-center justify-center transition-all disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
        </svg>
      </button>
    </div>
  )
}
