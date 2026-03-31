# VaultNote Build Scripts - Quick Reference

## First Time Setup (New Machine)

### Option 1: Full Setup (Recommended)
```bash
# Install Flutter, Android SDK, and configure everything
cd flutter
./scripts/setup.sh

# Reload shell configuration
source ~/.bashrc

# Verify installation
./scripts/test_setup.sh

# Create signing key (for release builds)
./scripts/create_keystore.sh
```

### Option 2: Environment Only (Tools Already Installed)
```bash
# Just configure environment variables and aliases
cd flutter
./scripts/setup_env.sh

# Reload shell configuration
source ~/.bashrc

# Verify
./scripts/test_setup.sh
```

## Common Build Commands

### Development
```bash
vn              # Navigate to project
vn-debug        # Quick debug build
vn-install      # Install on connected device
vn-clean        # Clean and get dependencies
```

### Release
```bash
vn-build        # Build release APK
vn-build-all    # Build all variants (split APKs + universal)
vn-verify       # Verify release build
```

### Maintenance
```bash
vn-doctor       # Run flutter doctor
vn-setup        # Re-run setup script
```

## Build Options

### build.sh Options
```bash
./scripts/build.sh [OPTIONS]

-t, --type TYPE       # apk or appbundle
-m, --mode MODE       # release, profile, debug  
-s, --split-abi       # Split per ABI
-k, --sign            # Sign with release key
-c, --clean           # Clean before build
```

### Common Build Commands
```bash
# Basic release build
./scripts/build.sh

# Split per ABI with signing
./scripts/build.sh -s -k

# Build App Bundle for Google Play
./scripts/build.sh -t appbundle -k

# Full clean build
./scripts/build.sh -c -s -k
```

## Output Locations

| Build Type | Location |
|------------|----------|
| Debug APK | `build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | `build/app/outputs/flutter-apk/app-release.apk` |
| Split APKs | `build/app/outputs/flutter-apk/app-*-release.apk` |
| App Bundle | `build/app/outputs/bundle/release/app-release.aab` |
| All Variants | `build/outputs/v{version}/` |

## ABI Recommendations

| ABI | Device Type | Recommended |
|-----|-------------|-------------|
| `arm64-v8a` | Modern Android (64-bit) | ✓ Primary |
| `armeabi-v7a` | Older Android (32-bit) | For compatibility |
| `x86_64` | Emulators, some tablets | For testing |
| `universal` | All architectures | Direct distribution |

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| `command not found: vn` | Run `source ~/.bashrc` |
| Flutter not found | Run `./scripts/setup.sh --flutter-only` |
| Android SDK not found | Run `./scripts/setup.sh --sdk-only` |
| Keystore not found | Run `./scripts/create_keystore.sh` |
| No devices connected | Connect device or start emulator |
| Build failed | Run `vn-clean` then try again |

## Environment Files

| File | Purpose |
|------|---------|
| `~/.vaultnote_env` | Environment variables |
| `~/.vaultnote_aliases` | Command aliases |
| `android/local.properties` | SDK/Flutter paths |
| `android/keystore/` | Signing keys (backup!) |

## Useful Commands

```bash
# Check setup
./scripts/test_setup.sh

# Check Flutter installation
flutter doctor -v

# List connected devices
adb devices

# Install APK manually
adb install -r build/app/outputs/flutter-apk/app-debug.apk

# View app logs
adb logcat | grep -i vaultnote
```

## Support

- Flutter docs: https://flutter.dev/docs
- Android docs: https://developer.android.com
- Scripts docs: `./scripts/README.md`
