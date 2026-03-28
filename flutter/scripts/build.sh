#!/bin/bash

# VaultNote Flutter Build Script
# Supports per-ABI builds and APK signing

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
KEYSTORE_DIR="$PROJECT_DIR/android/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/vaultnote-release-key.keystore"
KEY_ALIAS="vaultnote"

# Default values
BUILD_TYPE="apk"
BUILD_MODE="release"
SPLIT_PER_ABI=false
SIGN_APK=false
CLEAN_BUILD=false
OBFUSCATE=true

# Functions
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

show_help() {
    cat << EOF
VaultNote Flutter Build Script

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

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        -m|--mode)
            BUILD_MODE="$2"
            shift 2
            ;;
        -s|--split-abi)
            SPLIT_PER_ABI=true
            shift
            ;;
        -k|--sign)
            SIGN_APK=true
            shift
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -n|--no-obfuscate)
            OBFUSCATE=false
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Validate build type
if [[ "$BUILD_TYPE" != "apk" && "$BUILD_TYPE" != "appbundle" ]]; then
    print_error "Invalid build type: $BUILD_TYPE"
    print_info "Valid types: apk, appbundle"
    exit 1
fi

# Validate build mode
if [[ "$BUILD_MODE" != "release" && "$BUILD_MODE" != "profile" && "$BUILD_MODE" != "debug" ]]; then
    print_error "Invalid build mode: $BUILD_MODE"
    print_info "Valid modes: release, profile, debug"
    exit 1
fi

# Check if signing is requested but keystore doesn't exist
if [[ "$SIGN_APK" == true && ! -f "$KEYSTORE_FILE" ]]; then
    print_error "Keystore file not found: $KEYSTORE_FILE"
    print_info "Run 'scripts/create_keystore.sh' to create a release key"
    exit 1
fi

# Print build configuration
print_header "VaultNote Build Configuration"
echo -e "Build Type:      ${GREEN}$BUILD_TYPE${NC}"
echo -e "Build Mode:      ${GREEN}$BUILD_MODE${NC}"
echo -e "Split Per ABI:   ${GREEN}$SPLIT_PER_ABI${NC}"
echo -e "Sign APK:        ${GREEN}$SIGN_APK${NC}"
echo -e "Clean Build:     ${GREEN}$CLEAN_BUILD${NC}"
echo -e "Obfuscate:       ${GREEN}$OBFUSCATE${NC}"
echo ""

# Change to project directory
cd "$PROJECT_DIR"

# Clean if requested
if [[ "$CLEAN_BUILD" == true ]]; then
    print_header "Cleaning Build"
    flutter clean
    rm -rf build/
    print_success "Clean completed"
    echo ""
fi

# Get Flutter version
print_header "Environment Check"
flutter --version
echo ""

# Get dependencies
print_header "Getting Dependencies"
flutter pub get
print_success "Dependencies installed"
echo ""

# Build arguments
BUILD_ARGS=()

if [[ "$BUILD_MODE" == "release" ]]; then
    BUILD_ARGS+=(--release)
fi

if [[ "$OBFUSCATE" == true && "$BUILD_MODE" == "release" ]]; then
    BUILD_ARGS+=(--obfuscate)
    BUILD_ARGS+=(--split-debug-info=build/symbols)
fi

# Signing configuration
if [[ "$SIGN_APK" == true ]]; then
    print_header "Signing Configuration"
    
    # Create key.properties if it doesn't exist
    KEY_PROPERTIES="$PROJECT_DIR/android/key.properties"
    if [[ ! -f "$KEY_PROPERTIES" ]]; then
        cat > "$KEY_PROPERTIES" << EOF
storePassword=android
keyPassword=android
keyAlias=$KEY_ALIAS
storeFile=$KEYSTORE_FILE
EOF
        print_info "Created key.properties (update with your actual passwords)"
    fi
    
    print_success "Signing configured"
    echo ""
fi

# Build
if [[ "$SPLIT_PER_ABI" == true ]]; then
    print_header "Building Split APKs (Per ABI)"
    
    ABIS=("armeabi-v7a" "arm64-v8a" "x86_64")
    
    for ABI in "${ABIS[@]}"; do
        print_info "Building for $ABI..."
        
        ABI_BUILD_ARGS=("${BUILD_ARGS[@]}")
        ABI_BUILD_ARGS+=(--split-per-abi)
        ABI_BUILD_ARGS+=(--target-platform android-$ABI)
        
        if [[ "$BUILD_TYPE" == "appbundle" ]]; then
            ABI_BUILD_ARGS+=(build appbundle)
        else
            ABI_BUILD_ARGS+=(build apk)
        fi
        
        flutter build "${ABI_BUILD_ARGS[@]}"
        
        print_success "Built for $ABI"
    done
    
    print_success "All ABI builds completed"
else
    print_header "Building $BUILD_TYPE"
    
    if [[ "$BUILD_TYPE" == "appbundle" ]]; then
        flutter build appbundle "${BUILD_ARGS[@]}"
        print_success "App Bundle built successfully"
    else
        flutter build apk "${BUILD_ARGS[@]}"
        print_success "APK built successfully"
    fi
fi

echo ""

# Sign APK if requested (for unsigned builds)
if [[ "$SIGN_APK" == true && "$BUILD_TYPE" == "apk" ]]; then
    print_header "Signing APKs"
    
    # Find APKs to sign
    if [[ "$SPLIT_PER_ABI" == true ]]; then
        APK_FILES=("$BUILD_DIR"/app-*-release.apk)
    else
        APK_FILES=("$BUILD_DIR"/app-release.apk)
    fi
    
    for APK_FILE in "${APK_FILES[@]}"; do
        if [[ -f "$APK_FILE" ]]; then
            APK_NAME=$(basename "$APK_FILE")
            UNSIGNED_DIR="$BUILD_DIR/unsigned"
            mkdir -p "$UNSIGNED_DIR"
            
            # Move original to unsigned folder
            mv "$APK_FILE" "$UNSIGNED_DIR/"
            
            # Sign the APK
            print_info "Signing $APK_NAME..."
            
            "$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools" | tail -1)/apksigner" sign \
                --ks "$KEYSTORE_FILE" \
                --ks-key-alias "$KEY_ALIAS" \
                --ks-pass pass:android \
                --key-pass pass:android \
                --out "$APK_FILE" \
                "$UNSIGNED_DIR/$APK_NAME"
            
            # Verify signature
            if "$ANDROID_HOME/build-tools/$(ls "$ANDROID_HOME/build-tools" | tail -1)/apksigner" verify "$APK_FILE"; then
                print_success "Signed and verified: $APK_NAME"
            else
                print_error "Failed to verify: $APK_NAME"
            fi
        fi
    done
    
    echo ""
fi

# Print build output
print_header "Build Output"
if [[ "$BUILD_TYPE" == "apk" ]]; then
    if [[ -d "$BUILD_DIR" ]]; then
        ls -lh "$BUILD_DIR"/*.apk 2>/dev/null || print_info "No APK files found"
    fi
else
    BUNDLE_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"
    if [[ -d "$BUNDLE_DIR" ]]; then
        ls -lh "$BUNDLE_DIR"/*.aab 2>/dev/null || print_info "No AAB files found"
    fi
fi

echo ""

# Print debug symbols location
if [[ "$OBFUSCATE" == true && "$BUILD_MODE" == "release" ]]; then
    print_info "Debug symbols saved to: $PROJECT_DIR/build/symbols"
    echo ""
fi

# Summary
print_header "Build Summary"
TOTAL_SIZE=0
if [[ "$BUILD_TYPE" == "apk" && -d "$BUILD_DIR" ]]; then
    for APK_FILE in "$BUILD_DIR"/*.apk; do
        if [[ -f "$APK_FILE" ]]; then
            SIZE=$(du -h "$APK_FILE" | cut -f1)
            NAME=$(basename "$APK_FILE")
            echo -e "  ${GREEN}$NAME${NC}: $SIZE"
        fi
    done
elif [[ "$BUILD_TYPE" == "appbundle" ]]; then
    BUNDLE_DIR="$PROJECT_DIR/build/app/outputs/bundle/release"
    if [[ -f "$BUNDLE_DIR/app-release.aab" ]]; then
        SIZE=$(du -h "$BUNDLE_DIR/app-release.aab" | cut -f1)
        echo -e "  ${GREEN}app-release.aab${NC}: $SIZE"
    fi
fi

echo ""
print_success "Build completed successfully!"
echo ""
print_info "To install on device: adb install -r $BUILD_DIR/app-release.apk"
echo ""
