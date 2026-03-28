#!/bin/bash

# VaultNote Setup Test Script
# Verifies that the environment is configured correctly

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

print_header "VaultNote Setup Verification"
echo ""

# Check environment file
if [[ -f "$HOME/.vaultnote_env" ]]; then
    print_success "Environment file exists: ~/.vaultnote_env"
else
    print_error "Environment file not found"
    print_info "Run: ./scripts/setup_env.sh"
    exit 1
fi

# Check aliases file
if [[ -f "$HOME/.vaultnote_aliases" ]]; then
    print_success "Aliases file exists: ~/.vaultnote_aliases"
else
    print_error "Aliases file not found"
    exit 1
fi

echo ""

# Source environment
source "$HOME/.vaultnote_env" 2>/dev/null || true
source "$HOME/.vaultnote_aliases" 2>/dev/null || true

# Check Flutter
print_info "Checking Flutter..."
if command -v flutter &> /dev/null; then
    FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
    print_success "Flutter: $FLUTTER_VERSION"
else
    print_error "Flutter not found"
    print_info "Run: ./scripts/setup.sh --flutter-only"
fi

# Check Android SDK
print_info "Checking Android SDK..."
if [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]]; then
    print_success "Android SDK: $ANDROID_HOME"
    if [[ -f "$ANDROID_HOME/platform-tools/adb" ]]; then
        ADB_VERSION=$(adb --version 2>&1 | head -1)
        print_success "ADB: $ADB_VERSION"
    fi
else
    print_info "Android SDK not configured"
    print_info "Run: ./scripts/setup.sh --sdk-only"
fi

# Check Java
print_info "Checking Java..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | head -1)
    print_success "Java: $JAVA_VERSION"
else
    print_info "Java not found"
fi

echo ""

# Check project structure
print_info "Checking project structure..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

if [[ -f "$PROJECT_DIR/pubspec.yaml" ]]; then
    print_success "Flutter project found: $PROJECT_DIR"
else
    print_error "Flutter project not found"
    exit 1
fi

# Check scripts
echo ""
print_info "Checking build scripts..."
SCRIPTS=(
    "build.sh"
    "build_all.sh"
    "build_debug.sh"
    "create_keystore.sh"
    "install.sh"
    "verify_release.sh"
    "setup.sh"
    "setup_env.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [[ -x "$SCRIPT_DIR/$script" ]]; then
        print_success "  $script"
    else
        print_error "  $script (not executable)"
    fi
done

echo ""

# Summary
print_header "Summary"
echo ""

ISSUES=0

if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed"
    ISSUES=$((ISSUES + 1))
fi

if [[ -z "$ANDROID_HOME" ]] || [[ ! -d "$ANDROID_HOME" ]]; then
    print_info "Android SDK not installed (optional for development)"
fi

if [[ $ISSUES -eq 0 ]]; then
    print_success "All checks passed!"
    echo ""
    print_info "You can now use the following commands:"
    echo ""
    echo "  source ~/.bashrc     # Reload shell configuration"
    echo "  vn                   # Navigate to project"
    echo "  vn-debug             # Build debug APK"
    echo "  vn-build             # Build release APK"
    echo ""
else
    print_error "Some issues found. Please review the output above."
    echo ""
    print_info "To fix issues, run:"
    echo "  ./scripts/setup.sh   # Full setup"
    echo ""
fi

echo ""
