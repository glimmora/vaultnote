#!/bin/bash

# VaultNote Auto Run Script
# Detects project type and runs it appropriately

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
LOG_FILE="$SCRIPTS_DIR/logs/run-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

# Default values
PROJECT_TYPE=""
MODE="development"
PORT=3000
VERBOSE=false
BACKGROUND=false

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
VaultNote Auto Run Script

Usage: $(basename "$0") [OPTIONS] [PROJECT_TYPE]

Options:
    -m, --mode MODE       Run mode: development, production, debug (default: development)
    -p, --port PORT       Port for web server (default: 3000)
    -v, --verbose         Verbose output
    -b, --background      Run in background
    -h, --help            Show this help message

Project Types:
    flutter               Run Flutter app
    web                   Run Web app
    android               Run Android app
    auto                  Auto-detect project type (default)

Examples:
    $(basename "$0")                    # Auto-detect and run
    $(basename "$0") flutter            # Run Flutter app
    $(basename "$0") web -p 8080        # Run Web app on port 8080
    $(basename "$0") -b                 # Run in background

EOF
}

# Detect project type
detect_project_type() {
    if [[ -d "$FLUTTER_DIR" && -f "$FLUTTER_DIR/pubspec.yaml" ]]; then
        echo "flutter"
    elif [[ -d "$WEB_DIR" && -f "$WEB_DIR/package.json" ]]; then
        echo "web"
    elif [[ -f "$PROJECT_DIR/android/app/build.gradle" ]]; then
        echo "android"
    else
        echo "unknown"
    fi
}

# Check prerequisites
check_prerequisites() {
    local project_type="$1"
    
    case $project_type in
        flutter)
            if ! command -v flutter &> /dev/null; then
                print_error "Flutter not found. Run ./scripts/setup.sh first"
                exit 1
            fi
            ;;
        web)
            if ! command -v node &> /dev/null; then
                print_error "Node.js not found. Run ./scripts/setup.sh first"
                exit 1
            fi
            ;;
        android)
            if ! command -v flutter &> /dev/null; then
                print_error "Flutter not found. Run ./scripts/setup.sh first"
                exit 1
            fi
            if [[ -z "$ANDROID_SDK_ROOT" ]]; then
                print_error "Android SDK not configured. Run ./scripts/setup.sh first"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown project type: $project_type"
            exit 1
            ;;
    esac
}

# Run Flutter project
run_flutter() {
    local mode="$1"
    local verbose="$2"
    local background="$3"
    
    print_step "Running Flutter app..."
    cd "$FLUTTER_DIR"
    
    # Build run command
    RUN_CMD="flutter run"
    
    case $mode in
        development)
            RUN_CMD="$RUN_CMD --debug"
            ;;
        production)
            RUN_CMD="$RUN_CMD --release"
            ;;
        debug)
            RUN_CMD="$RUN_CMD --debug --enable-software-rendering"
            ;;
    esac
    
    if [[ "$verbose" == true ]]; then
        RUN_CMD="$RUN_CMD --verbose"
    fi
    
    # Check for connected devices
    print_info "Checking for connected devices..."
    flutter devices
    
    # Run in background if requested
    if [[ "$background" == true ]]; then
        print_info "Starting Flutter app in background..."
        nohup $RUN_CMD > "$LOG_FILE.flutter" 2>&1 &
        FLUTTER_PID=$!
        echo $FLUTTER_PID > "$SCRIPTS_DIR/.flutter.pid"
        print_success "Flutter app started in background (PID: $FLUTTER_PID)"
        print_info "Logs: $LOG_FILE.flutter"
        print_info "Stop with: kill $FLUTTER_PID"
    else
        print_info "Starting Flutter app..."
        $RUN_CMD
    fi
}

# Run Web project
run_web() {
    local mode="$1"
    local port="$2"
    local verbose="$3"
    local background="$4"
    
    print_step "Running Web app..."
    cd "$WEB_DIR"
    
    # Load nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm use default > /dev/null 2>&1 || true
    fi
    
    # Install dependencies if needed
    if [[ ! -d "node_modules" ]]; then
        print_info "Installing dependencies..."
        npm install
    fi
    
    # Set environment variables
    export NODE_ENV="$mode"
    export PORT="$port"
    
    # Build run command
    if [[ -f "package.json" ]]; then
        # Check for available scripts
        if grep -q "\"dev\"" package.json; then
            RUN_CMD="npm run dev"
        elif grep -q "\"start\"" package.json; then
            RUN_CMD="npm start"
        else
            print_error "No dev or start script found in package.json"
            exit 1
        fi
    else
        print_error "package.json not found"
        exit 1
    fi
    
    if [[ "$verbose" == true ]]; then
        RUN_CMD="$RUN_CMD --verbose"
    fi
    
    # Run in background if requested
    if [[ "$background" == true ]]; then
        print_info "Starting Web app in background on port $port..."
        nohup $RUN_CMD > "$LOG_FILE.web" 2>&1 &
        WEB_PID=$!
        echo $WEB_PID > "$SCRIPTS_DIR/.web.pid"
        print_success "Web app started in background (PID: $WEB_PID)"
        print_info "URL: http://localhost:$port"
        print_info "Logs: $LOG_FILE.web"
        print_info "Stop with: kill $WEB_PID"
    else
        print_info "Starting Web app on port $port..."
        $RUN_CMD
    fi
}

# Run Android project
run_android() {
    local mode="$1"
    local verbose="$2"
    local background="$3"
    
    print_step "Running Android app..."
    cd "$FLUTTER_DIR"
    
    # Build run command
    RUN_CMD="flutter run"
    
    case $mode in
        development)
            RUN_CMD="$RUN_CMD --debug"
            ;;
        production)
            RUN_CMD="$RUN_CMD --release"
            ;;
        debug)
            RUN_CMD="$RUN_CMD --debug --enable-software-rendering"
            ;;
    esac
    
    if [[ "$verbose" == true ]]; then
        RUN_CMD="$RUN_CMD --verbose"
    fi
    
    # Check for connected devices or emulators
    print_info "Checking for Android devices/emulators..."
    flutter devices
    
    # Run in background if requested
    if [[ "$background" == true ]]; then
        print_info "Starting Android app in background..."
        nohup $RUN_CMD > "$LOG_FILE.android" 2>&1 &
        ANDROID_PID=$!
        echo $ANDROID_PID > "$SCRIPTS_DIR/.android.pid"
        print_success "Android app started in background (PID: $ANDROID_PID)"
        print_info "Logs: $LOG_FILE.android"
        print_info "Stop with: kill $ANDROID_PID"
    else
        print_info "Starting Android app..."
        $RUN_CMD
    fi
}

# Main function
main() {
    local project_type="auto"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--mode)
                MODE="$2"
                shift 2
                ;;
            -p|--port)
                PORT="$2"
                shift 2
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -b|--background)
                BACKGROUND=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                project_type="$1"
                shift
                ;;
        esac
    done
    
    print_header "VaultNote Auto Run"
    echo ""
    
    log "Starting run process..."
    
    # Auto-detect project type if not specified
    if [[ "$project_type" == "auto" ]]; then
        project_type=$(detect_project_type)
        print_info "Auto-detected project type: $project_type"
    fi
    
    # Check if project type is valid
    if [[ "$project_type" == "unknown" ]]; then
        print_error "Could not detect project type"
        print_info "Please specify project type: flutter, web, or android"
        exit 1
    fi
    
    # Check prerequisites
    check_prerequisites "$project_type"
    
    # Print run configuration
    print_info "Run Configuration:"
    echo -e "  Project Type: ${GREEN}$project_type${NC}"
    echo -e "  Mode: ${GREEN}$MODE${NC}"
    echo -e "  Port: ${GREEN}$PORT${NC} (Web only)"
    echo -e "  Verbose: ${GREEN}$VERBOSE${NC}"
    echo -e "  Background: ${GREEN}$BACKGROUND${NC}"
    echo ""
    
    # Run project based on type
    case $project_type in
        flutter)
            run_flutter "$MODE" "$VERBOSE" "$BACKGROUND"
            ;;
        web)
            run_web "$MODE" "$PORT" "$VERBOSE" "$BACKGROUND"
            ;;
        android)
            run_android "$MODE" "$VERBOSE" "$BACKGROUND"
            ;;
        *)
            print_error "Unsupported project type: $project_type"
            exit 1
            ;;
    esac
    
    echo ""
    print_success "Run process completed"
    log "Run process completed"
}

# Run main function
main "$@"