#!/bin/bash

# VaultNote Quick Commands Reference
# Copy this to your notes for easy access

# ============================================
# SETUP & INSTALLATION
# ============================================

# Initial setup (run once)
./scripts/setup.sh

# ============================================
# DEVELOPMENT
# ============================================

# Run app locally
./scripts/run.sh              # Auto-detect platform
./scripts/run.sh flutter      # Flutter only
./scripts/run.sh web          # Web only
./scripts/run.sh web -p 8080  # Web on custom port

# Run tests
./scripts/test.sh             # All tests
./scripts/test.sh -f          # Flutter only
./scripts/test.sh -w          # Web only

# Auto-fix issues
./scripts/fix.sh               # Fix all issues
./scripts/fix.sh -v           # Verbose output

# ============================================
# BUILDING
# ============================================

# Quick builds
./scripts/build-all.sh        # Build everything (APK+AAB+Web)
./scripts/build.sh -f         # Android APK only
./scripts/build.sh -f -t appbundle -s  # Android AAB (Play Store)
./scripts/build.sh -w         # Web only

# Full pipeline (build + test + verify)
./scripts/auto-pipeline.sh    # Full pipeline
./scripts/auto-pipeline.sh -v # Verbose
./scripts/auto-pipeline.sh -n # Dry run

# ============================================
# INSTALLATION & TESTING
# ============================================

# Install on Android device
adb install-multiple dist/android/apk/*.apk

# Test web locally
cd dist/web && python3 -m http.server 8000
# Access: http://localhost:8000

# ============================================
# DEPLOYMENT
# ============================================

# Deploy to Google Play Store
# 1. Build AAB
./scripts/build.sh -f -t appbundle -s
# 2. Upload dist/android/aab/app-release.aab to Play Console
# 3. Fill version info and submit

# Deploy web
./scripts/deploy.sh web-local   # Local server
./scripts/deploy.sh web-s3      # AWS S3
./scripts/deploy.sh web-firebase # Firebase

# ============================================
# RELEASES
# ============================================

# Create release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
# (GitHub Actions automatically builds and uploads)

# ============================================
# TROUBLESHOOTING
# ============================================

# Clear Flutter cache
./scripts/flutter-cache.sh

# Clear Web cache
cd web && rm -rf node_modules && npm ci

# Clean rebuild
./scripts/build.sh -f -c -v

# View detailed logs
ls -lh dist/
cat dist/BUILD_SUMMARY.md

# ============================================
# USEFUL PATHS
# ============================================

# Build outputs
dist/web                # Web production
dist/android/apk/       # Android APK files
dist/android/aab/       # Android App Bundle
dist/BUILD_SUMMARY.md   # Build info

# Documentation
BUILD_GUIDE.md          # Complete build guide
CI_CD_GUIDE.md          # CI/CD documentation
FEATURES.md             # Feature documentation
README.md               # Getting started

# Source code
flutter/lib/            # Flutter app code
web/src/                # Web app code
scripts/                # Build scripts

# ============================================
# PLATFORM REQUIREMENTS
# ============================================

# Android APK Requirements
- Flutter 3.0+
- Java JDK 17+
- Android SDK 21+

# Web Requirements
- Node.js 18+
- npm 9+

# Deployment Requirements
- Google Play Developer Account (for Play Store)
- AWS Account (for S3 deployment)
- Firebase Project (for Firebase Hosting)

# ============================================
# QUICK STATS
# ============================================

# Web Build Size
# - JS: 328.87 KB (gzip: 99.91 KB)
# - CSS: 25.02 KB (gzip: 5.20 KB)
# - Build time: 2.33 seconds
# Total size: ~354 KB

# Android APK Sizes (per ABI)
# - armeabi-v7a: ~60-80 MB
# - arm64-v8a: ~65-85 MB (recommended)
# - x86_64: ~70-90 MB

# ============================================
# GITHUB ACTIONS CI/CD
# ============================================

# Automatic triggers:
push main/develop       → CI build (APK+AAB+Web+Tests)
tag v*.*              → Release build + upload
Daily 2 AM UTC        → Scheduled builds

# Manual triggers:
GitHub Actions UI     → Workflow dispatch
create release        → Automatic build & publish

# View builds:
https://github.com/your-org/vaultnote/actions

# ============================================
# KEY FEATURES
# ============================================

✅ Encrypted notes (AES-256-GCM)
✅ Multiple platforms (Android + Web)
✅ Offline-first (no internet required)
✅ Label organization
✅ Search functionality
✅ QR code export/import
✅ File export/import (.vnc format)
✅ Auto-save (2 second interval)
✅ Dark/light theme
✅ Pin important notes
✅ Archive functionality

# ============================================
# SUPPORT
# ============================================

# For help:
cat BUILD_GUIDE.md          # Build instructions
cat CI_CD_GUIDE.md          # CI/CD help
cat FEATURES.md             # Features documentation
cat IMPLEMENTATION_SUMMARY.md # What was built

# GitHub Issues:
https://github.com/your-org/vaultnote/issues

# ============================================
# SECURITY NOTES
# ============================================

⚠️ Never commit keystore passwords!
⚠️ All encryption keys stored in RAM only
⚠️ No data stored on remote servers
⚠️ Keystore file should be backed up
⚠️ Use HTTPS for all web deployments
⚠️ Enable CORS/CSP headers on production

# ============================================
# TYPICAL WORKFLOW
# ============================================

# 1. Development
./scripts/run.sh            # Run locally
./scripts/test.sh           # Test changes

# 2. Build
./scripts/build-all.sh      # Create production builds

# 3. Deploy
./scripts/deploy.sh         # Choose target

# 4. Release (optional)
git tag v1.0.1 && git push origin v1.0.1

# ============================================
