#!/bin/bash

# VaultNote Build All Variants Script
# Builds all APK variants (split per ABI + universal) with signing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"
OUTPUT_DIR="$PROJECT_DIR/build/outputs"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_header "VaultNote - Build All Variants"
echo ""

# Check if keystore exists
KEYSTORE_FILE="$PROJECT_DIR/android/keystore/vaultnote-release-key.keystore"
if [[ ! -f "$KEYSTORE_FILE" ]]; then
    print_error "Keystore not found. Run 'scripts/create_keystore.sh' first."
    exit 1
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Clean previous build
print_header "Cleaning Previous Build"
flutter clean
rm -rf build/
flutter pub get
print_success "Clean completed"
echo ""

# Build split per ABI with signing
print_header "Building Split APKs (Per ABI)"
./scripts/build.sh -s -k -c

echo ""

# Build universal APK (all ABIs in one)
print_header "Building Universal APK (All ABIs)"
./scripts/build.sh -k

echo ""

# Copy and rename outputs
print_header "Organizing Build Outputs"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
VERSION=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1)

# Create version directory
VERSION_DIR="$OUTPUT_DIR/v$VERSION"
mkdir -p "$VERSION_DIR"

# Copy split APKs
if [[ -f "$BUILD_DIR/app-armeabi-v7a-release.apk" ]]; then
    cp "$BUILD_DIR/app-armeabi-v7a-release.apk" \
       "$VERSION_DIR/VaultNote-v${VERSION}-armeabi-v7a.apk"
    print_success "Copied: armeabi-v7a"
fi

if [[ -f "$BUILD_DIR/app-arm64-v8a-release.apk" ]]; then
    cp "$BUILD_DIR/app-arm64-v8a-release.apk" \
       "$VERSION_DIR/VaultNote-v${VERSION}-arm64-v8a.apk"
    print_success "Copied: arm64-v8a"
fi

if [[ -f "$BUILD_DIR/app-x86_64-release.apk" ]]; then
    cp "$BUILD_DIR/app-x86_64-release.apk" \
       "$VERSION_DIR/VaultNote-v${VERSION}-x86_64.apk"
    print_success "Copied: x86_64"
fi

# Copy universal APK
if [[ -f "$BUILD_DIR/app-release.apk" ]]; then
    cp "$BUILD_DIR/app-release.apk" \
       "$VERSION_DIR/VaultNote-v${VERSION}-universal.apk"
    print_success "Copied: universal"
fi

# Copy App Bundle if exists
BUNDLE_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"
if [[ -f "$BUNDLE_DIR/app-release.aab" ]]; then
    cp "$BUNDLE_DIR/app-release.aab" \
       "$VERSION_DIR/VaultNote-v${VERSION}.aab"
    print_success "Copied: App Bundle"
fi

# Copy debug symbols
if [[ -d "$PROJECT_DIR/build/symbols" ]]; then
    SYMBOLS_DIR="$VERSION_DIR/symbols"
    mkdir -p "$SYMBOLS_DIR"
    cp -r "$PROJECT_DIR/build/symbols/"* "$SYMBOLS_DIR/"
    print_success "Copied: Debug symbols"
fi

echo ""

# Generate checksums
print_header "Generating Checksums"
cd "$VERSION_DIR"

for file in *.apk *.aab 2>/dev/null; do
    if [[ -f "$file" ]]; then
        sha256sum "$file" > "$file.sha256"
        print_success "Generated SHA256: $file"
    fi
done

cd "$PROJECT_DIR"
echo ""

# List outputs
print_header "Build Outputs"
echo ""
ls -lh "$VERSION_DIR"
echo ""

# Print summary
print_header "Build Summary"
echo ""
print_info "Version: ${GREEN}v$VERSION${NC}"
print_info "Output Directory: ${GREEN}$VERSION_DIR${NC}"
echo ""
print_info "Files created:"
echo "  - VaultNote-v${VERSION}-armeabi-v7a.apk (32-bit ARM devices)"
echo "  - VaultNote-v${VERSION}-arm64-v8a.apk (64-bit ARM devices - most modern phones)"
echo "  - VaultNote-v${VERSION}-x86_64.apk (64-bit x86 devices - emulators)"
echo "  - VaultNote-v${VERSION}-universal.apk (all architectures)"
echo "  - VaultNote-v${VERSION}.aab (Google Play App Bundle)"
echo ""
print_info "Recommended for distribution:"
echo "  - Google Play: Use the .aab file"
echo "  - Direct download: Use arm64-v8a.apk for modern devices"
echo "  - Universal: Use universal.apk for compatibility"
echo ""
print_success "All variants built successfully!"
echo ""
