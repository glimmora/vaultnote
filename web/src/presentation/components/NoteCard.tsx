import { Note } from '../../domain/entities/types'
import { formatDistanceToNow } from 'date-fns'

interface NoteCardProps {
  note: Note
  isCompact?: boolean
  onClick?: () => void
}

export default function NoteCard({ note, isCompact = false, onClick }: NoteCardProps) {
  const colorClass = getColorClass(note.color)

  return (
    <div
      onClick={onClick}
      className={`${colorClass} rounded-lg shadow-sm hover:shadow-md transition-shadow cursor-pointer overflow-hidden ${
        isCompact ? '' : 'break-inside-avoid'
      }`}
    >
      <div className="p-4">
        <div className="flex items-start justify-between mb-2">
          <h3 className="font-semibold text-gray-900 dark:text-white truncate flex-1">
            {note.title}
          </h3>
          {note.pinned && (
            <svg className="w-4 h-4 text-gray-500 flex-shrink-0 ml-2" fill="currentColor" viewBox="0 0 20 20">
              <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
            </svg>
          )}
        </div>

        {!isCompact && (
          <p className="text-gray-700 dark:text-gray-300 text-sm mb-3 line-clamp-6 whitespace-pre-wrap">
            {note.body}
          </p>
        )}

        {note.labels.length > 0 && (
          <div className="flex flex-wrap gap-1 mb-2">
            {note.labels.slice(0, 3).map((label, index) => (
              <span
                key={index}
                className="px-2 py-0.5 bg-black/20 rounded-full text-xs text-white"
              >
                {label}
              </span>
            ))}
            {note.labels.length > 3 && (
              <span className="px-2 py-0.5 text-xs text-gray-600 dark:text-gray-400">
                +{note.labels.length - 3}
              </span>
            )}
          </div>
        )}

        <p className="text-xs text-gray-500 dark:text-gray-400">
          {formatDistanceToNow(new Date(note.modified), { addSuffix: true })}
        </p>
      </div>
    </div>
  )
}

function getColorClass(color: string): string {
  const colorMap: Record<string, string> = {
    '#FFFFFF': 'note-white dark:bg-gray-800',
    '#F28B82': 'note-red',
    '#FDD663': 'note-yellow',
    '#81C995': 'note-green',
    '#78D9EC': 'note-cyan',
    '#7BAAF7': 'note-blue',
    '#8793F9': 'note-purple',
    '#FF8BCC': 'note-pink',
    '#E8EAED': 'note-gray',
  }
  return colorMap[color] || 'note-white dark:bg-gray-800'
}
