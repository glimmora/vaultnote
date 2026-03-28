#!/bin/bash

# VaultNote Install Script
# Installs the built APK on a connected device

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/app/outputs/flutter-apk"

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

# Default values
APK_TYPE="release"
UNINSTALL_FIRST=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--debug)
            APK_TYPE="debug"
            shift
            ;;
        -u|--uninstall)
            UNINSTALL_FIRST=true
            shift
            ;;
        -h|--help)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -d, --debug       Install debug APK"
            echo "  -u, --uninstall   Uninstall app before installing"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_header "VaultNote - Install APK"
echo ""

# Check for connected devices
DEVICE_COUNT=$(adb devices | grep -v "List" | grep "device$" | wc -l)

if [[ $DEVICE_COUNT -eq 0 ]]; then
    print_error "No devices connected"
    print_info "Connect a device or start an emulator"
    exit 1
fi

print_info "Devices connected: $DEVICE_COUNT"
echo ""

# Determine APK file
if [[ "$APK_TYPE" == "debug" ]]; then
    APK_FILE="$BUILD_DIR/app-debug.apk"
else
    APK_FILE="$BUILD_DIR/app-release.apk"
fi

# Check if APK exists
if [[ ! -f "$APK_FILE" ]]; then
    print_error "APK not found: $APK_FILE"
    print_info "Build the APK first: ./scripts/build.sh"
    exit 1
fi

# Uninstall if requested
if [[ "$UNINSTALL_FIRST" == true ]]; then
    print_info "Uninstalling existing app..."
    adb uninstall com.vaultnote.vaultnote || true
    print_success "Uninstalled"
    echo ""
fi

# Install APK
print_info "Installing: $(basename "$APK_FILE")"
print_info "Size: $(du -h "$APK_FILE" | cut -f1)"
echo ""

adb install -r -d "$APK_FILE"

echo ""
print_success "Installation completed!"
echo ""
print_info "To launch: adb shell am start -n com.vaultnote.vaultnote/.MainActivity"
echo ""
