# VaultNote Scripts Summary

## Overview
This document summarizes the automation scripts available in the VaultNote project.

## Scripts

### Main Scripts
- **run.sh** - Master script that provides unified access to all other scripts
- **fix.sh** - Automatically fixes common issues in Flutter and Web projects
- **test.sh** - Runs comprehensive tests for Flutter and Web applications
- **build.sh** - Builds Flutter and Web applications with various options
- **start.sh** - Runs Flutter and/or Web applications

### Cache Management Scripts
- **cache-manager.sh** - Unified cache management for Flutter and Node.js
- **flutter-cache.sh** - Flutter dependencies caching utility
- **node-cache.sh** - Node.js dependencies caching utility

## Quick Start

### Download and Cache Dependencies
```bash
./scripts/run.sh download
```

### Fix Issues
```bash
./scripts/run.sh fix
```

### Run Tests
```bash
./scripts/run.sh test
```

### Build Applications
```bash
./scripts/run.sh build
```

### Run Applications
```bash
./scripts/run.sh start
```

## Cache Management

### Save Dependencies to Cache
```bash
./scripts/run.sh cache save
```

### Restore from Cache
```bash
./scripts/run.sh cache restore
```

### Check Cache Status
```bash
./scripts/run.sh cache status
```

### Clean Caches
```bash
./scripts/run.sh cache clean
```

## Build Options

### Build Flutter APK
```bash
./scripts/build.sh -f
```

### Build Flutter APK with Split per ABI
```bash
./scripts/build.sh -f -p
```

### Build Signed Flutter APK
```bash
./scripts/build.sh -f -s
```

### Build Signed Split APKs
```bash
./scripts/build.sh -f -s -p
```

### Build Flutter App Bundle
```bash
./scripts/build.sh -t appbundle
```

### Build Web Application
```bash
./scripts/build.sh -w
```

## Test Options

### Test Flutter Only
```bash
./scripts/test.sh -f
```

### Test Web Only
```bash
./scripts/test.sh -w
```

### Test with Coverage
```bash
./scripts/test.sh -c
```

## Fix Options

### Fix Flutter Only
```bash
./scripts/fix.sh -f
```

### Fix Web Only
```bash
./scripts/fix.sh -w
```

### Fix and Auto-commit
```bash
./scripts/fix.sh -a
```

## Run Options

### Run Flutter Only
```bash
./scripts/start.sh -f
```

### Run Web Only
```bash
./scripts/start.sh -w
```

### Run on Specific Device
```bash
./scripts/start.sh -d chrome
```

### Run on Specific Port
```bash
./scripts/start.sh -p 3000
```

## Cache Structure

```
~/.vaultnote-cache/
├── flutter/
│   ├── pubspec/
│   │   ├── pubspec.lock.20260329_154948
│   │   └── pubspec.yaml.sha256
│   ├── pub-cache/
│   │   └── (cached Flutter packages)
│   └── flutter-version.txt
└── node/
    ├── package/
    │   ├── package-lock.json.20260329_154948
    │   └── package.json.sha256
    ├── npm-cache/
    │   └── (cached npm packages)
    ├── node-version.txt
    └── npm-version.txt
```

## Output Structure

```
vaultnote/
├── scripts/
│   ├── run.sh
│   ├── fix.sh
│   ├── test.sh
│   ├── build.sh
│   ├── start.sh
│   ├── cache-manager.sh
│   ├── flutter-cache.sh
│   ├── node-cache.sh
│   └── README.md
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

## Prerequisites

### Flutter
- Flutter SDK installed
- Android SDK (for Android builds)
- Xcode (for iOS builds, macOS only)

### Web
- Node.js (v18 or higher)
- npm

### Optional
- Git (for auto-commit feature)
- lcov (for coverage reports)

## Notes

- All scripts use color-coded output for better readability
- Scripts support both individual and combined operations
- Build outputs include SHA256 checksums for verification
- Fix script can automatically commit changes with `-a` flag
- All scripts have comprehensive error handling
- Caches are stored in `~/.vaultnote-cache/` directory
- Dependencies can be downloaded once and reused multiple times

## Troubleshooting

### Flutter Issues
```bash
# Clean Flutter cache
./scripts/flutter-cache.sh clean

# Restore Flutter cache
./scripts/flutter-cache.sh restore
```

### Web Issues
```bash
# Clean Node.js cache
./scripts/node-cache.sh clean

# Restore Node.js cache
./scripts/node-cache.sh restore
```

### Permission Issues
```bash
# Fix script permissions
./scripts/fix.sh -p
```

### Cache Issues
```bash
# Check cache status
./scripts/run.sh cache status

# Clean all caches
./scripts/run.sh cache clean

# Re-download dependencies
./scripts/run.sh download
```

## Support

For issues or questions:
1. Check the troubleshooting section
2. Run scripts with `-h` flag for help
3. Review the output logs for specific errors
4. Check cache status with `./scripts/run.sh cache status`