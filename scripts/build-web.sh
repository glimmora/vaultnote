#!/bin/bash

# VaultNote Web Build Script
# Builds web application for production deployment

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
WEB_DIR="$PROJECT_DIR/web"
BUILD_OUTPUT_DIR="$PROJECT_DIR/build-output"
LOG_FILE="$SCRIPTS_DIR/logs/build-web-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

# Default values
BUILD_MODE="production"
VERBOSE=false
CLEAN_BUILD=false
MINIFY=true
SOURCE_MAPS=false

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
VaultNote Web Build Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -m, --mode MODE           Build mode: production, development (default: production)
    -c, --clean               Clean build before building
    -v, --verbose             Verbose output
    -s, --source-maps         Include source maps
    -n, --no-minify           Don't minify output
    -o, --output DIR          Output directory (default: build-output)
    -h, --help                Show this help message

Examples:
    $(basename "$0")                          # Build for production
    $(basename "$0") -m development           # Build for development
    $(basename "$0") -c -v                    # Clean build with verbose output
    $(basename "$0") -s                       # Build with source maps

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            BUILD_MODE="$2"
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
        -s|--source-maps)
            SOURCE_MAPS=true
            shift
            ;;
        -n|--no-minify)
            MINIFY=false
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

print_header "VaultNote Web Build"
echo ""

log "Starting web build process..."

# Print build configuration
print_info "Build Configuration:"
echo -e "  Build Mode: ${GREEN}$BUILD_MODE${NC}"
echo -e "  Clean Build: ${GREEN}$CLEAN_BUILD${NC}"
echo -e "  Minify: ${GREEN}$MINIFY${NC}"
echo -e "  Source Maps: ${GREEN}$SOURCE_MAPS${NC}"
echo -e "  Output Dir: ${GREEN}$BUILD_OUTPUT_DIR${NC}"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

if ! command -v node &> /dev/null; then
    print_error "Node.js not found. Run ./scripts/setup.sh first"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    print_error "npm not found. Run ./scripts/setup.sh first"
    exit 1
fi

if [[ ! -d "$WEB_DIR" ]]; then
    print_error "Web directory not found"
    exit 1
fi

print_success "Prerequisites check passed"
echo ""

# Create output directory
mkdir -p "$BUILD_OUTPUT_DIR"

# Navigate to web directory
cd "$WEB_DIR"

# Load nvm if available
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    source "$HOME/.nvm/nvm.sh"
    nvm use default > /dev/null 2>&1 || true
fi

# Clean if requested
if [[ "$CLEAN_BUILD" == true ]]; then
    print_step "Cleaning web build..."
    rm -rf dist/ node_modules/
    print_success "Clean completed"
fi

# Install dependencies
print_step "Installing dependencies..."
if [[ ! -d "node_modules" ]]; then
    npm install
    print_success "Dependencies installed"
else
    print_success "Dependencies already installed"
fi

echo ""

# Set environment variables
export NODE_ENV="$BUILD_MODE"

# Build arguments
BUILD_ARGS=""

if [[ "$VERBOSE" == true ]]; then
    BUILD_ARGS="$BUILD_ARGS --verbose"
fi

# Build based on available scripts
print_step "Building web application..."

if [[ -f "package.json" ]]; then
    # Check for available build scripts
    if grep -q "\"build\"" package.json; then
        print_info "Running npm build..."
        npm run build $BUILD_ARGS
    elif grep -q "\"build:prod\"" package.json; then
        print_info "Running npm build:prod..."
        npm run build:prod $BUILD_ARGS
    elif grep -q "\"build:production\"" package.json; then
        print_info "Running npm build:production..."
        npm run build:production $BUILD_ARGS
    else
        print_error "No build script found in package.json"
        exit 1
    fi
else
    print_error "package.json not found"
    exit 1
fi

echo ""

# Check if build was successful
if [[ -d "dist" ]]; then
    print_success "Web build completed"
    
    # Generate build info
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local version=$(grep -oP '"version": "\K[^"]+' package.json)
    local build_info_file="$BUILD_OUTPUT_DIR/build-info-web-${timestamp}.json"
    
    cat > "$build_info_file" << EOF
{
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "version": "$version",
    "buildMode": "$BUILD_MODE",
    "minify": $MINIFY,
    "sourceMaps": $SOURCE_MAPS,
    "buildDir": "dist"
}
EOF
    
    # Copy to output directory
    local output_dir="$BUILD_OUTPUT_DIR/vaultnote-web-v${version}-${timestamp}"
    cp -r dist "$output_dir"
    
    # Create archive
    cd "$BUILD_OUTPUT_DIR"
    tar -czf "vaultnote-web-v${version}-${timestamp}.tar.gz" "vaultnote-web-v${version}-${timestamp}"
    rm -rf "vaultnote-web-v${version}-${timestamp}"
    
    local archive_file="$BUILD_OUTPUT_DIR/vaultnote-web-v${version}-${timestamp}.tar.gz"
    sha256sum "$archive_file" > "$archive_file.sha256"
    
    print_info "Build info saved to: $build_info_file"
    print_info "Archive created: $archive_file"
    print_info "Size: $(du -h "$archive_file" | cut -f1)"
    
else
    print_error "Web build failed - dist directory not found"
    exit 1
fi

echo ""

# Print summary
print_header "Build Summary"
echo ""

echo -e "${CYAN}Web Build:${NC}"
echo -e "  Type: Web Application"
echo -e "  Mode: $BUILD_MODE"
echo -e "  Minify: $MINIFY"
echo -e "  Source Maps: $SOURCE_MAPS"

local archive_file=$(find "$BUILD_OUTPUT_DIR" -name "vaultnote-web-*.tar.gz" -type f | head -1)
if [[ -f "$archive_file" ]]; then
    echo -e "  Output: $(basename "$archive_file")"
    echo -e "  Size: $(du -h "$archive_file" | cut -f1)"
fi

echo ""
print_info "All builds saved to: $BUILD_OUTPUT_DIR"
echo ""
ls -lh "$BUILD_OUTPUT_DIR"
echo ""

print_success "Web build completed successfully!"
echo ""
print_info "To deploy, extract the archive and serve the dist directory"
print_info "Run './scripts/test.sh' to verify build"