#!/bin/bash

# VaultNote Android Build Script
# Builds Android APK with split ABI and automatic signing

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"
FLUTTER_DIR="$PROJECT_DIR/flutter"
BUILD_OUTPUT_DIR="$PROJECT_DIR/build-output"
LOG_FILE="$SCRIPTS_DIR/logs/build-android-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

# Default values
BUILD_TYPE="apk"
BUILD_MODE="release"
SIGN_BUILD=true
SPLIT_APK=true
VERBOSE=false
CLEAN_BUILD=false

# Keystore configuration
KEYSTORE_DIR="$PROJECT_DIR/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/vaultnote-release.keystore"
KEYSTORE_PASSWORD="LO3QERKYFWAVIRZQS7JNHNHKMGCIZTRB"
KEY_ALIAS="vaultnote"
KEY_PASSWORD="LO3QERKYFWAVIRZQS7JNHNHKMGCIZTRB"

# Logging functions
log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [INFO]  $*" | tee -a "$LOG_FILE"
}

log_error() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] [ERROR] $*" | tee -a "$LOG_FILE" >&2
}

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

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

show_help() {
    cat << EOF
VaultNote Android Build Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -t, --type TYPE           Build type: apk, appbundle (default: apk)
    -m, --mode MODE           Build mode: release, debug, profile (default: release)
    -s, --sign                Sign APK/AAB (default: true)
    -p, --split               Split APK per ABI (default: true)
    -c, --clean               Clean build before building
    -v, --verbose             Verbose output
    -o, --output DIR          Output directory (default: build-output)
    -h, --help                Show this help message

Examples:
    $(basename "$0")                          # Build signed split APKs
    $(basename "$0") -t appbundle             # Build signed App Bundle
    $(basename "$0") -s=false                 # Build unsigned APK
    $(basename "$0") -p=false                 # Build single APK
    $(basename "$0") -c -v                    # Clean build with verbose output

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
        -s|--sign)
            SIGN_BUILD="$2"
            shift 2
            ;;
        -p|--split)
            SPLIT_APK="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -o|--output)
            BUILD_OUTPUT_DIR="$2"
            shift 2
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

print_header "VaultNote Android Build"
echo ""

log "Starting Android build process..."

# Print build configuration
print_info "Build Configuration:"
echo -e "  Build Type: ${GREEN}$BUILD_TYPE${NC}"
echo -e "  Build Mode: ${GREEN}$BUILD_MODE${NC}"
echo -e "  Sign Build: ${GREEN}$SIGN_BUILD${NC}"
echo -e "  Split APK: ${GREEN}$SPLIT_APK${NC}"
echo -e "  Clean Build: ${GREEN}$CLEAN_BUILD${NC}"
echo -e "  Output Dir: ${GREEN}$BUILD_OUTPUT_DIR${NC}"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v flutter &> /dev/null; then
    print_error "Flutter not found. Run ./scripts/setup.sh first"
    exit 1
fi

if [[ -z "$ANDROID_SDK_ROOT" ]]; then
    print_error "Android SDK not configured. Run ./scripts/setup.sh first"
    exit 1
fi

if [[ ! -d "$FLUTTER_DIR" ]]; then
    print_error "Flutter directory not found"
    exit 1
fi

print_success "Prerequisites check passed"
echo ""

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Navigate to Flutter directory
cd "$FLUTTER_DIR"

# Clean if requested
if [[ "$CLEAN_BUILD" == true ]]; then
    print_step "Cleaning Flutter build..."
    flutter clean
    rm -rf build/
    print_success "Clean completed"
fi

# Get dependencies
print_step "Getting Flutter dependencies..."
flutter pub get
print_success "Dependencies installed"
echo ""

# Create keystore if it doesn't exist
if [[ "$SIGN_BUILD" == true && ! -f "$KEYSTORE_FILE" ]]; then
    print_step "Creating keystore..."
    mkdir -p "$KEYSTORE_DIR"
    
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -alias "$KEY_ALIAS" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -storepass "$KEYSTORE_PASSWORD" \
        -keypass "$KEY_PASSWORD" \
        -dname "CN=VaultNote, OU=Development, O=VaultNote, L=Unknown, ST=Unknown, C=US"
    
    print_success "Keystore created"
fi

# Build arguments
BUILD_ARGS=""

if [[ "$BUILD_MODE" == "release" ]]; then
    BUILD_ARGS="--release"
elif [[ "$BUILD_MODE" == "profile" ]]; then
    BUILD_ARGS="--profile"
fi

if [[ "$VERBOSE" == true ]]; then
    BUILD_ARGS="$BUILD_ARGS --verbose"
fi

# Build function
build_apk() {
    local target_platform="$1"
    local abi_name="$2"
    
    print_step "Building APK for $abi_name..."
    
    if [[ "$target_platform" == "all" ]]; then
        flutter build apk $BUILD_ARGS
    else
        flutter build apk $BUILD_ARGS --target-platform "android-$target_platform"
    fi
    
    local build_file="build/app/outputs/flutter-apk/app-release.apk"
    
    if [[ "$target_platform" != "all" ]]; then
        build_file="build/app/outputs/flutter-apk/app-$abi_name-release.apk"
    fi
    
    if [[ -f "$build_file" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local version=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1 | cut -d'+' -f1)
        local output_file="$BUILD_OUTPUT_DIR/VaultNote-v${version}-${timestamp}-${abi_name}.apk"
        
        cp "$build_file" "$output_file"
        
        # Sign APK if requested
        if [[ "$SIGN_BUILD" == true ]]; then
            print_step "Signing APK for $abi_name..."
            if [[ -f "$KEYSTORE_FILE" ]]; then
                jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                    -keystore "$KEYSTORE_FILE" \
                    -storepass "$KEYSTORE_PASSWORD" \
                    -keypass "$KEY_PASSWORD" \
                    "$output_file" "$KEY_ALIAS"
                print_success "APK signed for $abi_name"
            else
                print_error "Keystore not found at $KEYSTORE_FILE"
                exit 1
            fi
        fi
        
        # Generate checksum
        sha256sum "$output_file" > "$output_file.sha256"
        
        print_success "APK built for $abi_name"
        print_info "Output: $output_file"
        print_info "Size: $(du -h "$output_file" | cut -f1)"
        
        return 0
    else
        print_error "APK build failed for $abi_name - output file not found"
        return 1
    fi
}

build_appbundle() {
    print_step "Building App Bundle..."
    
    flutter build appbundle $BUILD_ARGS
    
    local build_file="build/app/outputs/bundle/release/app-release.aab"
    
    if [[ -f "$build_file" ]]; then
        local timestamp=$(date +%Y%m%d_%H%M%S)
        local version=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1 | cut -d'+' -f1)
        local output_file="$BUILD_OUTPUT_DIR/VaultNote-v${version}-${timestamp}.aab"
        
        cp "$build_file" "$output_file"
        
        # Sign AAB if requested
        if [[ "$SIGN_BUILD" == true ]]; then
            print_step "Signing App Bundle..."
            if [[ -f "$KEYSTORE_FILE" ]]; then
                jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                    -keystore "$KEYSTORE_FILE" \
                    -storepass "$KEYSTORE_PASSWORD" \
                    -keypass "$KEY_PASSWORD" \
                    "$output_file" "$KEY_ALIAS"
                print_success "App Bundle signed"
            else
                print_error "Keystore not found at $KEYSTORE_FILE"
                exit 1
            fi
        fi
        
        # Generate checksum
        sha256sum "$output_file" > "$output_file.sha256"
        
        print_success "App Bundle built"
        print_info "Output: $output_file"
        print_info "Size: $(du -h "$output_file" | cut -f1)"
        
        return 0
    else
        print_error "App Bundle build failed - output file not found"
        return 1
    fi
}

# Build based on type
if [[ "$BUILD_TYPE" == "appbundle" ]]; then
    if ! build_appbundle; then
        exit 1
    fi
else
    # Build APK
    if [[ "$SPLIT_APK" == true ]]; then
        print_step "Building split APKs per ABI..."
        
        # Build for each ABI
        ABIS=("arm" "arm64" "x64")
        ABI_NAMES=("armeabi-v7a" "arm64-v8a" "x86_64")
        
        for i in "${!ABIS[@]}"; do
            local abi="${ABIS[$i]}"
            local abi_name="${ABI_NAMES[$i]}"
            
            if ! build_apk "$abi" "$abi_name"; then
                print_error "Build failed for $abi_name"
                exit 1
            fi
        done
        
        print_success "All split APKs built successfully"
    else
        # Build single APK
        if ! build_apk "all" "universal"; then
            exit 1
        fi
    fi
fi

echo ""

# Print summary
print_header "Build Summary"
echo ""

if [[ "$BUILD_TYPE" == "appbundle" ]]; then
    echo -e "${CYAN}App Bundle Build:${NC}"
    echo -e "  Type: App Bundle (AAB)"
    echo -e "  Mode: $BUILD_MODE"
    echo -e "  Signed: $SIGN_BUILD"
    
    local aab_file=$(find "$BUILD_OUTPUT_DIR" -name "*.aab" -type f | head -1)
    if [[ -f "$aab_file" ]]; then
        echo -e "  Output: $(basename "$aab_file")"
        echo -e "  Size: $(du -h "$aab_file" | cut -f1)"
    fi
else
    echo -e "${CYAN}APK Build:${NC}"
    echo -e "  Type: APK"
    echo -e "  Mode: $BUILD_MODE"
    echo -e "  Signed: $SIGN_BUILD"
    echo -e "  Split APK: $SPLIT_APK"
    
    if [[ "$SPLIT_APK" == true ]]; then
        echo -e "  ABIs: armeabi-v7a, arm64-v8a, x86_64"
        echo -e "  Output files:"
        for abi_name in "${ABI_NAMES[@]}"; do
            local apk_file=$(find "$BUILD_OUTPUT_DIR" -name "*-$abi_name.apk" -type f | head -1)
            if [[ -f "$apk_file" ]]; then
                echo -e "    - $(basename "$apk_file")"
            fi
        done
    else
        local apk_file=$(find "$BUILD_OUTPUT_DIR" -name "*-universal.apk" -type f | head -1)
        if [[ -f "$apk_file" ]]; then
            echo -e "  Output: $(basename "$apk_file")"
            echo -e "  Size: $(du -h "$apk_file" | cut -f1)"
        fi
    fi
fi

echo ""
print_info "All builds saved to: $BUILD_OUTPUT_DIR"
echo ""
ls -lh "$BUILD_OUTPUT_DIR"
echo ""

print_success "Android build completed successfully!"
echo ""
print_info "Run './scripts/test.sh' to verify builds"