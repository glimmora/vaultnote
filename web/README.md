# VaultNote Web Application

Encrypted notes web application built with React, TypeScript, and Vite.

## Features

- **End-to-end encryption** - AES-256-GCM + PBKDF2 key derivation
- **Offline-first** - All data stored locally in IndexedDB
- **QR Code export/import** - Share encrypted notes via QR codes
- **Labels & colors** - Organize notes with custom labels and colors
- **Dark/Light mode** - Automatic theme based on system preference
- **Responsive design** - Works on desktop and mobile browsers

## Tech Stack

- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite 5
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Crypto**: Web Crypto API
- **Storage**: IndexedDB
- **QR**: qrcode, @zxing/library

## Quick Start

### Prerequisites

- Node.js 18+ 
- npm 9+

### Development

```bash
cd /root/vaultnote/web

# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# Open in browser
# http://localhost:3000
```

### Production Build

```bash
# Build for production
npm run build

# Preview production build
npm run preview

# Test build
./scripts/test.sh
```

## Available Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Start development server |
| `npm run build` | Build for production |
| `npm run preview` | Preview production build |
| `npm run lint` | Run ESLint |
| `./scripts/test.sh` | Run build tests |

## Project Structure

```
web/
├── src/
│   ├── core/
│   │   ├── crypto/
│   │   │   ├── aesGCM.ts         # AES-256-GCM encryption
│   │   │   ├── argon2KDF.ts      # Key derivation (PBKDF2)
│   │   │   ├── hmacSHA256.ts     # HMAC for integrity
│   │   │   └── secureRandom.ts   # CSPRNG wrapper
│   │   ├── qr/
│   │   │   └── qrEncoder.ts      # QR encode/decode
│   │   └── storage/
│   │       ├── noteRepository.ts # IndexedDB storage
│   │       ├── secureStorage.ts  # LocalStorage wrapper
│   │       └── vncFormat.ts      # .vnc file format
│   ├── domain/
│   │   └── entities/
│   │       └── types.ts          # TypeScript types
│   ├── presentation/
│   │   ├── components/
│   │   │   └── NoteCard.tsx      # Note card component
│   │   └── screens/
│   │       ├── HomeScreen.tsx    # Main screen
│   │       ├── UnlockScreen.tsx  # Password entry
│   │       ├── NoteEditorScreen.tsx
│   │       ├── LabelScreen.tsx
│   │       ├── QRExportScreen.tsx
│   │       ├── QRImportScreen.tsx
│   │       └── SettingsScreen.tsx
│   ├── store/
│   │   ├── cryptoStore.ts        # Crypto state
│   │   ├── noteStore.ts          # Notes state
│   │   └── labelStore.ts         # Labels state
│   ├── App.tsx                   # Main app component
│   ├── main.tsx                  # Entry point
│   └── index.css                 # Global styles
├── public/
├── dist/                         # Production build
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## Security

### Encryption Details

- **Key Derivation**: PBKDF2 with SHA-256 (100,000 iterations)
- **Encryption**: AES-256-GCM (authenticated encryption)
- **Integrity**: HMAC-SHA256 for file tamper detection
- **Random**: Web Crypto API CSPRNG

### .vnc File Format

```
[Header - 128 bytes]     Magic, version, flags
[KDF Params - 16 bytes]  Algorithm parameters
[Salt - 32 bytes]        Random salt for key derivation
[IV - 12 bytes]          Random IV for encryption
[Ciphertext - variable]  Encrypted note data
[Auth Tag - 16 bytes]    GCM authentication tag
[HMAC - 32 bytes]        File integrity check
```

### Security Best Practices

1. **Keys never leave the browser** - All encryption happens client-side
2. **No cloud sync** - Data stored only in IndexedDB
3. **Password not stored** - Only salt and verification hash stored
4. **Constant-time comparison** - Prevents timing attacks
5. **Secure random** - Web Crypto API CSPRNG

## State Management

### Stores

- **cryptoStore** - Master key, HMAC key, QR session
- **noteStore** - Notes CRUD operations
- **labelStore** - Labels management

### Usage Example

```typescript
import { useCryptoStore } from './store/cryptoStore'
import { useNoteStore } from './store/noteStore'

// Unlock with password
const { unlockWithPassword } = useCryptoStore()
await unlockWithPassword('my-password')

// Load notes
const { loadNotes } = useNoteStore()
await loadNotes()

// Create note
const { createNote } = useNoteStore()
await createNote({
  id: uuid(),
  title: 'My Note',
  body: 'Content',
  labels: ['work'],
  color: '#FFFFFF',
  created: new Date().toISOString(),
  modified: new Date().toISOString(),
  pinned: false,
  archived: false,
})
```

## Development Guidelines

### Code Style

- TypeScript strict mode enabled
- ESLint with React hooks rules
- Prettier for formatting
- Tailwind CSS for styling

### Component Structure

```typescript
import { useState } from 'react'
import { useNoteStore } from '../../store/noteStore'

export default function MyComponent() {
  const { notes } = useNoteStore()
  const [state, setState] = useState('')

  const handleClick = () => {
    // Handler logic
  }

  return (
    <div className="container">
      {/* JSX */}
    </div>
  )
}
```

### Testing

```bash
# Run build tests
./scripts/test.sh

# Type check
npx tsc --noEmit

# Lint
npm run lint
```

## Deployment

### Static Hosting

The `dist/` folder can be deployed to any static hosting:

- **Vercel**: Automatic deployment from git
- **Netlify**: Drag & drop dist folder
- **GitHub Pages**: Push dist to gh-pages branch
- **Firebase Hosting**: `firebase deploy`
- **Self-hosted**: Serve with nginx/Apache

### Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build
FROM nginx:alpine
COPY --from=0 /app/dist /usr/share/nginx/html
EXPOSE 80
```

### Environment Variables

No environment variables required for basic usage.

For custom builds:

```env
VITE_APP_TITLE=VaultNote
VITE_API_URL=  # Not used (offline-first)
```

## Troubleshooting

### Build Errors

```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
npm run build
```

### TypeScript Errors

```bash
# Check types
npx tsc --noEmit

# Regenerate types if needed
npx tsc --init
```

### Development Server Issues

```bash
# Kill stuck process
killall -9 node

# Clear Vite cache
rm -rf node_modules/.vite
npm run dev
```

## Browser Support

| Browser | Version |
|---------|---------|
| Chrome | 88+ |
| Firefox | 87+ |
| Safari | 14+ |
| Edge | 88+ |

Required: Web Crypto API, IndexedDB

## Performance

- **Initial load**: ~300KB gzipped
- **First interaction**: < 100ms
- **Note encryption**: < 500ms
- **Search**: < 100ms for 100 notes

## Contributing

1. Fork the repository
2. Create feature branch
3. Make changes
4. Run tests: `./scripts/test.sh`
5. Submit PR

## License

MIT License - See LICENSE file

## Links

- **Flutter App**: `/root/vaultnote/flutter`
- **Documentation**: `/root/vaultnote/README.md`
- **Build Scripts**: `./scripts/`

---

**VaultNote** - Your notes, securely encrypted
