#!/bin/bash

# VaultNote Quick Debug Build Script
# Fast build for development and testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header "VaultNote - Quick Debug Build"
echo ""

cd "$PROJECT_DIR"

# Get dependencies
flutter pub get

# Build debug APK
print_info "Building debug APK..."
flutter build apk --debug

# Output location
BUILD_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"
APK_FILE="$BUILD_DIR/app-debug.apk"

echo ""
if [[ -f "$APK_FILE" ]]; then
    print_success "Debug APK built successfully!"
    echo ""
    print_info "Location: $APK_FILE"
    print_info "Size: $(du -h "$APK_FILE" | cut -f1)"
    echo ""
    print_info "To install: adb install -r $APK_FILE"
else
    print_error "Build failed - APK not found"
    exit 1
fi

echo ""
