# VaultNote CI/CD & Deployment Documentation

**Version**: 1.0.0  
**Last Updated**: April 2, 2026

## Overview

VaultNote uses GitHub Actions for automated builds and deployments. All build artifacts are output to the `dist/` folder for easy access and deployment.

## GitHub Actions Workflows

### 1. Main CI/CD Workflow (`ci-build.yml`)

**Trigger**: Push to `main` or `develop` branches, pull requests

**Steps**:
1. **Build Web**: React/TypeScript → Production build
2. **Build Android APK**: Flutter → Split APK per ABI
3. **Build Android AAB**: Flutter → App Bundle
4. **Run Tests**: Flutter tests + Web tests
5. **Security Scan**: Trivy vulnerability scanner
6. **Create Artifacts**: Organize outputs in `dist/`

**Output**: 
```
Actions → Artifacts → complete-build
├── web/                  # Production web files
├── android/apk/          # Split APKs
├── android/aab/          # App Bundle
└── BUILD_MANIFEST.md     # Build info
```

### 2. Release Workflow (`release.yml`)

**Trigger**: Tag creation (`v*`), manual workflow dispatch

**Steps**:
1. Build release artifacts
2. Create archives (.zip, .tar.gz)
3. Upload to GitHub Releases
4. Deploy to GitHub Pages (optional)

**Outputs**:
```
Releases → v1.0.0
├── vaultnote-web-v1.0.0.zip
├── vaultnote-android-apk-v1.0.0.tar.gz
└── vaultnote-android-aab-v1.0.0.tar.gz
```

### 3. Scheduled Builds (`scheduled-builds.yml`)

**Trigger**: Daily at 2 AM UTC, manual workflow dispatch

**Steps**:
1. Daily build test
2. Dependency check & audit
3. Generate build report

## Build Outputs Directory Structure

```
dist/
├── web/                          # Latest web build
│   ├── index.html
│   ├── assets/
│   ├── *.js, *.css, *.woff2
│   └── BUILD_INFO.txt            # Build metadata
│
├── android/
│   ├── apk/                      # Split APK per ABI
│   │   ├── app-armeabi-v7a-release.apk
│   │   ├── app-armeabi-v7a-release.apk.sha256
│   │   ├── app-arm64-v8a-release.apk
│   │   ├── app-arm64-v8a-release.apk.sha256
│   │   ├── app-x86_64-release.apk
│   │   └── app-x86_64-release.apk.sha256
│   │
│   └── aab/                      # App Bundle (Play Store)
│       ├── app-release-1.0.0.aab
│       └── app-release-1.0.0.aab.sha256
│
├── releases/                     # Tagged releases
│   ├── v1.0.0/
│   │   ├── web/
│   │   ├── android/apk
│   │   └── android/aab
│   └── v1.1.0/
│       ├── web/
│       ├── android/apk
│       └── android/aab
│
├── BUILD_MANIFEST.md             # Latest build metadata
├── BUILD_SUMMARY.md              # Build summary report
└── README.md                     # Directory guide
```

## CI/CD Environment Setup

### GitHub Secrets Configuration

Required secrets for deployments:

```
SLACK_WEBHOOK              # For build notifications
FIREBASE_PROJECT_ID        # Firebase Hosting
FIREBASE_SERVICE_ACCOUNT   # Firebase credentials
AWS_ACCESS_KEY_ID          # AWS S3 deployment
AWS_SECRET_ACCESS_KEY      # AWS credentials
KEYSTORE_PASSWORD          # Android signing
```

Add secrets: Settings → Secrets and variables → Actions

### Triggering Workflows

#### Automatic Triggers
- Push to `main` or `develop` → Runs CI build
- Create git tag `v*` → Runs release workflow
- Daily at 2 AM UTC → Runs scheduled build

#### Manual Triggers
```bash
# Create release
git tag -a v1.0.0 -m "Release 1.0.0"
git push origin v1.0.0

# Or use GitHub UI:
# Releases → Draft a new release → Create
```

## Deployment Guides

### 1. Deploy to Google Play Store

**Workflow**:
1. GitHub Actions builds AAB
2. Download from workflow artifacts or releases
3. Upload to Play Console manually

**Steps**:
```bash
# 1. Trigger build
git push origin main

# 2. Wait for CI/CD to complete (15-30 min)

# 3. Download artifact
# Actions → latest run → Artifacts → android-aab
# Extract: app-release.aab

# 4. Upload to Play Store
# https://play.google.com/console
# App → Releases → Internal testing → Create release
# Upload: app-release.aab
# Fill version info, review notes, privacy policy
# Submit for review

# Or use bundletool to test first:
npm install -g bundletool
bundletool build-apks --bundle=app-release.aab --output=app.apks
bundletool install-apks --apks=app.apks
```

**Release Notes Template**:
```
# VaultNote v1.0.0

## New Features
- [List new features]

## Improvements
- [List improvements]

## Bug Fixes
- [List fixes]

## Note
All notes are encrypted locally. No data is stored on remote servers.
```

### 2. Deploy Web to Production

#### Option A: Direct Git-based Deployment

```bash
# Merge to main branch
git checkout main
git merge develop --no-ff -m "Release v1.0.0"
git tag v1.0.0
git push origin main v1.0.0

# GitHub Actions automatically:
# 1. Builds web app
# 2. Deploys to dist/web
# 3. (Optional) Deploys to GitHub Pages or Firebase
```

#### Option B: Manual Deployment

```bash
# Get latest web build
./scripts/build.sh -w

# Deploy to web server
scp -r dist/web/* user@server:/var/www/vaultnote/

# Or to AWS S3
aws s3 sync dist/web/ s3://vaultnote-web/ --delete

# Or to Firebase
firebase deploy --only hosting
```

### 3. Deploy Android APK

#### Option A: For Testing (ADB)

```bash
# Build APK
./scripts/build.sh -f

# Connect Android device via USB
adb devices

# Install
adb install-multiple dist/android/apk/*.apk
```

#### Option B: For Distribution

```bash
# 1. Build signed APK
./scripts/build.sh -f -s

# 2. Share as .apk files
#    - Email, WhatsApp, cloud storage
#    - Install via "adb install-multiple"
#    - Or direct installation from browser

# 3. Or upload to Play Store as AAB
./scripts/build.sh -f -t appbundle -s
# Then upload to Play Console (see Google Play section above)

# 4. Or generate APK set for testing
bundletool build-apks \
  --bundle=dist/android/aab/app-release.aab \
  --output=app.apks \
  --mode=universal

# Direct install from .apks file
bundletool install-apks --apks=app.apks
```

## Continuous Monitoring

### Build Status

Check build status: Settings → Badges in README

Add badge to README:
```markdown
[![CI/CD Build](https://github.com/your-org/vaultnote/workflows/CI%2FCD%20Build/badge.svg)](https://github.com/your-org/vaultnote/actions)
[![Release](https://github.com/your-org/vaultnote/workflows/Release%20%26%20Deploy/badge.svg)](https://github.com/your-org/vaultnote/actions)
```

### Artifact Retention

| Artifact | Retention | Location |
|----------|-----------|----------|
| CI builds | 30 days | Actions artifacts |
| Releases | Permanent | Releases / dist/releases/ |
| Web builds | Latest | dist/web/ |
| Android builds | Latest | dist/android/ |

### Build Performance

Monitor in Actions:
- Total duration (target: < 30 min)
- Android APK build time (target: < 15 min)
- Web build time (target: < 5 min)
- Test execution time (target: < 5 min)

## Troubleshooting

### Build Fails in GitHub Actions

**Check**:
1. GitHub Actions logs: Actions → workflow → logs
2. Artifact availability: Actions → artifacts
3. Build output: dist/ folder
4. Workflow YAML syntax

**Common Issues**:
```bash
# Flutter version mismatch
# Fix: Update flutter-version in workflow YAML

# Node version mismatch
# Fix: Update node-version in workflow YAML

# Dependency caching issues
# Fix: Run action with cache: false

# Timeout issues
# Fix: Increase timeout in workflow YAML
```

### Deployment Issues

**Web deployment fails**:
```bash
# Check web build exists
ls -la dist/web/

# Verify permissions
sudo chmod -R 755 /var/www/vaultnote/

# Test locally first
cd dist/web && python3 -m http.server 8000
```

**Android deployment fails**:
```bash
# Verify APK signature
jarsigner -verify -verbose dist/android/apk/*.apk

# Check Play Store upload
adb shell getprop ro.com.google.clientidbase android-vaultnote

# Test locally
adb install-multiple dist/android/apk/*.apk
```

## Security Best Practices

1. **Code Signing**: Use keystore for Android, certificates for web
2. **Secrets Management**: Never commit credentials or passwords
3. **SSL/TLS**: Use HTTPS for all web deployments
4. **Dependency Updates**: Run `npm audit` and `flutter pub outdated`
5. **Access Control**: Restrict deployment permissions
6. **Monitoring**: Track failed builds and deployments
7. **Backup**: Keep release artifacts for rollback

## Performance Optimization

### Reduce Build Time

```yaml
# In workflow file
- name: Cache Flutter dependencies
  uses: actions/cache@v3
  with:
    path: ~/.pub-cache
    key: ${{ runner.os }}-pub-${{ hashFiles('**/pubspec.lock') }}

- name: Cache npm dependencies
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('**/package-lock.json') }}
```

### Reduce Artifact Size

```bash
# Android APK: Split by ABI
build-apk --split-per-abi

# Web: Enable gzip compression
npm run build -- --compress

# Monitor sizes
du -sh dist/*
```

## Roll Back Procedure

### Rollback Web Deployment

```bash
# Revert to previous build
git git revert <commit-hash>
git push origin main

# GitHub Actions will rebuild previous version
# Or manually restore from backup:
cp -r /var/www/vaultnote.backup.YYYYMMDD_HHMMSS/* /var/www/vaultnote/
```

### Rollback Android (Play Store)

```bash
# Go to Play Console
# App → Releases → Internal testing / Production
# Select previous version
# Click "Roll out to X%"
```

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Flutter Build Documentation](https://flutter.dev/docs/deployment)
- [React Build Optimization](https://react.dev/learn/react-compiler)
- [Google Play Console](https://play.google.com/console)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)
