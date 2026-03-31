# VaultNote

A secure note-taking application built with Flutter and Web technologies.

## Features

- 🔐 Encrypted note storage with AES-256
- 👆 Biometric authentication (fingerprint, face)
- 📱 Cross-platform support (Android, iOS, Web)
- ✍️ Markdown support with live preview
- ☁️ Cloud sync with end-to-end encryption
- 🔍 Full-text search across all notes
- 📁 Folder organization with tags
- 🌙 Dark and light theme support

## Quick Start

### Prerequisites

- Flutter SDK (3.0 or higher)
- Node.js (16 or higher)
- Java JDK 17 (for Android development)
- Android SDK (for Android development)
- Xcode (for iOS development, macOS only)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd vaultnote
```

2. Run automated setup:
```bash
./scripts/setup.sh
```

3. Run the application:
```bash
./scripts/run.sh
```

## Development

### Project Structure

```
vaultnote/
├── flutter/          # Flutter mobile application
│   ├── lib/         # Dart source code
│   ├── android/     # Android-specific code
│   ├── ios/         # iOS-specific code
│   └── test/        # Unit and widget tests
├── web/              # Web application
│   ├── src/         # Source code
│   ├── public/      # Static assets
│   └── dist/        # Build output
├── scripts/          # Automation scripts
│   ├── setup.sh     # Install dependencies
│   ├── run.sh       # Run application
│   ├── test.sh      # Run tests
│   ├── fix.sh       # Auto-fix issues
│   ├── build.sh     # Build for production
│   ├── build-android.sh  # Build Android APK
│   ├── build-web.sh      # Build Web app
│   ├── auto-pipeline.sh  # Full CI/CD pipeline
│   └── backup.sh    # Create compressed project backup
├── build-output/     # Build artifacts
```

### Scripts

All automation scripts are located in the `scripts/` directory:

| Script | Description |
|--------|-------------|
| `setup.sh` | Install dependencies and configure environment |
| `run.sh` | Run the application (Flutter or Web) |
| `test.sh` | Run all tests with coverage |
| `fix.sh` | Auto-detect and fix common issues |
| `build.sh` | Build for production (Android + Web) |
| `build-android.sh` | Build Android APK/AAB with signing |
| `build-web.sh` | Build Web application |
| `auto-pipeline.sh` | Full automated pipeline |
| `backup.sh` | Create compressed project backup |

### Usage Examples

#### Run Application
```bash
# Auto-detect and run
./scripts/run.sh

# Run Flutter app
./scripts/run.sh flutter

# Run Web app on custom port
./scripts/run.sh web -p 8080

# Run in background
./scripts/run.sh -b
```

#### Build Application
```bash
# Build all (Android + Web)
./scripts/build.sh

# Build Android only
./scripts/build.sh -f

# Build Web only
./scripts/build.sh -w

# Build signed split APKs
./scripts/build.sh -f -s -p

# Build App Bundle
./scripts/build-android.sh -t appbundle
```

#### Run Tests
```bash
# Run all tests
./scripts/test.sh

# Run Flutter tests only
./scripts/test.sh -f

# Run Web tests only
./scripts/test.sh -w

# Generate coverage report
./scripts/test.sh -c
```

#### Auto Fix
```bash
# Auto-fix all issues
./scripts/fix.sh

# Show fixes without applying
./scripts/fix.sh -a

# Verbose output
./scripts/fix.sh -v
```

#### Full Pipeline
```bash
# Run complete pipeline
./scripts/auto-pipeline.sh

# Skip run step
./scripts/auto-pipeline.sh -s

# Skip test step
./scripts/auto-pipeline.sh -S

# Verbose with 5 retries
./scripts/auto-pipeline.sh -v -r 5
```

## Android Development

### Building APK

```bash
# Build signed split APKs per ABI
./scripts/build-android.sh

# Build single universal APK
./scripts/build-android.sh -p=false

# Build unsigned APK
./scripts/build-android.sh -s=false

# Build App Bundle for Play Store
./scripts/build-android.sh -t appbundle
```

### Signing

APKs are automatically signed with the keystore in `keystore/` directory:
- Keystore: `vaultnote-release.keystore`
- Alias: `vaultnote`
- Password: Stored in script (change for production)

## Web Development

### Building

```bash
# Build for production
./scripts/build-web.sh

# Build for development
./scripts/build-web.sh -m development

# Build with source maps
./scripts/build-web.sh -s

# Clean build
./scripts/build-web.sh -c
```

### Deployment

The build output is in `build-output/` directory:
- Extract the `.tar.gz` archive
- Serve the `dist/` folder with any web server
- Or deploy to Vercel, Netlify, or Firebase Hosting

## Testing

### Test Coverage

```bash
# Generate coverage report
./scripts/test.sh -c

# View HTML coverage report
open coverage/html/index.html
```

### Test Reports

Test reports are generated in `logs/` directory:
- `test-report-*.md` - Markdown summary
- `test-*.log` - Detailed logs

## CI/CD Pipeline

The `auto-pipeline.sh` script provides a complete CI/CD workflow:

1. **Setup** - Verify dependencies
2. **Run** - Start application (optional)
3. **Test** - Run all tests
4. **Fix** - Auto-fix issues if tests fail
5. **Re-Test** - Verify fixes
6. **Report** - Generate pipeline report

### Pipeline Options

```bash
# Full pipeline
./scripts/auto-pipeline.sh

# Flutter only
./scripts/auto-pipeline.sh -t flutter

# Skip run, test + fix only
./scripts/auto-pipeline.sh -s

# Verbose with 5 retries
./scripts/auto-pipeline.sh -v -r 5
```

## Configuration

### Environment Variables

Create `.env` file in project root:

```env
# Firebase (optional)
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id

# Cloud Sync (optional)
SYNC_SERVER_URL=https://api.vaultnote.com
SYNC_ENCRYPTION_KEY=your_encryption_key

# Development
DEBUG_MODE=true
LOG_LEVEL=verbose
```

### Build Configuration

Edit `scripts/build.sh` to customize:
- Build modes (debug, profile, release)
- Signing configuration
- Output directory
- Verbose logging

## Troubleshooting

### Common Issues

1. **Flutter not found**
   ```bash
   ./scripts/setup.sh  # Re-run setup
   ```

2. **Android build fails**
   ```bash
   ./scripts/fix.sh    # Auto-fix issues
   ./scripts/build-android.sh -c  # Clean build
   ```

3. **Tests fail**
   ```bash
   ./scripts/fix.sh    # Auto-fix issues
   ./scripts/test.sh   # Re-run tests
   ```

4. **Dependencies outdated**
   ```bash
   cd flutter && flutter pub upgrade
   cd ../web && npm update
   ```

### Logs

All logs are stored in `logs/` directory:
- `setup-*.log` - Setup logs
- `run-*.log` - Run logs
- `test-*.log` - Test logs
- `fix-*.log` - Fix logs
- `build-*.log` - Build logs
- `pipeline-*.log` - Pipeline logs

## Security

- All notes are encrypted with AES-256
- Biometric authentication required
- Cloud sync uses end-to-end encryption
- No plaintext data stored locally
- Secure key derivation with PBKDF2

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Run tests: `./scripts/test.sh`
4. Commit changes: `git commit -m 'Add amazing feature'`
5. Push to branch: `git push origin feature/amazing-feature`
6. Open pull request

## License

Private - All rights reserved

## Support

For issues and questions:
- Check `logs/` directory for error details
- Run `./scripts/fix.sh` for auto-repair
- Review `scripts/README.md` for script documentation