#!/bin/bash

# VaultNote Auto-Test Script
# Runs tests for Flutter and Web applications

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
TEST_FLUTTER=true
TEST_WEB=true
FLUTTER_COVERAGE=false
WEB_COVERAGE=false
VERBOSE=false

# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

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
VaultNote Auto-Test Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --flutter-only    Test Flutter only
    -w, --web-only        Test Web only
    -c, --coverage        Generate coverage reports
    -v, --verbose         Verbose output
    -h, --help            Show this help message

Examples:
    $(basename "$0")                    # Test both Flutter and Web
    $(basename "$0") -f                 # Test Flutter only
    $(basename "$0") -w                 # Test Web only
    $(basename "$0") -c                 # Test with coverage

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flutter-only)
            TEST_WEB=false
            shift
            ;;
        -w|--web-only)
            TEST_FLUTTER=false
            shift
            ;;
        -c|--coverage)
            FLUTTER_COVERAGE=true
            WEB_COVERAGE=true
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
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

print_header "VaultNote Auto-Test"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

if [[ "$TEST_FLUTTER" == true ]]; then
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        print_success "Flutter: $FLUTTER_VERSION"
    else
        print_error "Flutter not found"
        exit 1
    fi
fi

if [[ "$TEST_WEB" == true ]]; then
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js: $NODE_VERSION"
    else
        print_error "Node.js not found"
        exit 1
    fi
fi

echo ""

# Function to run Flutter tests
test_flutter() {
    print_header "Testing Flutter App"
    cd "$FLUTTER_DIR"
    
    # Get dependencies
    print_step "Getting Flutter dependencies..."
    flutter pub get
    print_success "Dependencies installed"
    echo ""
    
    # Run static analysis
    print_step "Running static analysis..."
    if flutter analyze; then
        print_success "Static analysis passed"
        ((PASSED_TESTS++))
    else
        print_error "Static analysis failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo ""
    
    # Run tests
    print_step "Running Flutter tests..."
    TEST_ARGS=""
    if [[ "$FLUTTER_COVERAGE" == true ]]; then
        TEST_ARGS="--coverage"
    fi
    if [[ "$VERBOSE" == true ]]; then
        TEST_ARGS="$TEST_ARGS --verbose"
    fi
    
    if flutter test $TEST_ARGS; then
        print_success "Flutter tests passed"
        ((PASSED_TESTS++))
        
        # Show coverage if enabled
        if [[ "$FLUTTER_COVERAGE" == true ]]; then
            echo ""
            print_step "Coverage report generated at: $FLUTTER_DIR/coverage/lcov.info"
            if command -v lcov &> /dev/null; then
                print_step "Generating HTML coverage report..."
                genhtml coverage/lcov.info -o coverage/html
                print_success "HTML coverage report at: $FLUTTER_DIR/coverage/html/index.html"
            fi
        fi
    else
        print_error "Flutter tests failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo ""
}

# Function to run Web tests
test_web() {
    print_header "Testing Web App"
    cd "$WEB_DIR"
    
    # Load nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm use default > /dev/null 2>&1 || true
    fi
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        print_step "Installing web dependencies..."
        npm install
        print_success "Dependencies installed"
    fi
    
    echo ""
    
    # Run linting
    print_step "Running ESLint..."
    if npm run lint; then
        print_success "Linting passed"
        ((PASSED_TESTS++))
    else
        print_error "Linting failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo ""
    
    # Run TypeScript check
    print_step "Running TypeScript check..."
    if npx tsc --noEmit; then
        print_success "TypeScript check passed"
        ((PASSED_TESTS++))
    else
        print_error "TypeScript check failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo ""
    
    # Build test
    print_step "Testing production build..."
    if npm run build; then
        print_success "Build test passed"
        ((PASSED_TESTS++))
        
        # Verify build output
        if [[ -d "dist" && -f "dist/index.html" ]]; then
            print_success "Build output verified"
            ((PASSED_TESTS++))
        else
            print_error "Build output incomplete"
            ((FAILED_TESTS++))
        fi
        ((TOTAL_TESTS++))
    else
        print_error "Build test failed"
        ((FAILED_TESTS++))
    fi
    ((TOTAL_TESTS++))
    echo ""
}

# Run tests
if [[ "$TEST_FLUTTER" == true ]]; then
    test_flutter
fi

if [[ "$TEST_WEB" == true ]]; then
    test_web
fi

# Print summary
print_header "Test Summary"
echo ""
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [[ $FAILED_TESTS -eq 0 ]]; then
    print_success "All tests passed!"
    exit 0
else
    print_error "Some tests failed"
    exit 1
fi