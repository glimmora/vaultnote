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

- `run.sh` - Master script (fix, test, build, start, cache, download, install)
- `fix.sh` - Fix common issues
- `test.sh` - Run tests
- `build.sh` - Build applications
- `start.sh` - Run applications
- `cache-manager.sh` - Manage caches
- `flutter-cache.sh` - Flutter cache utility
- `node-cache.sh` - Node.js cache utility

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

## Documentation

Run any script with `-h` flag for help:
```bash
./scripts/run.sh -h
./scripts/fix.sh -h
./scripts/test.sh -h
./scripts/build.sh -h
./scripts/start.sh -h