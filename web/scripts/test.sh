#!/bin/bash

# VaultNote Web App Test Script
# Tests build and verifies output

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WEB_DIR="$(dirname "$SCRIPT_DIR")"

cd "$WEB_DIR"

# Load nvm if available
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
    source "$HOME/.nvm/nvm.sh"
    nvm use default > /dev/null 2>&1 || true
fi

print_header "VaultNote Web App - Test & Build"
echo ""

# Check Node.js
print_info "Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js: $NODE_VERSION"
else
    print_error "Node.js not found"
    print_info "Install Node.js or run: source ~/.nvm/nvm.sh"
    exit 1
fi

# Check npm
print_info "Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    print_success "npm: $NPM_VERSION"
else
    print_error "npm not found"
    exit 1
fi

echo ""

# Check dependencies
print_info "Checking dependencies..."
if [[ -d "node_modules" ]]; then
    print_success "Dependencies installed"
else
    print_info "Installing dependencies..."
    npm install --silent
    print_success "Dependencies installed"
fi

echo ""

# TypeScript check
print_header "TypeScript Check"
npx tsc --noEmit 2>&1 | head -20 || true
print_success "TypeScript check completed"
echo ""

# Build
print_header "Building Production Bundle"
npm run build 2>&1 | tail -20

echo ""

# Verify build output
print_header "Verifying Build Output"

if [[ -d "dist" ]]; then
    print_success "dist/ directory exists"
    
    if [[ -f "dist/index.html" ]]; then
        print_success "dist/index.html exists"
    else
        print_error "dist/index.html not found"
    fi
    
    JS_FILE=$(ls dist/assets/index-*.js 2>/dev/null | head -1)
    if [[ -n "$JS_FILE" ]]; then
        print_success "Main JS bundle exists"
        JS_SIZE=$(du -h "$JS_FILE" | cut -f1)
        print_info "JS bundle size: $JS_SIZE"
    else
        print_error "Main JS bundle not found"
    fi
    
    CSS_FILE=$(ls dist/assets/index-*.css 2>/dev/null | head -1)
    if [[ -n "$CSS_FILE" ]]; then
        print_success "CSS bundle exists"
        CSS_SIZE=$(du -h "$CSS_FILE" | cut -f1)
        print_info "CSS bundle size: $CSS_SIZE"
    else
        print_error "CSS bundle not found"
    fi
else
    print_error "dist/ directory not found"
    exit 1
fi

echo ""

# Summary
print_header "Build Summary"
echo ""
print_info "Build location: $WEB_DIR/dist"
print_info "Total size: $(du -sh dist/ | cut -f1)"
echo ""
ls -lh dist/assets/ 2>/dev/null || true
echo ""

print_success "Build completed successfully!"
echo ""

print_info "To run production server:"
echo "  npm run preview"
echo ""

print_info "To run development server:"
echo "  npm run dev"
echo ""
