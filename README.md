# VaultNote

A **secure, offline-first note-taking application** with military-grade AES-256 encryption. Build for Android and Web with complete CI/CD automation.

**Status**: ✅ Production Ready | **Version**: 1.0.0 | **Last Updated**: April 2, 2026

## 🔐 Key Features

- **Military-Grade Encryption**: AES-256-GCM with Argon2id KDF
- **Offline-First**: All data stored locally, never sent to servers
- **Zero-Knowledge**: No passwords stored, only encrypted containers
- **Cross-Platform**: 
  - 📱 Android (Flutter) - Full native app
  - 🌐 Web (React) - Browser-based, no installation
- **Rich Features**:
  - ✍️ Note creation, editing, deletion
  - 🏷️ Labels and organization
  - 🔍 Full-text search
  - 📌 Pin important notes
  - 🎨 Custom note colors
  - 🔄 QR code export/import
  - 💾 File-based export (.vnc format)
  - 🌙 Dark/Light theme

## 📋 Documentation

- **[BUILD_GUIDE.md](BUILD_GUIDE.md)**: Comprehensive build and deployment guide
- **[CI_CD_GUIDE.md](CI_CD_GUIDE.md)**: GitHub Actions workflows and automation
- **[FEATURES.md](FEATURES.md)**: Complete feature documentation
- **[Creating Releases](#creating-releases)**: Release process

## 🚀 Quick Start

### Prerequisites

```bash
# Check versions (minimum)
flutter --version        # 3.0+
node --version          # 18+
npm --version           # 9+
java -version           # 17+
```

### Build Artifacts

**Build everything in one command**:
```bash
./scripts/build-all.sh

# Output: ./dist/
#   ├── web/                    (production web)
#   ├── android/apk/            (split APK by ABI)
#   └── android/aab/            (app bundle for Play Store)
```

### Installation

#### Android (APK)
```bash
# Build
./scripts/build.sh -f

# Install to device
adb install-multiple dist/android/apk/*.apk
```

#### Web
```bash
# Build
./scripts/build.sh -w

# Serve locally
cd dist/web && python3 -m http.server 8000

# Access: http://localhost:8000
```

## 📦 Build Outputs

All build artifacts are organized in `dist/`:

```
dist/
├── web/                          # Latest web build
│   ├── index.html
│   ├── assets/
│   └── *.js, *.css, *.woff2
│
├── android/
│   ├── apk/                      # Split APK per ABI
│   │   ├── app-armeabi-v7a-release.apk     (32-bit ARM)
│   │   ├── app-arm64-v8a-release.apk       (64-bit ARM - recommended)
│   │   └── app-x86_64-release.apk          (Intel emulators)
│   │
│   └── aab/                      # App Bundle (for Play Store)
│       └── app-release.aab
│
├── releases/                     # Tagged releases
└── BUILD_SUMMARY.md              # Latest build info
```

## 🛠️ Development

### Project Structure

```
vaultnote/
├── flutter/
│   ├── lib/
│   │   ├── domain/           # Business logic
│   │   ├── core/             # Infrastructure (crypto, storage)
│   │   └── presentation/     # UI screens & widgets
│   ├── android/              # Android config
│   └── ios/                  # iOS config
│
├── web/
│   ├── src/
│   │   ├── domain/           # Business logic
│   │   ├── core/             # Infrastructure
│   │   ├── store/            # Zustand state management
│   │   └── presentation/     # React components
│   ├── public/               # Static assets
│   └── dist/                 # Production build
│
├── scripts/
│   ├── build-all.sh          # Build all artifacts
│   ├── build.sh              # Build Flutter + Web
│   ├── build-android.sh      # Android APK/AAB only
│   ├── build-web.sh          # Web only
│   ├── deploy.sh             # Deployment script
│   ├── auto-pipeline.sh      # Full CI/CD pipeline
│   └── ...                   # Other utility scripts
│
├── dist/                     # Build outputs (generated)
└── .github/workflows/        # GitHub Actions
```

### Run App Locally

```bash
# Flutter
./scripts/run.sh flutter

# Web
./scripts/run.sh web

# Auto-detect platform
./scripts/run.sh
```

### Run Tests

```bash
./scripts/test.sh

# Or individually
cd flutter && flutter test
cd ../web && npm test
```

## 🔨 Build Commands

### Android

```bash
# Build split APK (recommended)
./scripts/build.sh -f -s -p

# Build single universal APK
./scripts/build.sh -f

# Build App Bundle (Google Play)
./scripts/build.sh -f -t appbundle -s

# Verbose with clean build
./scripts/build.sh -f -c -v
```

### Web

```bash
# Production build
./scripts/build.sh -w

# Development with source maps
./scripts/build.sh -w -m development
```

### Full Pipeline

```bash
# Complete automated build + test
./scripts/auto-pipeline.sh

# Build + deploy
./scripts/auto-pipeline.sh -d -w

# Dry run (preview)
./scripts/auto-pipeline.sh -n -v
```

## 📱 Deployment

### Google Play Store

```bash
# 1. Build App Bundle
./scripts/build.sh -f -t appbundle -s

# 2. Upload to Play Store
# https://play.google.com/console
# Releases → Internal Testing → Create Release
# Upload: dist/android/aab/app-release.aab

# 3. Monitor rollout in Play Console
```

### Web Deployment

**Local Server**:
```bash
sudo cp -r dist/web/* /var/www/vaultnote/
sudo systemctl restart nginx
```

**AWS S3**:
```bash
aws s3 sync dist/web/ s3://vaultnote-web/ --delete
```

**Firebase Hosting**:
```bash
firebase deploy --only hosting
```

**GitHub Pages**:
```bash
cp -r dist/web/* docs/
git add docs/ && git commit -m "Deploy website"
git push
```

See [CI_CD_GUIDE.md](CI_CD_GUIDE.md) for detailed deployment instructions.

## 🤖 CI/CD Automation

GitHub Actions workflows run automatically:

```yaml
# On every push to main/develop
✅ Build Web
✅ Build Android APK
✅ Build Android AAB
✅ Run Tests
✅ Security Scanning
✅ Generate Artifacts

# On tag creation (v*.*)
✅ Build Release
✅ Upload to Releases
✅ Deploy to GitHub Pages

# Daily at 2 AM UTC
✅ Scheduled Build Test
✅ Dependency Audit
```

### Workflow Files

- **[.github/workflows/ci-build.yml](.github/workflows/ci-build.yml)**: Main CI/CD
- **[.github/workflows/release.yml](.github/workflows/release.yml)**: Release & deploy
- **[.github/workflows/scheduled-builds.yml](.github/workflows/scheduled-builds.yml)**: Daily tests

## 📖 Guides

### [BUILD_GUIDE.md](BUILD_GUIDE.md)
- Build instructions for each platform
- Signing & key management
- Deployment to all platforms
- Troubleshooting common issues

### [CI_CD_GUIDE.md](CI_CD_GUIDE.md)
- GitHub Actions workflows
- Environment setup
- Deployment procedures
- Monitoring & monitoring
- Security best practices

### [FEATURES.md](FEATURES.md)
- Complete feature documentation
- Technical specifications
- Encryption details
- API reference

## 🔒 Security

**Encryption Stack**:
- **Password Derivation**: Argon2id (m=65536, t=3, p=4)
- **Master Key**: AES-256 from password + salt
- **Data Encryption**: AES-256-GCM per note
- **Integrity**: HMAC-SHA256 verification
- **Key Storage**: RAM only, cleared on lock (never written to disk)

**File Format (.vnc)**:
```
[Header: 128 bytes]
[KDF Params: 16 bytes]
[Salt: 32 bytes]
[IV: 12 bytes]
[Ciphertext: variable]
[GCM Auth Tag: 16 bytes]
[HMAC-SHA256: 32 bytes]
```

See [FEATURES.md](FEATURES.md#security-features) for complete security documentation.

## 📊 Build Status

[![CI/CD Build](https://github.com/your-org/vaultnote/workflows/CI%2FCD%20Build/badge.svg)](https://github.com/your-org/vaultnote/actions)
[![Release](https://github.com/your-org/vaultnote/workflows/Release%20%26%20Deploy/badge.svg)](https://github.com/your-org/vaultnote/actions)

Latest builds available in [dist/](dist/)

## 📦 Available Downloads

- **Android APK**: [dist/android/apk/](dist/android/apk/)
- **Android AAB**: [dist/android/aab/](dist/android/aab/)
- **Web Build**: [dist/web/](dist/web/)
- **Releases**: [GitHub Releases](../../releases)

## 🐛 Troubleshooting

### Common Issues

**Flutter build fails**:
```bash
./scripts/flutter-cache.sh  # Clear Flutter cache
./scripts/build.sh -f -c    # Clean rebuild
```

**Web build fails**:
```bash
cd web && rm -rf node_modules
npm ci && npm run build
```

**APK installation fails**:
```bash
adb uninstall com.vaultnote.app
adb install-multiple dist/android/apk/*.apk
```

See [BUILD_GUIDE.md#troubleshooting](BUILD_GUIDE.md#troubleshooting) for more issues and solutions.

## 🔄 Continuous Integration

All builds run on GitHub Actions:

```
push to main/develop  →  [CI/CD Build]  →  Artifacts in dist/
                            ↓
                         [Tests]
                            ↓
                         [Security Scan]
                            ↓
                         [Verify Artifacts]
```

View builds: [GitHub Actions](../../actions)

## 📝 Creating Releases

```bash
# 1. Update version
# flutter/pubspec.yaml: version: 1.0.1+2
# web/package.json: "version": "1.0.1"

# 2. Commit & tag
git add -A
git commit -m "Release v1.0.1"
git tag -a v1.0.1 -m "Release version 1.0.1"

# 3. Push (triggers automated release workflow)
git push origin main v1.0.1

# GitHub Actions will:
# - Build all artifacts
# - Create GitHub Release
# - Upload APK + AAB + Web
# - Deploy to GitHub Pages
```

## 📄 License

See [LICENSE](LICENSE) file

## 👥 Contributing

Contributions welcome! Please:
1. Fork repository
2. Create feature branch
3. Commit changes
4. Push & create Pull Request
5. Ensure CI/CD passes

## 📞 Support

- 🐛 [Issues](../../issues)
- 💬 [Discussions](../../discussions)
- 📚 [Documentation](docs/)

## 🙏 Acknowledgments

Built with:
- [Flutter](https://flutter.dev) - Cross-platform mobile
- [React](https://react.dev) - Web framework
- [Vite](https://vitejs.dev) - Build tool
- [Tailwind CSS](https://tailwindcss.com) - Styling
- [Argon2](https://github.com/P-H-C/phc-winner-argon2) - Password hashing
- [pointycastle](https://pub.dev/packages/pointycastle) - Cryptography

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