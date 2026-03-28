# VaultNote

**Encrypted notes with military-grade encryption**

VaultNote is a secure, offline-first notes application with end-to-end encryption. Each note is stored as an encrypted `.vnc` (VaultNote Container) file using AES-256-GCM encryption with Argon2id key derivation.

## Features

### Security
- **AES-256-GCM** encryption for all notes
- **Argon2id** key derivation (m=65536, t=3, p=4)
- **HMAC-SHA256** integrity verification
- Master key stored only in RAM during session
- Auto-lock after period of inactivity
- Secure wipe on wrong password attempts

### Core Features
- Create, edit, delete notes with rich text formatting
- 9 color options for notes (like Google Keep)
- Labels/Tags for organization
- Pin important notes to top
- Search notes (decrypt-and-search in-memory)
- Dark/Light mode
- Grid & List view toggle

### Export/Import
- **QR Code Export**: Export notes as encrypted QR codes
- **QR Code Import**: Scan QR codes to import notes
- **File Export**: Export notes as `.vnc` container files
- **File Import**: Import `.vnc` files via file picker

## Project Structure

```
vaultnote/
├── flutter/          # Flutter mobile app (Android)
│   ├── lib/
│   │   ├── core/     # Crypto, storage, QR, export
│   │   ├── domain/   # Entities and use cases
│   │   └── presentation/ # UI screens and widgets
│   └── android/      # Android native code
└── web/              # React web app (Vite + TypeScript)
    ├── src/
    │   ├── core/     # Crypto, storage, QR
    │   ├── domain/   # Types and entities
    │   ├── presentation/ # React components
    │   └── store/    # Zustand state management
    └── public/
```

## Technology Stack

### Flutter App
- **Framework**: Flutter 3.x
- **State Management**: flutter_bloc
- **Crypto**: pointycastle, argon2, encrypt
- **Storage**: flutter_secure_storage, path_provider
- **QR**: qr_flutter, mobile_scanner

### Web App
- **Framework**: React 18 + TypeScript
- **Build Tool**: Vite 5
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Crypto**: Web Crypto API, argon2-browser
- **QR**: qrcode, @zxing/library

## .vnc File Format

Each note is stored as a `.vnc` file with the following structure:

```
[HEADER — 128 bytes]
  Magic "VNC\x01" | Version | Flags | Reserved

[KDF PARAMS — 16 bytes]
  Argon2id m_cost | t_cost | p_cost | Reserved

[SALT — 32 bytes]
  Cryptographically random per file

[IV/NONCE — 12 bytes]
  Cryptographically random per file

[CIPHERTEXT — variable]
  AES-256-GCM encrypted payload (gzip compressed JSON)

[GCM AUTH TAG — 16 bytes]
  Authentication tag from AES-GCM

[HMAC-SHA256 — 32 bytes]
  HMAC over entire file for tamper detection
```

## Getting Started

### Flutter App

```bash
cd vaultnote/flutter

# Install dependencies
flutter pub get

# Run the app
flutter run

# Build release APK
flutter build apk --release --obfuscate --split-debug-info=debug-info/
```

### Web App

```bash
cd vaultnote/web

# Install dependencies
npm install

# Development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Security Considerations

1. **Never store passwords**: Only salt and verification hash are stored
2. **Key management**: Master key exists only in RAM during active session
3. **Constant-time comparison**: All cryptographic comparisons use constant-time algorithms
4. **Secure deletion**: Keys are zeroed from memory on lock
5. **No plaintext on disk**: Notes are encrypted before writing to storage
6. **Tamper detection**: HMAC verification detects file modification

## Privacy

- **Offline-first**: All data stored locally on device
- **No analytics**: No tracking or telemetry
- **No cloud sync**: Your notes never leave your device unless you export them
- **Open source**: All code is auditable

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## Support

For issues and feature requests, please use the GitHub issue tracker.

---

**VaultNote** - *Your notes, securely encrypted*
# vaultnote
