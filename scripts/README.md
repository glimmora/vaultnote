# VaultNote Scripts

This directory contains all automation scripts for the VaultNote project.

## Quick Start

```bash
# Download and cache dependencies
./scripts/run.sh download

# Fix any issues
./scripts/run.sh fix

# Run tests
./scripts/run.sh test

# Build applications
./scripts/run.sh build

# Run applications
./scripts/run.sh start
```

## Scripts

### Core

| Script | Description |
|--------|-------------|
| `run.sh` | Master script (fix, test, build, start, cache, download, install) |
| `setup.sh` | Install dependencies and configure environment |
| `fix.sh` | Auto-detect and fix common issues |
| `test.sh` | Run all tests with coverage |
| `start.sh` | Run Flutter and/or Web applications |

### Build

| Script | Description |
|--------|-------------|
| `build.sh` | Build Flutter and/or Web for production |
| `build-android.sh` | Build Android APK/AAB with signing options |
| `build-web.sh` | Build Web application |
| `auto-pipeline.sh` | Full automated CI/CD pipeline |

### Backup & Cache

| Script | Description |
|--------|-------------|
| `backup.sh` | Create compressed zip archive of the project |
| `cache-manager.sh` | Unified cache management for Flutter and Node.js |
| `flutter-cache.sh` | Flutter dependencies caching utility |
| `node-cache.sh` | Node.js dependencies caching utility |

## Cache Management

```bash
# Save dependencies to cache
./scripts/run.sh cache save

# Restore from cache
./scripts/run.sh cache restore

# Check cache status
./scripts/run.sh cache status

# Clean caches
./scripts/run.sh cache clean
```

## Backup

```bash
# Create a compressed backup (prompts for destination)
./scripts/backup.sh
```

The backup script:
- Prompts for a destination directory (defaults to `~/vaultnote-backups`)
- Excludes `node_modules`, `.git`, and cache directories
- Includes build output directories (`dist`, `build`, `build-output`)
- Calculates build output size and optionally pushes metadata to GitHub

## Documentation

Run any script with `-h` flag for help:
```bash
./scripts/run.sh -h
./scripts/fix.sh -h
./scripts/test.sh -h
./scripts/build.sh -h
./scripts/start.sh -h
./scripts/backup.sh -h
```

For detailed script documentation, see the root [`README.md`](../README.md).
