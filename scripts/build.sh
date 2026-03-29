#!/bin/bash

# VaultNote Auto-Build Script
# Builds Flutter and Web applications with comprehensive options

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
WEB_DIR="$PROJECT_DIR/web"
BUILD_OUTPUT_DIR="$PROJECT_DIR/build-output"

# Default values
BUILD_FLUTTER=true
BUILD_WEB=true
FLUTTER_BUILD_TYPE="apk"
FLUTTER_BUILD_MODE="release"
WEB_BUILD_MODE="production"
CLEAN_BUILD=false
SIGN_BUILD=false
SPLIT_APK=false
VERBOSE=false

# Keystore configuration
KEYSTORE_DIR="$PROJECT_DIR/keystore"
KEYSTORE_FILE="$KEYSTORE_DIR/vaultnote-release.keystore"
KEYSTORE_PASSWORD="LO3QERKYFWAVIRZQS7JNHNHKMGCIZTRB"
KEY_ALIAS="vaultnote"
KEY_PASSWORD="LO3QERKYFWAVIRZQS7JNHNHKMGCIZTRB"

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
VaultNote Auto-Build Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --flutter-only        Build Flutter only
    -w, --web-only            Build Web only
    -t, --type TYPE           Flutter build type: apk, appbundle (default: apk)
    -m, --mode MODE           Build mode: release, debug, profile (default: release)
    -c, --clean               Clean build before building
    -s, --sign                Sign Flutter APK/AAB
    -p, --split               Split APK per ABI (armeabi-v7a, arm64-v8a, x86_64)
    -v, --verbose             Verbose output
    -o, --output DIR          Output directory (default: build-output)
    -h, --help                Show this help message

Examples:
    $(basename "$0")                          # Build all (Flutter APK + Web)
    $(basename "$0") -f                       # Build Flutter APK only
    $(basename "$0") -w                       # Build Web only
    $(basename "$0") -t appbundle -s          # Build signed App Bundle
    $(basename "$0") -f -s -p                 # Build signed split APKs per ABI
    $(basename "$0") -c -v                    # Clean build with verbose output

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flutter-only)
            BUILD_WEB=false
            shift
            ;;
        -w|--web-only)
            BUILD_FLUTTER=false
            shift
            ;;
        -t|--type)
            FLUTTER_BUILD_TYPE="$2"
            shift 2
            ;;
        -m|--mode)
            FLUTTER_BUILD_MODE="$2"
            WEB_BUILD_MODE="$2"
            shift 2
            ;;
        -c|--clean)
            CLEAN_BUILD=true
            shift
            ;;
        -s|--sign)
            SIGN_BUILD=true
            shift
            ;;
        -p|--split)
            SPLIT_APK=true
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

print_header "VaultNote Auto-Build"
echo ""

# Print build configuration
print_info "Build Configuration:"
echo -e "  Flutter: ${GREEN}$BUILD_FLUTTER${NC}"
echo -e "  Web: ${GREEN}$BUILD_WEB${NC}"
echo -e "  Flutter Type: ${GREEN}$FLUTTER_BUILD_TYPE${NC}"
echo -e "  Build Mode: ${GREEN}$FLUTTER_BUILD_MODE${NC}"
echo -e "  Clean Build: ${GREEN}$CLEAN_BUILD${NC}"
echo -e "  Sign Build: ${GREEN}$SIGN_BUILD${NC}"
echo -e "  Output Dir: ${GREEN}$BUILD_OUTPUT_DIR${NC}"
echo ""

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Check prerequisites
print_step "Checking prerequisites..."

if [[ "$BUILD_FLUTTER" == true ]]; then
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        print_success "Flutter: $FLUTTER_VERSION"
    else
        print_error "Flutter not found"
        exit 1
    fi
fi

if [[ "$BUILD_WEB" == true ]]; then
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js: $NODE_VERSION"
    else
        print_error "Node.js not found"
        exit 1
    fi
fi

echo ""

# Build Flutter
if [[ "$BUILD_FLUTTER" == true ]]; then
    print_header "Building Flutter App"
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
    
    # Build arguments
    BUILD_ARGS=""
    
    if [[ "$FLUTTER_BUILD_MODE" == "release" ]]; then
        BUILD_ARGS="--release"
    elif [[ "$FLUTTER_BUILD_MODE" == "profile" ]]; then
        BUILD_ARGS="--profile"
    fi
    
    if [[ "$VERBOSE" == true ]]; then
        BUILD_ARGS="$BUILD_ARGS --verbose"
    fi
    
    # Handle split APKs
    if [[ "$SPLIT_APK" == true && "$FLUTTER_BUILD_TYPE" == "apk" ]]; then
        print_step "Building split APKs per ABI..."
        
        # Build for each ABI
        ABIS=("arm" "arm64" "x64")
        ABI_NAMES=("armeabi-v7a" "arm64-v8a" "x86_64")
        
        for i in "${!ABIS[@]}"; do
            ABI="${ABIS[$i]}"
            ABI_NAME="${ABI_NAMES[$i]}"
            print_step "Building APK for $ABI_NAME..."
            flutter build apk $BUILD_ARGS --target-platform "android-$ABI"
            
            BUILD_FILE="build/app/outputs/flutter-apk/app-$ABI-release.apk"
            
            if [[ -f "$BUILD_FILE" ]]; then
                TIMESTAMP=$(date +%Y%m%d_%H%M%S)
                VERSION=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1 | cut -d'+' -f1)
                OUTPUT_FILE="$BUILD_OUTPUT_DIR/VaultNote-v${VERSION}-${TIMESTAMP}-${ABI}.apk"
                
                cp "$BUILD_FILE" "$OUTPUT_FILE"
                
                # Sign APK if requested
                if [[ "$SIGN_BUILD" == true ]]; then
                    print_step "Signing APK for $ABI..."
                    if [[ -f "$KEYSTORE_FILE" ]]; then
                        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                            -keystore "$KEYSTORE_FILE" \
                            -storepass "$KEYSTORE_PASSWORD" \
                            -keypass "$KEY_PASSWORD" \
                            "$OUTPUT_FILE" "$KEY_ALIAS"
                        print_success "APK signed for $ABI"
                    else
                        print_error "Keystore not found at $KEYSTORE_FILE"
                        exit 1
                    fi
                fi
                
                # Generate checksum
                sha256sum "$OUTPUT_FILE" > "$OUTPUT_FILE.sha256"
                
                print_success "APK built for $ABI"
                print_info "Output: $OUTPUT_FILE"
                print_info "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
            else
                print_error "APK build failed for $ABI - output file not found"
                exit 1
            fi
        done
        
        print_success "All split APKs built successfully"
    else
        # Standard build (single APK or AAB)
        print_step "Building Flutter $FLUTTER_BUILD_TYPE..."
        
        if [[ "$FLUTTER_BUILD_TYPE" == "appbundle" ]]; then
            flutter build appbundle $BUILD_ARGS
            BUILD_FILE="build/app/outputs/bundle/release/app-release.aab"
        else
            flutter build apk $BUILD_ARGS
            BUILD_FILE="build/app/outputs/flutter-apk/app-release.apk"
        fi
        
        if [[ -f "$BUILD_FILE" ]]; then
            # Copy to output directory
            TIMESTAMP=$(date +%Y%m%d_%H%M%S)
            VERSION=$(grep -oP 'version: \K[^\s]+' pubspec.yaml | head -1 | cut -d'+' -f1)
            
            if [[ "$FLUTTER_BUILD_TYPE" == "appbundle" ]]; then
                OUTPUT_FILE="$BUILD_OUTPUT_DIR/VaultNote-v${VERSION}-${TIMESTAMP}.aab"
            else
                OUTPUT_FILE="$BUILD_OUTPUT_DIR/VaultNote-v${VERSION}-${TIMESTAMP}.apk"
            fi
            
            cp "$BUILD_FILE" "$OUTPUT_FILE"
            
            # Sign if requested
            if [[ "$SIGN_BUILD" == true ]]; then
                print_step "Signing $FLUTTER_BUILD_TYPE..."
                if [[ -f "$KEYSTORE_FILE" ]]; then
                    if [[ "$FLUTTER_BUILD_TYPE" == "appbundle" ]]; then
                        # For AAB, we need to use jarsigner
                        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                            -keystore "$KEYSTORE_FILE" \
                            -storepass "$KEYSTORE_PASSWORD" \
                            -keypass "$KEY_PASSWORD" \
                            "$OUTPUT_FILE" "$KEY_ALIAS"
                    else
                        # For APK, we can use apksigner or jarsigner
                        jarsigner -verbose -sigalg SHA256withRSA -digestalg SHA-256 \
                            -keystore "$KEYSTORE_FILE" \
                            -storepass "$KEYSTORE_PASSWORD" \
                            -keypass "$KEY_PASSWORD" \
                            "$OUTPUT_FILE" "$KEY_ALIAS"
                    fi
                    print_success "$FLUTTER_BUILD_TYPE signed successfully"
                else
                    print_error "Keystore not found at $KEYSTORE_FILE"
                    exit 1
                fi
            fi
            
            # Generate checksum
            sha256sum "$OUTPUT_FILE" > "$OUTPUT_FILE.sha256"
            
            print_success "Flutter build completed"
            print_info "Output: $OUTPUT_FILE"
            print_info "Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
        else
            print_error "Flutter build failed - output file not found"
            exit 1
        fi
    fi
    echo ""
fi

# Build Web
if [[ "$BUILD_WEB" == true ]]; then
    print_header "Building Web App"
    cd "$WEB_DIR"
    
    # Load nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm use default > /dev/null 2>&1 || true
    fi
    
    # Clean if requested
    if [[ "$CLEAN_BUILD" == true ]]; then
        print_step "Cleaning Web build..."
        rm -rf dist/ node_modules/
        print_success "Clean completed"
    fi
    
    # Install dependencies
    if [[ ! -d "node_modules" ]]; then
        print_step "Installing web dependencies..."
        npm install
        print_success "Dependencies installed"
    fi
    
    echo ""
    
    # Build
    print_step "Building Web app for $WEB_BUILD_MODE..."
    
    if [[ "$VERBOSE" == true ]]; then
        npm run build
    else
        npm run build > /dev/null 2>&1
    fi
    
    if [[ -d "dist" ]]; then
        # Copy to output directory
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        VERSION=$(grep -oP '"version": "\K[^"]+' package.json)
        OUTPUT_DIR="$BUILD_OUTPUT_DIR/vaultnote-web-v${VERSION}-${TIMESTAMP}"
        
        cp -r dist "$OUTPUT_DIR"
        
        # Create archive
        cd "$BUILD_OUTPUT_DIR"
        tar -czf "vaultnote-web-v${VERSION}-${TIMESTAMP}.tar.gz" "vaultnote-web-v${VERSION}-${TIMESTAMP}"
        rm -rf "vaultnote-web-v${VERSION}-${TIMESTAMP}"
        
        ARCHIVE_FILE="$BUILD_OUTPUT_DIR/vaultnote-web-v${VERSION}-${TIMESTAMP}.tar.gz"
        sha256sum "$ARCHIVE_FILE" > "$ARCHIVE_FILE.sha256"
        
        print_success "Web build completed"
        print_info "Output: $ARCHIVE_FILE"
        print_info "Size: $(du -h "$ARCHIVE_FILE" | cut -f1)"
    else
        print_error "Web build failed - output directory not found"
        exit 1
    fi
    echo ""
fi

# Print summary
print_header "Build Summary"
echo ""

if [[ "$BUILD_FLUTTER" == true ]]; then
    echo -e "${CYAN}Flutter Build:${NC}"
    echo -e "  Type: $FLUTTER_BUILD_TYPE"
    echo -e "  Mode: $FLUTTER_BUILD_MODE"
    echo -e "  Signed: $SIGN_BUILD"
    echo -e "  Split APK: $SPLIT_APK"
    
    if [[ "$SPLIT_APK" == true && "$FLUTTER_BUILD_TYPE" == "apk" ]]; then
        echo -e "  ABIs: armeabi-v7a, arm64-v8a, x86_64"
        echo -e "  Output files:"
        for ABI_NAME in "${ABI_NAMES[@]}"; do
            if [[ -f "$BUILD_OUTPUT_DIR"/VaultNote-v*-*-"$ABI_NAME".apk ]]; then
                echo -e "    - $(basename "$BUILD_OUTPUT_DIR"/VaultNote-v*-*-"$ABI_NAME".apk)"
            fi
        done
    else
        if [[ -f "$OUTPUT_FILE" ]]; then
            echo -e "  Output: $(basename "$OUTPUT_FILE")"
            echo -e "  Size: $(du -h "$OUTPUT_FILE" | cut -f1)"
        fi
    fi
    echo ""
fi

if [[ "$BUILD_WEB" == true ]]; then
    echo -e "${CYAN}Web Build:${NC}"
    echo -e "  Mode: $WEB_BUILD_MODE"
    if [[ -f "$ARCHIVE_FILE" ]]; then
        echo -e "  Output: $(basename "$ARCHIVE_FILE")"
        echo -e "  Size: $(du -h "$ARCHIVE_FILE" | cut -f1)"
    fi
    echo ""
fi

print_info "All builds saved to: $BUILD_OUTPUT_DIR"
echo ""
ls -lh "$BUILD_OUTPUT_DIR"
echo ""

print_success "Auto-build completed successfully!"
echo ""
print_info "Run './auto-test.sh' to verify builds"