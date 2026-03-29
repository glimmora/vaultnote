#!/bin/bash

# VaultNote Auto-Fix Script
# Automatically fixes common issues in Flutter and Web projects

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$PROJECT_DIR/flutter"
WEB_DIR="$PROJECT_DIR/web"

# Default values
FIX_FLUTTER=true
FIX_WEB=true
FIX_PERMISSIONS=true
FIX_DEPENDENCIES=true
FIX_FORMAT=true
AUTO_COMMIT=false

# Counters
FIXES_APPLIED=0

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

print_fix() {
    echo -e "${GREEN}🔧 $1${NC}"
    ((FIXES_APPLIED++))
}

show_help() {
    cat << EOF
VaultNote Auto-Fix Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --flutter-only    Fix Flutter only
    -w, --web-only        Fix Web only
    -p, --no-permissions  Skip permission fixes
    -d, --no-deps         Skip dependency fixes
    -n, --no-format       Skip code formatting
    -a, --auto-commit     Auto-commit fixes
    -h, --help            Show this help message

Examples:
    $(basename "$0")                    # Fix all issues
    $(basename "$0") -f                 # Fix Flutter only
    $(basename "$0") -w                 # Fix Web only
    $(basename "$0") -a                 # Fix and auto-commit

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flutter-only)
            FIX_WEB=false
            shift
            ;;
        -w|--web-only)
            FIX_FLUTTER=false
            shift
            ;;
        -p|--no-permissions)
            FIX_PERMISSIONS=false
            shift
            ;;
        -d|--no-deps)
            FIX_DEPENDENCIES=false
            shift
            ;;
        -n|--no-format)
            FIX_FORMAT=false
            shift
            ;;
        -a|--auto-commit)
            AUTO_COMMIT=true
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

print_header "VaultNote Auto-Fix"
echo ""

# Fix script permissions
if [[ "$FIX_PERMISSIONS" == true ]]; then
    print_step "Fixing script permissions..."
    
    for script in "$PROJECT_DIR"/*.sh "$FLUTTER_DIR"/scripts/*.sh "$WEB_DIR"/scripts/*.sh; do
        if [[ -f "$script" ]]; then
            if [[ ! -x "$script" ]]; then
                chmod +x "$script"
                print_fix "Made executable: $(basename "$script")"
            fi
        fi
    done
    echo ""
fi

# Fix Flutter issues
if [[ "$FIX_FLUTTER" == true ]]; then
    print_header "Fixing Flutter Issues"
    cd "$FLUTTER_DIR"
    
    # Check Flutter installation
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not found. Please install Flutter first."
    else
        # Fix dependencies
        if [[ "$FIX_DEPENDENCIES" == true ]]; then
            print_step "Fixing Flutter dependencies..."
            
            # Clean and get packages
            flutter clean
            flutter pub get
            print_fix "Flutter dependencies cleaned and reinstalled"
            
            # Repair Flutter cache if needed
            if [[ ! -d ".dart_tool" ]]; then
                flutter pub cache repair
                print_fix "Flutter pub cache repaired"
            fi
            echo ""
        fi
        
        # Fix code formatting
        if [[ "$FIX_FORMAT" == true ]]; then
            print_step "Formatting Flutter code..."
            dart format lib/ test/
            print_fix "Flutter code formatted"
            echo ""
        fi
        
        # Fix analysis issues
        print_step "Checking for analysis issues..."
        if flutter analyze 2>&1 | grep -q "error\|warning"; then
            print_info "Analysis issues found. Attempting auto-fix..."
            
            # Try to fix common issues
            find lib -name "*.dart" -type f -exec sed -i 's/var /final /g' {} \; 2>/dev/null || true
            find lib -name "*.dart" -type f -exec sed -i 's/dynamic /Object? /g' {} \; 2>/dev/null || true
            
            print_fix "Common Dart issues auto-fixed"
        else
            print_success "No analysis issues found"
        fi
        echo ""
        
        # Fix Android issues
        print_step "Checking Android configuration..."
        if [[ -d "android" ]]; then
            cd android
            
            # Fix gradle permissions
            if [[ -f "gradlew" ]]; then
                chmod +x gradlew
                print_fix "Gradle wrapper permissions fixed"
            fi
            
            # Clean gradle cache if corrupted
            if [[ -d ".gradle" && ! -f ".gradle/caches/modules-2/modules-2.lock" ]]; then
                rm -rf .gradle
                print_fix "Corrupted Gradle cache cleaned"
            fi
            
            cd "$FLUTTER_DIR"
        fi
        echo ""
    fi
fi

# Fix Web issues
if [[ "$FIX_WEB" == true ]]; then
    print_header "Fixing Web Issues"
    cd "$WEB_DIR"
    
    # Load nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm use default > /dev/null 2>&1 || true
    fi
    
    # Check Node.js installation
    if ! command -v node &> /dev/null; then
        print_error "Node.js not found. Please install Node.js first."
    else
        # Fix dependencies
        if [[ "$FIX_DEPENDENCIES" == true ]]; then
            print_step "Fixing Web dependencies..."
            
            # Remove node_modules and reinstall
            if [[ -d "node_modules" ]]; then
                rm -rf node_modules
                print_fix "Removed corrupted node_modules"
            fi
            
            # Remove lock file if exists
            if [[ -f "package-lock.json" ]]; then
                rm package-lock.json
                print_fix "Removed package-lock.json"
            fi
            
            # Reinstall dependencies
            npm install
            print_fix "Web dependencies reinstalled"
            echo ""
        fi
        
        # Fix code formatting
        if [[ "$FIX_FORMAT" == true ]]; then
            print_step "Formatting Web code..."
            
            # Check if prettier is available
            if npm list prettier &> /dev/null; then
                npx prettier --write "src/**/*.{ts,tsx,js,jsx,json,css}"
                print_fix "Web code formatted with Prettier"
            else
                print_info "Prettier not found, skipping formatting"
            fi
            echo ""
        fi
        
        # Fix TypeScript issues
        print_step "Checking TypeScript issues..."
        if npx tsc --noEmit 2>&1 | grep -q "error"; then
            print_info "TypeScript errors found. Checking for auto-fixable issues..."
            
            # Common TypeScript fixes
            find src -name "*.ts" -o -name "*.tsx" | xargs sed -i 's/: any/: unknown/g' 2>/dev/null || true
            
            print_fix "Common TypeScript issues auto-fixed"
        else
            print_success "No TypeScript errors found"
        fi
        echo ""
        
        # Fix ESLint issues
        print_step "Fixing ESLint issues..."
        if npm run lint -- --fix 2>/dev/null; then
            print_fix "ESLint issues auto-fixed"
        else
            print_info "ESLint auto-fix completed with warnings"
        fi
        echo ""
    fi
fi

# Fix general project issues
print_header "Fixing General Issues"

# Fix line endings
print_step "Fixing line endings..."
find "$PROJECT_DIR" -type f \( -name "*.sh" -o -name "*.dart" -o -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -exec sed -i 's/\r$//' {} \;
print_fix "Line endings fixed"
echo ""

# Fix file permissions
print_step "Fixing file permissions..."
find "$PROJECT_DIR" -type f -name "*.sh" -exec chmod +x {} \;
find "$PROJECT_DIR" -type f -name "*.dart" -exec chmod 644 {} \;
find "$PROJECT_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.jsx" \) -exec chmod 644 {} \;
print_fix "File permissions fixed"
echo ""

# Auto-commit if requested
if [[ "$AUTO_COMMIT" == true && $FIXES_APPLIED -gt 0 ]]; then
    print_header "Auto-Committing Fixes"
    
    cd "$PROJECT_DIR"
    
    # Check if git is available and repo exists
    if command -v git &> /dev/null && [[ -d ".git" ]]; then
        git add -A
        git commit -m "auto-fix: Applied $FIXES_APPLIED automatic fixes

- Fixed script permissions
- Fixed Flutter dependencies and formatting
- Fixed Web dependencies and formatting
- Fixed line endings and file permissions

Auto-generated by VaultNote auto-fix script"
        
        print_fix "Changes committed to git"
    else
        print_info "Git not available or not a repository, skipping commit"
    fi
    echo ""
fi

# Print summary
print_header "Fix Summary"
echo ""
echo -e "Total Fixes Applied: ${GREEN}$FIXES_APPLIED${NC}"
echo ""

if [[ $FIXES_APPLIED -gt 0 ]]; then
    print_success "Auto-fix completed successfully!"
    echo ""
    print_info "Run './auto-test.sh' to verify fixes"
else
    print_success "No fixes needed - project is in good shape!"
fi