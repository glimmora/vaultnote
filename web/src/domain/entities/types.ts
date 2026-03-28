export interface Note {
  id: string
  title: string
  body: string
  labels: string[]
  color: string
  created: string
  modified: string
  pinned: boolean
  archived: boolean
}

export interface Label {
  id: string
  name: string
  color: string
}

export interface NotePayload {
  id: string
  title: string
  body: string
  labels: string[]
  color: string
  created: string
  modified: string
  pinned: boolean
  archived: boolean
}
