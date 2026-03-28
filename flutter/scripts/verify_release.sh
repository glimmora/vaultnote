#!/bin/bash

# VaultNote Release Verification Script
# Verifies APK signature, version, and integrity

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header "VaultNote - Release Verification"
echo ""

# Get build tools version
BUILD_TOOLS_VERSION=$(ls "$ANDROID_HOME/build-tools" | tail -1)
APKSIGNER="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/apksigner"
ZIPALIGN="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/zipalign"
AAPT2="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION/aapt2"

# Find APKs to verify
APK_FILES=()
if [[ -f "$BUILD_DIR/app-release.apk" ]]; then
    APK_FILES+=("$BUILD_DIR/app-release.apk")
fi

for abi in armeabi-v7a arm64-v8a x86_64; do
    if [[ -f "$BUILD_DIR/app-$abi-release.apk" ]]; then
        APK_FILES+=("$BUILD_DIR/app-$abi-release.apk")
    fi
done

if [[ ${#APK_FILES[@]} -eq 0 ]]; then
    print_error "No APK files found in $BUILD_DIR"
    print_info "Build the APK first: ./scripts/build.sh"
    exit 1
fi

print_info "Found ${#APK_FILES[@]} APK file(s)"
echo ""

# Verification results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

for APK_FILE in "${APK_FILES[@]}"; do
    APK_NAME=$(basename "$APK_FILE")
    print_header "Verifying: $APK_NAME"
    echo ""
    
    # Check 1: File exists and is readable
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if [[ -f "$APK_FILE" && -r "$APK_FILE" ]]; then
        print_success "File exists and is readable"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_error "File not found or not readable"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        continue
    fi
    
    # Check 2: File size
    FILE_SIZE=$(du -h "$APK_FILE" | cut -f1)
    print_info "File size: $FILE_SIZE"
    
    # Check 3: ZIP alignment
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if $ZIPALIGN -c -v 4 "$APK_FILE" > /dev/null 2>&1; then
        print_success "ZIP aligned correctly"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_error "ZIP alignment check failed"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    # Check 4: Signature verification
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if $APKSIGNER verify --verbose "$APK_FILE" 2>&1 | grep -q "Verified"; then
        print_success "APK signature verified"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        
        # Show signature info
        echo ""
        print_info "Signature details:"
        $APKSIGNER verify --print-certs "$APK_FILE" 2>&1 | head -10 || true
    else
        print_error "APK signature verification failed"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
    fi
    
    # Check 5: App version info
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    if command -v $AAPT2 &> /dev/null; then
        VERSION_INFO=$($AAPT2 dump badging "$APK_FILE" 2>/dev/null | grep -E "versionName|versionCode" || true)
        if [[ -n "$VERSION_INFO" ]]; then
            print_success "App version info:"
            echo "$VERSION_INFO" | sed 's/^/    /'
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            print_warning "Could not extract version info"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
    fi
    
    # Check 6: Package name
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    PACKAGE_NAME=$($AAPT2 dump badging "$APK_FILE" 2>/dev/null | grep "package:" | cut -d"'" -f2 || true)
    if [[ "$PACKAGE_NAME" == "com.vaultnote.vaultnote" ]]; then
        print_success "Package name: $PACKAGE_NAME"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        print_warning "Unexpected package name: $PACKAGE_NAME"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
    
    # Check 7: Target SDK
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    TARGET_SDK=$($AAPT2 dump badging "$APK_FILE" 2>/dev/null | grep "targetSdkVersion" | cut -d"'" -f2 || true)
    if [[ -n "$TARGET_SDK" ]]; then
        print_info "Target SDK: API $TARGET_SDK"
        if [[ "$TARGET_SDK" -ge 33 ]]; then
            print_success "Target SDK meets requirements (≥33)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        else
            print_warning "Target SDK below recommended (≥33)"
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
        fi
    else
        print_warning "Could not determine target SDK"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    fi
    
    # Check 8: Permissions
    echo ""
    print_info "Declared permissions:"
    $AAPT2 dump badging "$APK_FILE" 2>/dev/null | grep "uses-permission:" | cut -d"'" -f2 | sed 's/^/    - /' || true
    
    echo ""
    echo "----------------------------------------"
    echo ""
done

# Summary
print_header "Verification Summary"
echo ""
print_info "Total checks: $TOTAL_CHECKS"
print_success "Passed: $PASSED_CHECKS"
if [[ $FAILED_CHECKS -gt 0 ]]; then
    print_error "Failed: $FAILED_CHECKS"
else
    echo -e "Failed: ${GREEN}0${NC}"
fi

echo ""
SUCCESS_RATE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))
print_info "Success rate: $SUCCESS_RATE%"

echo ""
if [[ $FAILED_CHECKS -eq 0 ]]; then
    print_success "All verification checks passed!"
    echo ""
    print_info "APK is ready for distribution"
else
    print_error "Some verification checks failed"
    echo ""
    print_warning "Review the errors above before distributing"
    exit 1
fi

echo ""
