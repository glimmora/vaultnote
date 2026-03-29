#!/bin/bash

# VaultNote Auto Test Script
# Runs all tests automatically with comprehensive reporting

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
LOG_FILE="$SCRIPTS_DIR/logs/test-$(date +%Y%m%d-%H%M%S).log"
REPORT_FILE="$SCRIPTS_DIR/logs/test-report-$(date +%Y%m%d-%H%M%S).md"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

# Default values
TEST_FLUTTER=true
TEST_WEB=true
TEST_ANDROID=false
VERBOSE=false
COVERAGE=false
GENERATE_REPORT=true

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
SKIPPED_TESTS=0

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
VaultNote Auto Test Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --flutter-only        Test Flutter only
    -w, --web-only            Test Web only
    -a, --android             Include Android tests
    -v, --verbose             Verbose output
    -c, --coverage            Generate test coverage
    -r, --no-report           Don't generate test report
    -h, --help                Show this help message

Examples:
    $(basename "$0")                    # Test all (Flutter + Web)
    $(basename "$0") -f                 # Test Flutter only
    $(basename "$0") -w                 # Test Web only
    $(basename "$0") -a -c              # Test all with coverage

EOF
}

# Initialize test report
init_report() {
    if [[ "$GENERATE_REPORT" == true ]]; then
        cat > "$REPORT_FILE" << EOF
# VaultNote Test Report

**Generated:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Test Summary

| Test Suite | Status | Details |
|------------|--------|---------|
EOF
    fi
}

# Add test result to report
add_to_report() {
    local suite="$1"
    local status="$2"
    local details="$3"
    
    if [[ "$GENERATE_REPORT" == true ]]; then
        echo "| $suite | $status | $details |" >> "$REPORT_FILE"
    fi
}

# Finalize test report
finalize_report() {
    if [[ "$GENERATE_REPORT" == true ]]; then
        cat >> "$REPORT_FILE" << EOF

## Statistics

- **Total Tests:** $TOTAL_TESTS
- **Passed:** $PASSED_TESTS
- **Failed:** $FAILED_TESTS
- **Skipped:** $SKIPPED_TESTS

## Logs

Full test log: \`$LOG_FILE\`

EOF
        print_info "Test report generated: $REPORT_FILE"
    fi
}

# Run Flutter tests
run_flutter_tests() {
    print_step "Running Flutter tests..."
    
    if [[ ! -d "$FLUTTER_DIR" ]]; then
        print_info "Flutter directory not found, skipping"
        add_to_report "Flutter" "Skipped" "Directory not found"
        return 0
    fi
    
    cd "$FLUTTER_DIR"
    
    # Check if tests exist
    if [[ ! -d "test" ]]; then
        print_info "No Flutter tests found, skipping"
        add_to_report "Flutter" "Skipped" "No test directory"
        return 0
    fi
    
    # Build test command
    TEST_CMD="flutter test"
    
    if [[ "$VERBOSE" == true ]]; then
        TEST_CMD="$TEST_CMD --verbose"
    fi
    
    if [[ "$COVERAGE" == true ]]; then
        TEST_CMD="$TEST_CMD --coverage"
    fi
    
    # Run tests
    print_info "Running Flutter tests..."
    if $TEST_CMD > "$LOG_FILE.flutter" 2>&1; then
        print_success "Flutter tests passed"
        add_to_report "Flutter" "✅ Passed" "All tests passed"
        ((PASSED_TESTS++))
    else
        print_error "Flutter tests failed"
        add_to_report "Flutter" "❌ Failed" "Some tests failed"
        ((FAILED_TESTS++))
        cat "$LOG_FILE.flutter"
    fi
    
    ((TOTAL_TESTS++))
    
    # Generate coverage report if requested
    if [[ "$COVERAGE" == true && -f "coverage/lcov.info" ]]; then
        print_info "Generating coverage report..."
        if command -v genhtml &> /dev/null; then
            genhtml coverage/lcov.info -o coverage/html > /dev/null 2>&1
            print_success "Coverage report generated: coverage/html/index.html"
        else
            print_info "genhtml not found, skipping HTML coverage report"
        fi
    fi
}

# Run Web tests
run_web_tests() {
    print_step "Running Web tests..."
    
    if [[ ! -d "$WEB_DIR" ]]; then
        print_info "Web directory not found, skipping"
        add_to_report "Web" "Skipped" "Directory not found"
        return 0
    fi
    
    cd "$WEB_DIR"
    
    # Check if package.json exists
    if [[ ! -f "package.json" ]]; then
        print_info "package.json not found, skipping"
        add_to_report "Web" "Skipped" "No package.json"
        return 0
    fi
    
    # Load nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm use default > /dev/null 2>&1 || true
    fi
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        print_info "Installing dependencies..."
        npm install > /dev/null 2>&1
    fi
    
    # Check for test script
    if ! grep -q "\"test\"" package.json; then
        print_info "No test script found in package.json, skipping"
        add_to_report "Web" "Skipped" "No test script"
        return 0
    fi
    
    # Build test command
    TEST_CMD="npm test"
    
    if [[ "$VERBOSE" == true ]]; then
        TEST_CMD="$TEST_CMD --verbose"
    fi
    
    # Run tests
    print_info "Running Web tests..."
    if $TEST_CMD > "$LOG_FILE.web" 2>&1; then
        print_success "Web tests passed"
        add_to_report "Web" "✅ Passed" "All tests passed"
        ((PASSED_TESTS++))
    else
        print_error "Web tests failed"
        add_to_report "Web" "❌ Failed" "Some tests failed"
        ((FAILED_TESTS++))
        cat "$LOG_FILE.web"
    fi
    
    ((TOTAL_TESTS++))
}

# Run Android tests
run_android_tests() {
    print_step "Running Android tests..."
    
    if [[ ! -d "$FLUTTER_DIR" ]]; then
        print_info "Flutter directory not found, skipping Android tests"
        add_to_report "Android" "Skipped" "Directory not found"
        return 0
    fi
    
    cd "$FLUTTER_DIR"
    
    # Check if Android tests exist
    if [[ ! -d "test" ]]; then
        print_info "No Android tests found, skipping"
        add_to_report "Android" "Skipped" "No test directory"
        return 0
    fi
    
    # Build test command
    TEST_CMD="flutter test"
    
    if [[ "$VERBOSE" == true ]]; then
        TEST_CMD="$TEST_CMD --verbose"
    fi
    
    # Run tests
    print_info "Running Android tests..."
    if $TEST_CMD > "$LOG_FILE.android" 2>&1; then
        print_success "Android tests passed"
        add_to_report "Android" "✅ Passed" "All tests passed"
        ((PASSED_TESTS++))
    else
        print_error "Android tests failed"
        add_to_report "Android" "❌ Failed" "Some tests failed"
        ((FAILED_TESTS++))
        cat "$LOG_FILE.android"
    fi
    
    ((TOTAL_TESTS++))
}

# Check for lint errors
run_lint_checks() {
    print_step "Running lint checks..."
    
    local lint_errors=0
    
    # Flutter lint
    if [[ -d "$FLUTTER_DIR" && -f "$FLUTTER_DIR/pubspec.yaml" ]]; then
        cd "$FLUTTER_DIR"
        print_info "Running Flutter analyze..."
        if flutter analyze > "$LOG_FILE.flutter-lint" 2>&1; then
            print_success "Flutter lint passed"
            add_to_report "Flutter Lint" "✅ Passed" "No issues found"
        else
            print_error "Flutter lint failed"
            add_to_report "Flutter Lint" "❌ Failed" "Issues found"
            ((lint_errors++))
            cat "$LOG_FILE.flutter-lint"
        fi
    fi
    
    # Web lint
    if [[ -d "$WEB_DIR" && -f "$WEB_DIR/package.json" ]]; then
        cd "$WEB_DIR"
        if grep -q "\"lint\"" package.json; then
            print_info "Running Web lint..."
            if npm run lint > "$LOG_FILE.web-lint" 2>&1; then
                print_success "Web lint passed"
                add_to_report "Web Lint" "✅ Passed" "No issues found"
            else
                print_error "Web lint failed"
                add_to_report "Web Lint" "❌ Failed" "Issues found"
                ((lint_errors++))
                cat "$LOG_FILE.web-lint"
            fi
        else
            print_info "No lint script found in package.json, skipping"
            add_to_report "Web Lint" "Skipped" "No lint script"
        fi
    fi
    
    ((TOTAL_TESTS++))
    
    if [[ $lint_errors -gt 0 ]]; then
        ((FAILED_TESTS++))
    else
        ((PASSED_TESTS++))
    fi
}

# Main function
main() {
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
            -a|--android)
                TEST_ANDROID=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -c|--coverage)
                COVERAGE=true
                shift
                ;;
            -r|--no-report)
                GENERATE_REPORT=false
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
    
    print_header "VaultNote Auto Test"
    echo ""
    
    log "Starting test process..."
    
    # Print test configuration
    print_info "Test Configuration:"
    echo -e "  Flutter: ${GREEN}$TEST_FLUTTER${NC}"
    echo -e "  Web: ${GREEN}$TEST_WEB${NC}"
    echo -e "  Android: ${GREEN}$TEST_ANDROID${NC}"
    echo -e "  Verbose: ${GREEN}$VERBOSE${NC}"
    echo -e "  Coverage: ${GREEN}$COVERAGE${NC}"
    echo ""
    
    # Initialize report
    init_report
    
    # Run lint checks first
    run_lint_checks
    echo ""
    
    # Run tests based on configuration
    if [[ "$TEST_FLUTTER" == true ]]; then
        run_flutter_tests
        echo ""
    fi
    
    if [[ "$TEST_WEB" == true ]]; then
        run_web_tests
        echo ""
    fi
    
    if [[ "$TEST_ANDROID" == true ]]; then
        run_android_tests
        echo ""
    fi
    
    # Print summary
    print_header "Test Summary"
    echo ""
    
    print_info "Results:"
    echo -e "  Total Tests: ${CYAN}$TOTAL_TESTS${NC}"
    echo -e "  Passed: ${GREEN}$PASSED_TESTS${NC}"
    echo -e "  Failed: ${RED}$FAILED_TESTS${NC}"
    echo -e "  Skipped: ${YELLOW}$SKIPPED_TESTS${NC}"
    echo ""
    
    # Finalize report
    finalize_report
    
    # Exit with appropriate code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        print_error "Some tests failed"
        exit 1
    else
        print_success "All tests passed"
        exit 0
    fi
}

# Run main function
main "$@"