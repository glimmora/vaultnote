# VaultNote Build Scripts

This directory contains scripts for building, signing, and managing VaultNote Flutter builds.

## Quick Start - First Time Setup

If you're setting up the development environment for the first time:

```bash
# Full setup (installs Flutter, Android SDK, and configures environment)
./scripts/setup.sh

# After setup, reload your shell
source ~/.bashrc  # or source ~/.zshrc

# Verify installation
flutter doctor -v
```

## Prerequisites

Before using the build scripts, ensure you have:

1. **Flutter SDK** installed and in your PATH
2. **Android SDK** with `ANDROID_HOME` environment variable set
3. **Java JDK** for keystore creation
4. **adb** for device installation

**Don't have these?** Run `./scripts/setup.sh` to install everything automatically.

## Quick Start

### Environment Setup (First Time Only)

```bash
# Install Flutter, Android SDK, and configure environment
./scripts/setup.sh

# Or just configure environment (if tools already installed)
./scripts/setup_env.sh

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

### First Time Build Setup

```bash
# 1. Create a release signing key
./scripts/create_keystore.sh

# 2. Build all variants (split APKs + universal + App Bundle)
./scripts/build_all.sh
```

### Development Build

```bash
# Quick debug build for testing
./scripts/build_debug.sh

# Install on connected device
./scripts/install.sh

# Install debug version
./scripts/install.sh --debug
```

### Release Build

```bash
# Build release APK
./scripts/build.sh

# Build with split per ABI
./scripts/build.sh --split-abi

# Build and sign
./scripts/build.sh --split-abi --sign

# Build App Bundle for Google Play
./scripts/build.sh --type appbundle --sign

# Clean, split ABI, and sign
./scripts/build.sh --clean --split-abi --sign
```

### Verify Release

```bash
# Verify APK signature and integrity
./scripts/verify_release.sh
```

## Scripts Reference

### `setup.sh` - Complete Environment Setup

Installs Flutter, Android SDK, and configures the development environment.

**Usage:**
```bash
./scripts/setup.sh
```

**Options:**
- `--no-flutter` - Skip Flutter installation
- `--no-android-sdk` - Skip Android SDK installation
- `--android-studio` - Install Android Studio (optional)
- `--no-jdk` - Skip OpenJDK installation
- `--flutter-only` - Only install Flutter
- `--sdk-only` - Only install Android SDK

**What it does:**
1. Installs system dependencies (curl, git, unzip, etc.)
2. Installs OpenJDK 17 (if not present)
3. Installs Flutter SDK
4. Installs Android SDK with required components
5. Configures environment variables
6. Creates convenience aliases
7. Runs `flutter doctor` for verification

**Aliases created:**
- `vn` - Navigate to Flutter project
- `vn-build` - Build release APK
- `vn-debug` - Quick debug build
- `vn-install` - Install on device
- `vn-doctor` - Run flutter doctor
- `vn-clean` - Clean and get dependencies

### `setup_env.sh` - Environment Configuration Only

Configures environment variables without installing anything. Use this if you already have Flutter and Android SDK installed.

**Usage:**
```bash
./scripts/setup_env.sh
```

**What it does:**
1. Detects existing Flutter installation
2. Detects existing Android SDK
3. Creates `~/.vaultnote_env` with environment variables
4. Adds sourcing to shell config (`.bashrc` or `.zshrc`)
5. Creates project aliases

### `build.sh` - Main Build Script

Builds the Flutter app with various options.

**Options:**
- `-t, --type TYPE` - Build type: `apk` or `appbundle` (default: `apk`)
- `-m, --mode MODE` - Build mode: `release`, `profile`, or `debug` (default: `release`)
- `-s, --split-abi` - Split build per ABI (armeabi-v7a, arm64-v8a, x86_64)
- `-k, --sign` - Sign the APK/AAB with release key
- `-c, --clean` - Clean build before building
- `-n, --no-obfuscate` - Disable code obfuscation
- `-h, --help` - Show help message

**Examples:**
```bash
# Basic release build
./scripts/build.sh

# Split per ABI with signing
./scripts/build.sh -s -k

# Build signed App Bundle
./scripts/build.sh -t appbundle -k

# Full clean build with obfuscation
./scripts/build.sh -c -s -k
```

### `create_keystore.sh` - Create Signing Key

Creates a release signing keystore for the app.

**Usage:**
```bash
./scripts/create_keystore.sh
```

**What it does:**
1. Creates a keystore directory
2. Generates a new RSA 2048-bit key
3. Creates `key.properties` with signing configuration
4. Adds keystore to `.gitignore`
5. Displays security best practices

**Important:** 
- Backup your keystore in a secure location
- Never lose your keystore - you cannot update your app without it
- Store passwords in a password manager

### `build_all.sh` - Build All Variants

Builds all APK variants and organizes outputs.

**What it builds:**
- Split APKs (armeabi-v7a, arm64-v8a, x86_64)
- Universal APK (all architectures)
- App Bundle (for Google Play)
- Debug symbols

**Output structure:**
```
build/outputs/v{version}/
├── VaultNote-v{version}-armeabi-v7a.apk
├── VaultNote-v{version}-arm64-v8a.apk
├── VaultNote-v{version}-x86_64.apk
├── VaultNote-v{version}-universal.apk
├── VaultNote-v{version}.aab
├── symbols/
└── *.sha256 (checksums)
```

### `build_debug.sh` - Quick Debug Build

Fast build for development and testing.

**Usage:**
```bash
./scripts/build_debug.sh
```

**Output:** `build/app/outputs/flutter-apk/app-debug.apk`

### `install.sh` - Install on Device

Installs the built APK on a connected device.

**Options:**
- `-d, --debug` - Install debug APK
- `-u, --uninstall` - Uninstall app before installing

**Examples:**
```bash
# Install release version
./scripts/install.sh

# Install debug version
./scripts/install.sh --debug

# Uninstall and reinstall
./scripts/install.sh --uninstall
```

### `verify_release.sh` - Verify Release Build

Verifies APK signature, alignment, and metadata.

**Checks performed:**
1. File existence and readability
2. ZIP alignment
3. APK signature verification
4. App version info
5. Package name validation
6. Target SDK version
7. Declared permissions

**Usage:**
```bash
./scripts/verify_release.sh
```

## Build Configuration

### ABI Targets

| ABI | Architecture | Devices |
|-----|-------------|---------|
| `armeabi-v7a` | 32-bit ARM | Older Android devices |
| `arm64-v8a` | 64-bit ARM | Modern Android devices (recommended) |
| `x86_64` | 64-bit x86 | Emulators, some tablets |

### Signing Configuration

Signing configuration is stored in `android/key.properties`:

```properties
storePassword=your_password
keyPassword=your_password
keyAlias=vaultnote
storeFile=/path/to/keystore
```

**Security:** This file is gitignored. Keep it secure!

### Obfuscation

Release builds use ProGuard/R8 obfuscation by default:
- Code is obfuscated and optimized
- Debug symbols are saved to `build/symbols/`
- Use `--no-obfuscate` to disable

## Distribution Recommendations

### Google Play Store
- Use App Bundle (`.aab`) for smaller downloads
- Enable Google Play App Signing
- Upload: `build/outputs/v{version}/VaultNote-v{version}.aab`

### Direct Distribution
- Use split APKs for smaller file sizes
- Recommended: `arm64-v8a.apk` for modern devices
- Use `universal.apk` for maximum compatibility

### F-Droid / Other Stores
- Use universal APK for simplicity
- Include SHA256 checksums for verification

## Troubleshooting

### "Keystore not found"
Run `./scripts/create_keystore.sh` to create a signing key.

### "No devices connected"
- Connect a device via USB
- Enable USB debugging on the device
- Or start an Android emulator

### "Build failed"
- Run `flutter doctor` to check your setup
- Try `./scripts/build.sh --clean`
- Check `android/app/build.gradle` for errors

### "Signature verification failed"
- Ensure you're using the correct keystore
- Check that `key.properties` has correct passwords

## Build Size Optimization

To reduce APK size:
1. Use split APKs (`--split-abi`)
2. Enable R8 obfuscation (default)
3. Remove unused resources
4. Use WebP for images
5. Analyze with: `flutter build apk --analyze-size`

## Continuous Integration

Example CI/CD workflow:

```bash
# Setup
flutter pub get

# Create keystore (or use stored secrets)
./scripts/create_keystore.sh

# Build all variants
./scripts/build_all.sh

# Verify
./scripts/verify_release.sh

# Upload artifacts
# (Upload build/outputs/v{version}/ to your artifact storage)
```

## Security Best Practices

1. **Never commit** keystore or `key.properties`
2. **Backup** your keystore in multiple secure locations
3. **Use strong** passwords (12+ characters)
4. **Consider** Google Play App Signing for additional security
5. **Verify** checksums before distributing
6. **Keep** build tools updated

## Support

For issues or questions:
1. Check Flutter documentation: https://flutter.dev/docs
2. Check Android build documentation: https://developer.android.com/studio/build
3. Review the script source code for details

---

**VaultNote** - Your notes, securely encrypted
