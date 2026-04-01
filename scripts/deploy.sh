#!/bin/bash

# VaultNote Deployment Script
# Deploys built artifacts to various platforms

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"
DIST_DIR="$PROJECT_DIR/dist"

print_header() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_step() {
    echo -e "${CYAN}▶ $1${NC}"
}

show_help() {
    cat << 'EOF'
VaultNote Deployment Script

Usage: ./scripts/deploy.sh [OPTIONS] [TARGET]

Targets:
    android-apk       Deploy to physical Android device via ADB
    android-play      Instructions for Google Play Store upload
    web-local         Deploy to local web server
    web-s3            Deploy to AWS S3 bucket
    web-firebase      Deploy to Firebase Hosting
    all               Deploy all targets (interactive)

Options:
    -e, --env ENV     Environment: dev, staging, prod (default: dev)
    -s, --skip-tests  Skip verification tests
    -v, --verbose     Verbose output
    -h, --help        Show this help

Examples:
    ./scripts/deploy.sh android-apk
    ./scripts/deploy.sh web-local -e dev
    ./scripts/deploy.sh android-play
    ./scripts/deploy.sh web-s3 -e prod

EOF
}

# Parse arguments
TARGET="${1:-all}"
ENV="dev"
SKIP_TESTS=false
VERBOSE=false

while [[ $# -gt 1 ]]; do
    case $2 in
        -e|--env)
            ENV="$3"
            shift 2
            ;;
        -s|--skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

print_header "VaultNote Deployment"

# Verify builds exist
if [[ ! -d "$DIST_DIR" ]]; then
    echo "Error: Distribution directory not found at $DIST_DIR"
    echo "Run './scripts/build-all.sh' first to build artifacts"
    exit 1
fi

# Deploy APK via ADB
deploy_android_apk() {
    print_header "Deploying Android APK"
    
    if ! command -v adb &> /dev/null; then
        echo "Error: adb not found. Install Android SDK platform-tools."
        exit 1
    fi
    
    print_step "Checking for connected devices..."
    local devices=$(adb devices | grep -E "^\w+\s+device$" | wc -l)
    
    if [[ $devices -eq 0 ]]; then
        echo "Error: No connected Android devices found"
        exit 1
    fi
    
    print_info "Found $devices connected device(s)"
    
    local apks=("$DIST_DIR/android/apk/"*.apk)
    
    if [[ -z "${apks[0]}" ]]; then
        echo "Error: No APK files found in $DIST_DIR/android/apk/"
        exit 1
    fi
    
    print_step "Installing APKs..."
    adb install-multiple "${apks[@]}"
    
    print_success "APK installed successfully!"
    print_info "App info:"
    adb shell dumpsys package com.vaultnote.app | grep -E "(versionName|versionCode)" || true
}

# Deploy to Google Play
deploy_android_play() {
    print_header "Google Play Store Deployment"
    
    local aab_file="$DIST_DIR/android/aab/app-release.aab"
    
    if [[ ! -f "$aab_file" ]]; then
        echo "Error: App Bundle not found at $aab_file"
        exit 1
    fi
    
    echo "Steps to deploy to Google Play:"
    echo ""
    echo "1. Open Google Play Console (https://play.google.com/console)"
    echo "2. Go to your app → Internal testing → Releases"
    echo "3. Create new release"
    echo "4. Upload AAB file:"
    echo "   File: $aab_file"
    echo "   Size: $(du -h "$aab_file" | cut -f1)"
    echo "   SHA256: $(sha256sum "$aab_file" | cut -d' ' -f1)"
    echo ""
    echo "5. Or use bundletool to test locally:"
    echo "   bundletool build-apks --bundle=$aab_file --output=app.apks"
    echo "   bundletool install-apks --apks=app.apks"
    echo ""
    echo "6. Fill in version info, privacy policy, etc."
    echo "7. Submit for review"
}

# Deploy to local web server
deploy_web_local() {
    print_header "Local Web Deployment"
    
    local web_dir="/var/www/vaultnote"
    local backup_dir="/var/www/vaultnote.backup.$(date +%Y%m%d_%H%M%S)"
    
    if [[ ! -d "$DIST_DIR/web" ]]; then
        echo "Error: Web build not found at $DIST_DIR/web"
        exit 1
    fi
    
    print_step "Checking permissions..."
    if [[ ! -w "/var/www" ]]; then
        echo "Error: No write permissions to /var/www"
        echo "Run with sudo or use appropriate user"
        exit 1
    fi
    
    if [[ -d "$web_dir" ]]; then
        print_step "Backing up current deployment..."
        sudo cp -r "$web_dir" "$backup_dir"
        print_success "Backup created: $backup_dir"
    fi
    
    print_step "Deploying web application..."
    sudo mkdir -p "$web_dir"
    sudo cp -r "$DIST_DIR/web"/* "$web_dir/"
    
    print_success "Web deployment completed!"
    print_info "Access at: http://localhost/vaultnote"
    print_info "Or: http://$(hostname -I | cut -d' ' -f1)/vaultnote"
}

# Deploy to AWS S3
deploy_web_s3() {
    print_header "AWS S3 Web Deployment"
    
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI not found. Install with: pip install awscli"
        exit 1
    fi
    
    local s3_bucket="s3://vaultnote-${ENV}"
    local region="us-east-1"
    
    print_step "Configuring S3 bucket: $s3_bucket"
    
    print_step "Uploading files..."
    aws s3 sync "$DIST_DIR/web/" "$s3_bucket/" \
        --region "$region" \
        --delete \
        --exclude ".git*" \
        --cache-control "public, max-age=3600" \
        --metadata "deployment-date=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    print_success "S3 deployment completed!"
    print_info "Access at: https://$(aws s3api get-bucket-website --bucket vaultnote-${ENV} --region $region 2>/dev/null | grep -oP '"Endpoint": "\K[^"]+' || echo 's3-website URL')"
    
    print_step "Invalidating CloudFront cache..."
    aws cloudfront list-distributions --region "$region" | grep "DomainName" | head -1 || print_info "CloudFront not configured"
}

# Deploy to Firebase Hosting
deploy_web_firebase() {
    print_header "Firebase Hosting Deployment"
    
    if ! command -v firebase &> /dev/null; then
        echo "Error: Firebase CLI not found"
        echo "Install with: npm install -g firebase-tools"
        exit 1
    fi
    
    if [[ ! -f "$PROJECT_DIR/firebase.json" ]]; then
        echo "Error: firebase.json not found in project root"
        echo "Run: firebase init hosting"
        exit 1
    fi
    
    print_step "Deploying to Firebase Hosting..."
    firebase deploy --only hosting -P "vaultnote-${ENV}" --cwd="$PROJECT_DIR"
    
    print_success "Firebase deployment completed!"
}

# Main deployment logic
case "$TARGET" in
    android-apk)
        deploy_android_apk
        ;;
    android-play)
        deploy_android_play
        ;;
    web-local)
        deploy_web_local
        ;;
    web-s3)
        deploy_web_s3
        ;;
    web-firebase)
        deploy_web_firebase
        ;;
    all)
        echo "Select deployment target:"
        echo "1) Android APK (ADB)"
        echo "2) Google Play Store"
        echo "3) Local Web Server"
        echo "4) AWS S3"
        echo "5) Firebase Hosting"
        read -p "Enter choice [1-5]: " choice
        case $choice in
            1) deploy_android_apk ;;
            2) deploy_android_play ;;
            3) deploy_web_local ;;
            4) deploy_web_s3 ;;
            5) deploy_web_firebase ;;
            *) echo "Invalid choice"; exit 1 ;;
        esac
        ;;
    -h|--help)
        show_help
        ;;
    *)
        echo "Unknown target: $TARGET"
        show_help
        exit 1
        ;;
esac

print_success "Deployment completed!"
