# VaultNote Auto Scripts

This directory contains comprehensive automation scripts for the VaultNote project, supporting both Flutter and Web applications.

## Scripts Overview

### 1. `auto-run.sh` - Run Applications
Runs Flutter and/or Web applications with various options.

**Usage:**
```bash
./auto-run.sh [OPTIONS]
```

**Options:**
- `-f, --flutter-only` - Run Flutter app only
- `-w, --web-only` - Run Web app only
- `-d, --device DEVICE` - Flutter device ID
- `-p, --port PORT` - Web dev server port (default: 5173)
- `-b, --background` - Run in background
- `-h, --help` - Show help message

**Examples:**
```bash
./auto-run.sh                    # Run both Flutter and Web
./auto-run.sh -f                 # Run Flutter only
./auto-run.sh -w                 # Run Web only
./auto-run.sh -d chrome          # Run Flutter on Chrome
./auto-run.sh -p 3000            # Run Web on port 3000
```

---

### 2. `auto-test.sh` - Run Tests
Runs comprehensive tests for Flutter and Web applications.

**Usage:**
```bash
./auto-test.sh [OPTIONS]
```

**Options:**
- `-f, --flutter-only` - Test Flutter only
- `-w, --web-only` - Test Web only
- `-c, --coverage` - Generate coverage reports
- `-v, --verbose` - Verbose output
- `-h, --help` - Show help message

**Examples:**
```bash
./auto-test.sh                    # Test both Flutter and Web
./auto-test.sh -f                 # Test Flutter only
./auto-test.sh -w                 # Test Web only
./auto-test.sh -c                 # Test with coverage
```

**What it tests:**
- **Flutter:**
  - Static analysis (flutter analyze)
  - Unit tests (flutter test)
  - Coverage reports (optional)

- **Web:**
  - ESLint linting
  - TypeScript type checking
  - Production build verification

---

### 3. `auto-fix.sh` - Auto-Fix Issues
Automatically fixes common issues in Flutter and Web projects.

**Usage:**
```bash
./auto-fix.sh [OPTIONS]
```

**Options:**
- `-f, --flutter-only` - Fix Flutter only
- `-w, --web-only` - Fix Web only
- `-p, --no-permissions` - Skip permission fixes
- `-d, --no-deps` - Skip dependency fixes
- `-n, --no-format` - Skip code formatting
- `-a, --auto-commit` - Auto-commit fixes
- `-h, --help` - Show help message

**Examples:**
```bash
./auto-fix.sh                    # Fix all issues
./auto-fix.sh -f                 # Fix Flutter only
./auto-fix.sh -w                 # Fix Web only
./auto-fix.sh -a                 # Fix and auto-commit
```

**What it fixes:**
- Script permissions
- Flutter dependencies and cache
- Web dependencies (node_modules)
- Code formatting (Dart format, Prettier)
- Common Dart/TypeScript issues
- Line endings
- File permissions

---

### 4. `auto-build.sh` - Build Applications
Builds Flutter and Web applications with comprehensive options.

**Usage:**
```bash
./auto-build.sh [OPTIONS]
```

**Options:**
- `-f, --flutter-only` - Build Flutter only
- `-w, --web-only` - Build Web only
- `-t, --type TYPE` - Flutter build type: apk, appbundle (default: apk)
- `-m, --mode MODE` - Build mode: release, debug, profile (default: release)
- `-c, --clean` - Clean build before building
- `-s, --sign` - Sign Flutter APK/AAB
- `-v, --verbose` - Verbose output
- `-o, --output DIR` - Output directory (default: build-output)
- `-h, --help` - Show help message

**Examples:**
```bash
./auto-build.sh                          # Build all (Flutter APK + Web)
./auto-build.sh -f                       # Build Flutter APK only
./auto-build.sh -w                       # Build Web only
./auto-build.sh -t appbundle -s          # Build signed App Bundle
./auto-build.sh -c -v                    # Clean build with verbose output
```

**Output:**
- Flutter: APK or AAB files with SHA256 checksums
- Web: Tar.gz archive with SHA256 checksums
- All outputs saved to `build-output/` directory

---

## Quick Start

### 1. Make scripts executable (if needed):
```bash
chmod +x *.sh
```

### 2. Fix any issues:
```bash
./auto-fix.sh
```

### 3. Run tests:
```bash
./auto-test.sh
```

### 4. Build applications:
```bash
./auto-build.sh
```

### 5. Run applications:
```bash
./auto-run.sh
```

---

## Workflow Examples

### Development Workflow:
```bash
# 1. Fix any issues
./auto-fix.sh

# 2. Run tests
./auto-test.sh

# 3. Run in development mode
./auto-run.sh -w  # Web only
```

### Production Build Workflow:
```bash
# 1. Clean and fix
./auto-fix.sh -a

# 2. Run full test suite
./auto-test.sh -c

# 3. Build for production
./auto-build.sh -c -s

# 4. Verify builds
ls -lh build-output/
```

### CI/CD Workflow:
```bash
# Automated pipeline
./auto-fix.sh -a
./auto-test.sh
./auto-build.sh -c
```

---

## Output Structure

```
vaultnote/
├── auto-run.sh
├── auto-test.sh
├── auto-fix.sh
├── auto-build.sh
├── build-output/
│   ├── VaultNote-v1.0.0-20260329_154948.apk
│   ├── VaultNote-v1.0.0-20260329_154948.apk.sha256
│   ├── vaultnote-web-v1.0.0-20260329_154948.tar.gz
│   └── vaultnote-web-v1.0.0-20260329_154948.tar.gz.sha256
├── flutter/
│   └── (Flutter project)
└── web/
    └── (Web project)
```

---

## Prerequisites

### Flutter:
- Flutter SDK installed
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Web:
- Node.js (v18 or higher)
- npm

### Optional:
- Git (for auto-commit feature)
- lcov (for coverage reports)

---

## Troubleshooting

### Flutter issues:
```bash
# Clean Flutter cache
flutter clean
flutter pub get

# Repair pub cache
flutter pub cache repair
```

### Web issues:
```bash
# Clean node_modules
rm -rf node_modules package-lock.json
npm install
```

### Permission issues:
```bash
# Fix script permissions
chmod +x *.sh

# Fix all file permissions
./auto-fix.sh -p
```

---

## Notes

- All scripts use color-coded output for better readability
- Scripts support both individual and combined operations
- Build outputs include SHA256 checksums for verification
- Auto-fix can automatically commit changes with `-a` flag
- All scripts have comprehensive error handling

---

## Support

For issues or questions:
1. Check the troubleshooting section
2. Run scripts with `-h` flag for help
3. Review the output logs for specific errors