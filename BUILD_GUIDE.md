# VaultNote Build & Deployment Guide

**Version**: 1.0.0  
**Last Updated**: April 2, 2026  
**Platforms**: Android (Flutter), Web (React)

## Quick Start

### Prerequisites

```bash
# Flutter and Dart
flutter upgrade
flutter pub get

# Node.js
node --version  # 18+ required
npm --version   # 9+ required

# Java JDK
java -version   # 17+ required

# Android (optional, for APK builds)
flutter doctor -v
```

### Build All Artifacts

```bash
# Build APK, AAB, and Web in one command
./scripts/build-all.sh

# Outputs to: ./dist/
```

## Build Targets

### 1. Android APK (Development/Testing)

**Split APK per ABI** (recommended for Play Store testing):
```bash
./scripts/build.sh -f -s -p

# Outputs:
# - app-armeabi-v7a-release.apk (32-bit ARM)
# - app-arm64-v8a-release.apk (64-bit ARM)
# - app-x86_64-release.apk (Intel)
```

**Single Universal APK**:
```bash
./scripts/build.sh -f

# Output: app-release.apk
```

**Install to Device**:
```bash
# Requires: adb + connected Android device
adb install-multiple dist/android/apk/*.apk
```

### 2. Android App Bundle (Play Store)

**Build Bundle**:
```bash
./scripts/build.sh -f -t appbundle -s

# Output: dist/android/aab/app-release.aab
```

**Test Bundle Locally** (requires bundletool):
```bash
# Install bundletool
npm install -g bundletool

# Generate APK set
bundletool build-apks \
  --bundle=dist/android/aab/app-release.aab \
  --output=app.apks

# Install on device
bundletool install-apks --apks=app.apks
```

**Upload to Play Store**:
1. Go to https://play.google.com/console
2. Select app → Internal testing → Releases
3. Create new release
4. Upload `dist/android/aab/app-release.aab`
5. Review version info, release notes, etc.
6. Submit for review

### 3. Web Build

**Production Build**:
```bash
./scripts/build.sh -w

# Output: dist/web/
```

**Development Build**:
```bash
./scripts/build.sh -w -m development

# Output: dist/web/ (with source maps)
```

**Local Testing**:
```bash
cd dist/web
python3 -m http.server 8000

# Access: http://localhost:8000
```

## Deployment Targets

### Android Deployment

#### During Development

```bash
# Build APK
./scripts/build.sh -f

# Install to connected device
adb install-multiple dist/android/apk/*.apk

# View app:
adb shell am start -n com.vaultnote.app/.MainActivity
```

#### Google Play Store

```bash
# 1. Build App Bundle
./scripts/build.sh -f -t appbundle -s

# 2. Sign (if not auto-signed)
jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
  -keystore keystore/vaultnote-release.keystore \
  -storepass $KEYSTORE_PASSWORD \
  dist/android/aab/app-release.aab vaultnote

# 3. Upload to Play Console
# https://play.google.com/console → app → releases
```

### Web Deployment

#### Local Web Server

```bash
# Copy build to web server directory
sudo cp -r dist/web/* /var/www/vaultnote/

# Serve with nginx
sudo systemctl restart nginx

# Access: http://your-server/vaultnote/
```

#### AWS S3

```bash
# Install AWS CLI
pip install awscli

# Deploy
aws s3 sync dist/web/ s3://vaultnote-web/ \
  --delete \
  --cache-control "public, max-age=3600"

# Access: https://vaultnote-web.s3.amazonaws.com/
```

#### Firebase Hosting

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login
firebase login

# Deploy
firebase deploy --only hosting

# Access: https://your-project.web.app
```

#### GitHub Pages

```bash
# Build web
./scripts/build.sh -w

# Copy to docs folder
mkdir -p docs
cp -r dist/web/* docs/

# Push to GitHub
git add docs/
git commit -m "Deploy website"
git push

# Access: https://your-username.github.io/vaultnote/
```

## CI/CD Pipeline

### Automated Builds

GitHub Actions workflows run automatically:

```yaml
# On every push to main/develop
- Build Web
- Build Android APK
- Build Android AAB
- Run tests
- Generate artifacts

# Artifacts available in: dist/
```

### Manual CI/CD Run

```bash
# Full pipeline: build + test + verify
./scripts/auto-pipeline.sh

# Build only
./scripts/build-all.sh

# Deploy after build
./scripts/auto-pipeline.sh -d -w -a
```

## Signing & Release

### Keystore Management

Keystore location: `keystore/vaultnote-release.keystore`

**Create new keystore** (production):
```bash
./scripts/setup-keystore.sh
```

**Key details**:
- Alias: `vaultnote`
- Password: Stored in `keystore/.env` (NEVER commit!)
- Validity: 25 years

### Version Management

Update version in:
- `flutter/pubspec.yaml`: `version: 1.0.0+1`
- `web/package.json`: `"version": "1.0.0"`

Create git tag:
```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

This triggers automatic release workflow!

## Troubleshooting

### Flutter Build Issues

```bash
# Clear all caches
./scripts/flutter-cache.sh

# Check Flutter setup
flutter doctor -v

# Rebuild from scratch
./scripts/build.sh -f -c

# View detailed logs
./scripts/build.sh -f -v
```

### Web Build Issues

```bash
# Clear node_modules
rm -rf web/node_modules

# Reinstall dependencies
cd web && npm ci

# Rebuild
./scripts/build.sh -w

# Check for TypeScript errors
cd web && npm run build -- --show-errors
```

### APK Installation Issues

```bash
# Check connected devices
adb devices

# Uninstall existing app
adb uninstall com.vaultnote.app

# Install fresh
adb install-multiple dist/android/apk/*.apk

# View app logs
adb logcat | grep -i vaultnote
```

## Build Artifacts Location

```
vaultnote/dist/
├── web/                    # Web application files
│   ├── index.html
│   ├── assets/
│   ├── *.js, *.css        # Production optimized
├── android/
│   ├── apk/               # Split APK per ABI
│   │   ├── app-armeabi-v7a-release.apk
│   │   ├── app-arm64-v8a-release.apk
│   │   └── app-x86_64-release.apk
│   └── aab/               # App Bundle
│       └── app-release.aab
├── releases/              # Tagged releases
│   ├── v1.0.0/
│   ├── v1.1.0/
│   └── ...
└── BUILD_SUMMARY.md       # Latest build info
```

## Build Verification

### Verify APK

```bash
# Check APK signature
jarsigner -verify -verbose dist/android/apk/app-arm64-v8a-release.apk

# Extract manifest
zipinfo -1 dist/android/apk/app-arm64-v8a-release.apk | grep -E "^(AndroidManifest|classes\.dex|lib/)"

# Get APK details
aapt dump badging dist/android/apk/app-arm64-v8a-release.apk
```

### Verify Web Build

```bash
# Check HTML
cat dist/web/index.html | head -20

# Check file sizes
du -sh dist/web/*

# Check for common issues
grep -i "console.error" dist/web/*.js || echo "No console errors"
```

## Performance Optimization

### Android

- **Split APK per ABI**: Reduces download by 40-60%
- **Proguard/R8**: Already enabled in release builds
- **Bundle size**: Monitor in Play Console

### Web

- **Minification**: Enabled by default
- **Tree shaking**: Enabled for unused code removal
- **Code splitting**: Configured in Vite

Monitor sizes:
```bash
du -sh dist/web
du -sh dist/android/apk/*
du -sh dist/android/aab/*
```

## Security Considerations

### Build Security

- Keystore password in `.env` (not committed)
- Use HTTPS for all web deployments
- Enable CORS/CSP headers
- Regular dependency updates

### Release Process

- Tag releases in git
- Review all changes before merge
- Verify build outputs before deployment
- Monitor crash reports post-release

## Support

For issues or questions:
- GitHub Issues: https://github.com/your-org/vaultnote/issues
- Documentation: See FEATURES.md and README.md
- Build logs: Check `dist/BUILD_SUMMARY.md`
