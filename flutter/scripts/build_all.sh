#!/bin/bash

# VaultNote Build All Variants Script
# Builds all APK variants (split per ABI + universal) with signing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"
OUTPUT_DIR="$PROJECT_DIR/build/outputs"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}
print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${YELLOW}ℹ $1${NC}"; }

print_header "VaultNote - Build All Variants"
echo ""

cd "$PROJECT_DIR"

# Clean previous build
print_header "Cleaning Previous Build"
flutter clean
rm -rf build/
flutter pub get
print_success "Clean completed"
echo ""

# Build split per ABI + universal (handled by build.gradle splits block)
print_header "Building Split APKs (Per ABI) + Universal"
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols

echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Copy and rename outputs
print_header "Organizing Build Outputs"

VERSION=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

VERSION_DIR="$OUTPUT_DIR/v${VERSION}_${TIMESTAMP}"
mkdir -p "$VERSION_DIR"

# Copy split APKs
for ABI in armeabi-v7a arm64-v8a x86_64; do
    SRC="$BUILD_DIR/app-${ABI}-release.apk"
    if [[ -f "$SRC" ]]; then
        cp "$SRC" "$VERSION_DIR/VaultNote-v${VERSION}-${ABI}.apk"
        print_success "Copied: $ABI"
    fi
done

# Copy universal APK
if [[ -f "$BUILD_DIR/app-release.apk" ]]; then
    cp "$BUILD_DIR/app-release.apk" "$VERSION_DIR/VaultNote-v${VERSION}-universal.apk"
    print_success "Copied: universal"
fi

# Copy App Bundle if exists
BUNDLE_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"
if [[ -f "$BUNDLE_DIR/app-release.aab" ]]; then
    cp "$BUNDLE_DIR/app-release.aab" "$VERSION_DIR/VaultNote-v${VERSION}.aab"
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

print_header "Build Summary"
echo ""
print_info "Version: ${GREEN}v$VERSION${NC}"
print_info "Output Directory: ${GREEN}$VERSION_DIR${NC}"
echo ""
print_info "Files created:"
echo "  - VaultNote-v${VERSION}-armeabi-v7a.apk (32-bit ARM)"
echo "  - VaultNote-v${VERSION}-arm64-v8a.apk (64-bit ARM - most modern phones)"
echo "  - VaultNote-v${VERSION}-x86_64.apk (64-bit x86 - emulators)"
echo "  - VaultNote-v${VERSION}-universal.apk (all architectures)"
echo ""
print_success "All variants built successfully!"
echo ""
