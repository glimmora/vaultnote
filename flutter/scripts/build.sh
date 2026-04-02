#!/bin/bash

# VaultNote Flutter Build Script
# Production-ready: split per ABI, obfuscation, signing

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error()   { echo -e "${RED}✗ $1${NC}"; }
print_info()    { echo -e "${YELLOW}ℹ $1${NC}"; }

show_help() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
    -t, --type TYPE       Build type: apk, appbundle (default: apk)
    -m, --mode MODE       Build mode: release, profile, debug (default: release)
    -s, --split-abi       Split build per ABI (armeabi-v7a, arm64-v8a, x86_64)
    -k, --sign            Sign the APK/AAB with release key
    -c, --clean           Clean build before building
    -n, --no-obfuscate    Disable code obfuscation
    -h, --help            Show this help message

Examples:
    $(basename "$0")                          # Build release APK
    $(basename "$0") -s                       # Build split per ABI
    $(basename "$0") -s -k                    # Build split per ABI and sign
    $(basename "$0") -t appbundle -k          # Build signed App Bundle
    $(basename "$0") -c -s -k                 # Clean, split ABI, and sign

EOF
}

BUILD_TYPE="apk"
BUILD_MODE="release"
SPLIT_PER_ABI=false
SIGN_APK=false
CLEAN_BUILD=false
OBFUSCATE=true

while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type) BUILD_TYPE="$2"; shift 2 ;;
        -m|--mode) BUILD_MODE="$2"; shift 2 ;;
        -s|--split-abi) SPLIT_PER_ABI=true; shift ;;
        -k|--sign) SIGN_APK=true; shift ;;
        -c|--clean) CLEAN_BUILD=true; shift ;;
        -n|--no-obfuscate) OBFUSCATE=false; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) print_error "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

if [[ "$BUILD_TYPE" != "apk" && "$BUILD_TYPE" != "appbundle" ]]; then
    print_error "Invalid build type: $BUILD_TYPE"; exit 1
fi
if [[ "$BUILD_MODE" != "release" && "$BUILD_MODE" != "profile" && "$BUILD_MODE" != "debug" ]]; then
    print_error "Invalid build mode: $BUILD_MODE"; exit 1
fi

print_header "VaultNote Build Configuration"
echo -e "Build Type:      ${GREEN}$BUILD_TYPE${NC}"
echo -e "Build Mode:      ${GREEN}$BUILD_MODE${NC}"
echo -e "Split Per ABI:   ${GREEN}$SPLIT_PER_ABI${NC}"
echo -e "Sign APK:        ${GREEN}$SIGN_APK${NC}"
echo -e "Clean Build:     ${GREEN}$CLEAN_BUILD${NC}"
echo -e "Obfuscate:       ${GREEN}$OBFUSCATE${NC}"
echo ""

cd "$PROJECT_DIR"

if [[ "$CLEAN_BUILD" == true ]]; then
    print_header "Cleaning Build"
    flutter clean
    rm -rf build/
    print_success "Clean completed"
    echo ""
fi

print_header "Getting Dependencies"
flutter pub get
print_success "Dependencies installed"
echo ""

BUILD_ARGS=()
if [[ "$BUILD_MODE" == "release" ]]; then
    BUILD_ARGS+=(--release)
fi
if [[ "$OBFUSCATE" == true && "$BUILD_MODE" == "release" ]]; then
    BUILD_ARGS+=(--obfuscate --split-debug-info=build/symbols)
fi
if [[ "$SPLIT_PER_ABI" == true ]]; then
    BUILD_ARGS+=(--split-per-abi)
fi

if [[ "$SIGN_APK" == true ]]; then
    KEYSTORE_FILE="$PROJECT_DIR/android/keystore/vaultnote-release-key.keystore"
    if [[ ! -f "$KEYSTORE_FILE" ]]; then
        print_error "Keystore not found: $KEYSTORE_FILE"
        print_info "Run 'scripts/create_keystore.sh' to create a release key"
        exit 1
    fi
    KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"
    if [[ ! -f "$KEY_PROPERTIES" ]]; then
        cat > "$KEY_PROPERTIES" << EOF
storePassword=android
keyPassword=android
keyAlias=vaultnote
storeFile=$KEYSTORE_FILE
EOF
        print_info "Created key.properties"
    fi
fi

if [[ "$BUILD_TYPE" == "appbundle" ]]; then
    print_header "Building App Bundle"
    flutter build appbundle "${BUILD_ARGS[@]}"
    print_success "App Bundle built successfully"
else
    print_header "Building APK"
    flutter build apk "${BUILD_ARGS[@]}"
    print_success "APK built successfully"
fi

echo ""
print_header "Build Output"
if [[ -d "$BUILD_DIR" ]]; then
    ls -lh "$BUILD_DIR"/*.apk 2>/dev/null || print_info "No APK files found"
else
    print_info "Build directory not found"
fi

if [[ "$OBFUSCATE" == true && "$BUILD_MODE" == "release" ]]; then
    echo ""
    print_info "Debug symbols saved to: $PROJECT_DIR/build/symbols"
fi

echo ""
print_header "Build Summary"
if [[ -d "$BUILD_DIR" ]]; then
    for APK_FILE in "$BUILD_DIR"/*.apk; do
        if [[ -f "$APK_FILE" ]]; then
            SIZE=$(du -h "$APK_FILE" | cut -f1)
            NAME=$(basename "$APK_FILE")
            echo -e "  ${GREEN}$NAME${NC}: $SIZE"
        fi
    done
fi

echo ""
print_success "Build completed successfully!"
echo ""
