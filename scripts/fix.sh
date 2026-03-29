#!/bin/bash

# VaultNote Auto Fix Script
# Analyzes errors and applies fixes automatically

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
LOG_FILE="$SCRIPTS_DIR/logs/fix-$(date +%Y%m%d-%H%M%S).log"
HISTORY_FILE="$SCRIPTS_DIR/logs/fix-history.log"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

# Default values
AUTO_FIX=true
VERBOSE=false
MAX_RETRIES=3
FIX_HISTORY=()

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
VaultNote Auto Fix Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -a, --no-auto         Don't apply fixes automatically
    -v, --verbose         Verbose output
    -r, --retries NUM     Max retry attempts (default: 3)
    -h, --help            Show this help message

Examples:
    $(basename "$0")                    # Auto-fix all issues
    $(basename "$0") -a                 # Show fixes but don't apply
    $(basename "$0") -v                 # Verbose output

EOF
}

# Log fix action
log_fix() {
    local fix_type="$1"
    local description="$2"
    local timestamp=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
    
    FIX_HISTORY+=("$timestamp | $fix_type | $description")
    echo "$timestamp | $fix_type | $description" >> "$HISTORY_FILE"
}

# Analyze Flutter errors
analyze_flutter_errors() {
    print_step "Analyzing Flutter errors..."
    
    if [[ ! -d "$FLUTTER_DIR" ]]; then
        print_info "Flutter directory not found, skipping"
        return 0
    fi
    
    cd "$FLUTTER_DIR"
    
    # Check for common Flutter issues
    local issues_found=0
    
    # 1. Check for missing dependencies
    print_info "Checking Flutter dependencies..."
    if [[ ! -d ".dart_tool" ]]; then
        print_info "Missing .dart_tool directory, running flutter pub get..."
        if [[ "$AUTO_FIX" == true ]]; then
            flutter pub get
            log_fix "Flutter" "Ran flutter pub get to fix missing dependencies"
            print_success "Dependencies installed"
        else
            print_info "Would run: flutter pub get"
        fi
        ((issues_found++))
    fi
    
    # 2. Check for outdated packages
    print_info "Checking for outdated packages..."
    if flutter pub outdated > "$LOG_FILE.flutter-outdated" 2>&1; then
        if grep -q "dependencies" "$LOG_FILE.flutter-outdated"; then
            print_info "Some packages are outdated"
            if [[ "$AUTO_FIX" == true ]]; then
                print_info "Updating packages..."
                flutter pub upgrade
                log_fix "Flutter" "Updated outdated packages"
                print_success "Packages updated"
            else
                print_info "Would run: flutter pub upgrade"
            fi
            ((issues_found++))
        fi
    fi
    
    # 3. Check for Kotlin/Gradle issues
    print_info "Checking Android build configuration..."
    if [[ -f "android/app/build.gradle" ]]; then
        # Check for common Kotlin version issues
        if grep -q "kotlin_version = '1.9.0'" android/build.gradle; then
            print_info "Kotlin version may need updating"
            if [[ "$AUTO_FIX" == true ]]; then
                sed -i "s/kotlin_version = '1.9.0'/kotlin_version = '1.8.22'/g" android/build.gradle
                log_fix "Flutter" "Updated Kotlin version to 1.8.22"
                print_success "Kotlin version updated"
            else
                print_info "Would update Kotlin version to 1.8.22"
            fi
            ((issues_found++))
        fi
    fi
    
    # 4. Check for Android SDK issues
    print_info "Checking Android SDK configuration..."
    if [[ ! -f "android/local.properties" ]]; then
        print_info "Missing local.properties, creating..."
        if [[ "$AUTO_FIX" == true ]]; then
            echo "sdk.dir=$ANDROID_SDK_ROOT" > android/local.properties
            echo "flutter.sdk=$HOME/flutter" >> android/local.properties
            log_fix "Flutter" "Created local.properties for Android SDK"
            print_success "local.properties created"
        else
            print_info "Would create android/local.properties"
        fi
        ((issues_found++))
    fi
    
    # 5. Check for Gradle issues
    print_info "Checking Gradle configuration..."
    if [[ -d "android/.gradle" ]]; then
        print_info "Cleaning Gradle cache..."
        if [[ "$AUTO_FIX" == true ]]; then
            rm -rf android/.gradle
            log_fix "Flutter" "Cleaned Gradle cache"
            print_success "Gradle cache cleaned"
        else
            print_info "Would clean android/.gradle"
        fi
        ((issues_found++))
    fi
    
    # 6. Check for Flutter clean needed
    print_info "Checking if Flutter clean is needed..."
    if [[ -d "build" ]]; then
        print_info "Build directory exists, may need cleaning"
        if [[ "$AUTO_FIX" == true ]]; then
            flutter clean
            flutter pub get
            log_fix "Flutter" "Ran flutter clean and pub get"
            print_success "Flutter cleaned"
        else
            print_info "Would run: flutter clean && flutter pub get"
        fi
        ((issues_found++))
    fi
    
    return $issues_found
}

# Analyze Web errors
analyze_web_errors() {
    print_step "Analyzing Web errors..."
    
    if [[ ! -d "$WEB_DIR" ]]; then
        print_info "Web directory not found, skipping"
        return 0
    fi
    
    cd "$WEB_DIR"
    
    # Check for common Web/Node issues
    local issues_found=0
    
    # 1. Check for missing node_modules
    print_info "Checking Node.js dependencies..."
    if [[ ! -d "node_modules" ]]; then
        print_info "Missing node_modules, running npm install..."
        if [[ "$AUTO_FIX" == true ]]; then
            npm install
            log_fix "Web" "Installed missing node_modules"
            print_success "Dependencies installed"
        else
            print_info "Would run: npm install"
        fi
        ((issues_found++))
    fi
    
    # 2. Check for package-lock.json issues
    print_info "Checking package-lock.json..."
    if [[ -f "package.json" && ! -f "package-lock.json" ]]; then
        print_info "Missing package-lock.json, running npm install..."
        if [[ "$AUTO_FIX" == true ]]; then
            npm install
            log_fix "Web" "Generated package-lock.json"
            print_success "package-lock.json generated"
        else
            print_info "Would run: npm install"
        fi
        ((issues_found++))
    fi
    
    # 3. Check for outdated packages
    print_info "Checking for outdated packages..."
    if npm outdated > "$LOG_FILE.web-outdated" 2>&1; then
        if [[ -s "$LOG_FILE.web-outdated" ]]; then
            print_info "Some packages are outdated"
            if [[ "$AUTO_FIX" == true ]]; then
                print_info "Updating packages..."
                npm update
                log_fix "Web" "Updated outdated packages"
                print_success "Packages updated"
            else
                print_info "Would run: npm update"
            fi
            ((issues_found++))
        fi
    fi
    
    # 4. Check for build issues
    print_info "Checking build configuration..."
    if [[ -d "dist" ]]; then
        print_info "Build directory exists, may need cleaning"
        if [[ "$AUTO_FIX" == true ]]; then
            rm -rf dist
            log_fix "Web" "Cleaned build directory"
            print_success "Build directory cleaned"
        else
            print_info "Would clean dist directory"
        fi
        ((issues_found++))
    fi
    
    # 5. Check for TypeScript issues
    print_info "Checking TypeScript configuration..."
    if [[ -f "tsconfig.json" ]]; then
        if npx tsc --noEmit > "$LOG_FILE.typescript" 2>&1; then
            print_success "TypeScript check passed"
        else
            print_error "TypeScript errors found"
            if [[ "$AUTO_FIX" == true ]]; then
                print_info "Attempting to fix TypeScript errors..."
                # This is a basic fix, more sophisticated fixes would need more logic
                npx prettier --write "src/**/*.{ts,tsx}" > /dev/null 2>&1 || true
                log_fix "Web" "Applied TypeScript formatting fixes"
                print_success "TypeScript formatting applied"
            else
                print_info "Would apply TypeScript fixes"
            fi
            ((issues_found++))
        fi
    fi
    
    return $issues_found
}

# Fix common project issues
fix_common_issues() {
    print_step "Fixing common project issues..."
    
    local issues_found=0
    
    # 1. Check for Git issues
    print_info "Checking Git status..."
    if [[ -d "$PROJECT_DIR/.git" ]]; then
        cd "$PROJECT_DIR"
        
        # Check for uncommitted changes
        if [[ -n $(git status --porcelain) ]]; then
            print_info "Uncommitted changes found"
            if [[ "$AUTO_FIX" == true ]]; then
                git add .
                git commit -m "Auto-fix: $(date -u +"%Y-%m-%d %H:%M:%S UTC")" > /dev/null 2>&1 || true
                log_fix "Git" "Committed uncommitted changes"
                print_success "Changes committed"
            else
                print_info "Would commit changes"
            fi
            ((issues_found++))
        fi
        
        # Check for missing .gitignore
        if [[ ! -f ".gitignore" ]]; then
            print_info "Missing .gitignore, creating..."
            if [[ "$AUTO_FIX" == true ]]; then
                cat > .gitignore << 'EOF'
# Dependencies
node_modules/
.pnpm-store/
.pnpm-debug.log

# Build outputs
build/
dist/
.dart_tool/
.packages

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
logs/
*.log

# Environment
.env
.env.local
.env.*.local

# Android
android/.gradle/
android/local.properties
android/app/debug/
android/app/profile/
android/app/release/

# iOS
ios/Pods/
ios/.symlinks/

# Flutter
.flutter-plugins-dependencies

# Keystore
*.jks
*.keystore
EOF
                log_fix "Git" "Created .gitignore"
                print_success ".gitignore created"
            else
                print_info "Would create .gitignore"
            fi
            ((issues_found++))
        fi
    fi
    
    # 2. Check for missing README
    print_info "Checking documentation..."
    if [[ ! -f "$PROJECT_DIR/README.md" ]]; then
        print_info "Missing README.md, creating..."
        if [[ "$AUTO_FIX" == true ]]; then
            cat > "$PROJECT_DIR/README.md" << 'EOF'
# VaultNote

A secure note-taking application built with Flutter and Web technologies.

## Features

- Encrypted note storage
- Biometric authentication
- Cross-platform support (Android, iOS, Web)
- Markdown support
- Cloud sync

## Getting Started

### Prerequisites

- Flutter SDK
- Node.js (for web development)
- Android Studio (for Android development)
- Xcode (for iOS development)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd vaultnote
```

2. Run setup:
```bash
./scripts/setup.sh
```

3. Run the application:
```bash
./scripts/run.sh
```

## Development

### Scripts

- `./scripts/setup.sh` - Install dependencies and configure environment
- `./scripts/run.sh` - Run the application
- `./scripts/test.sh` - Run tests
- `./scripts/build.sh` - Build for production
- `./scripts/fix.sh` - Auto-fix common issues

### Testing

```bash
./scripts/test.sh
```

### Building

```bash
./scripts/build.sh -f -s -p  # Build signed split APKs
./scripts/build.sh -w        # Build web app
```

## Project Structure

```
vaultnote/
├── flutter/          # Flutter application
├── web/              # Web application
├── scripts/          # Automation scripts
├── build-output/     # Build outputs
└── keystore/         # Signing keys
```

## License

Private - All rights reserved
EOF
                log_fix "Documentation" "Created README.md"
                print_success "README.md created"
            else
                print_info "Would create README.md"
            fi
            ((issues_found++))
        fi
    fi
    
    return $issues_found
}

# Main function
main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -a|--no-auto)
                AUTO_FIX=false
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -r|--retries)
                MAX_RETRIES="$2"
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
    
    print_header "VaultNote Auto Fix"
    echo ""
    
    log "Starting fix process..."
    
    # Print fix configuration
    print_info "Fix Configuration:"
    echo -e "  Auto Fix: ${GREEN}$AUTO_FIX${NC}"
    echo -e "  Verbose: ${GREEN}$VERBOSE${NC}"
    echo -e "  Max Retries: ${GREEN}$MAX_RETRIES${NC}"
    echo ""
    
    # Analyze and fix issues
    local total_issues=0
    local retry_count=0
    
    while [[ $retry_count -lt $MAX_RETRIES ]]; do
        print_info "Analysis attempt $((retry_count + 1))/$MAX_RETRIES"
        
        # Analyze Flutter
        if analyze_flutter_errors; then
            local flutter_issues=$?
            ((total_issues += flutter_issues))
        fi
        echo ""
        
        # Analyze Web
        if analyze_web_errors; then
            local web_issues=$?
            ((total_issues += web_issues))
        fi
        echo ""
        
        # Fix common issues
        if fix_common_issues; then
            local common_issues=$?
            ((total_issues += common_issues))
        fi
        echo ""
        
        # If no issues found, break
        if [[ $total_issues -eq 0 ]]; then
            print_success "No issues found"
            break
        fi
        
        # If auto-fix is disabled, break
        if [[ "$AUTO_FIX" == false ]]; then
            print_info "Auto-fix disabled, showing issues only"
            break
        fi
        
        # Increment retry count
        ((retry_count++))
        
        # Wait before retry
        if [[ $retry_count -lt $MAX_RETRIES ]]; then
            print_info "Waiting 2 seconds before retry..."
            sleep 2
            total_issues=0
        fi
    done
    
    # Print summary
    print_header "Fix Summary"
    echo ""
    
    if [[ ${#FIX_HISTORY[@]} -eq 0 ]]; then
        print_success "No fixes were applied"
    else
        print_info "Applied fixes:"
        for fix in "${FIX_HISTORY[@]}"; do
            echo -e "  ${CYAN}•${NC} $fix"
        done
    fi
    
    echo ""
    print_info "Fix history logged to: $HISTORY_FILE"
    
    if [[ $total_issues -gt 0 ]]; then
        print_info "Some issues may require manual intervention"
    fi
    
    log "Fix process completed"
}

# Run main function
main "$@"
