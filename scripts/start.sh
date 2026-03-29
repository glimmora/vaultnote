#!/bin/bash

# VaultNote Auto-Run Script
# Runs both Flutter and Web applications

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

# Default values
RUN_FLUTTER=true
RUN_WEB=true
FLUTTER_DEVICE=""
WEB_PORT=5173
BACKGROUND=false

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
VaultNote Auto-Run Script

Usage: $(basename "$0") [OPTIONS]

Options:
    -f, --flutter-only    Run Flutter app only
    -w, --web-only        Run Web app only
    -d, --device DEVICE   Flutter device ID
    -p, --port PORT       Web dev server port (default: 5173)
    -b, --background      Run in background
    -h, --help            Show this help message

Examples:
    $(basename "$0")                    # Run both Flutter and Web
    $(basename "$0") -f                 # Run Flutter only
    $(basename "$0") -w                 # Run Web only
    $(basename "$0") -d chrome          # Run Flutter on Chrome
    $(basename "$0") -p 3000            # Run Web on port 3000

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--flutter-only)
            RUN_WEB=false
            shift
            ;;
        -w|--web-only)
            RUN_FLUTTER=false
            shift
            ;;
        -d|--device)
            FLUTTER_DEVICE="$2"
            shift 2
            ;;
        -p|--port)
            WEB_PORT="$2"
            shift 2
            ;;
        -b|--background)
            BACKGROUND=true
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

print_header "VaultNote Auto-Run"
echo ""

# Check prerequisites
print_step "Checking prerequisites..."

# Check Flutter
if [[ "$RUN_FLUTTER" == true ]]; then
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        print_success "Flutter: $FLUTTER_VERSION"
    else
        print_error "Flutter not found"
        exit 1
    fi
fi

# Check Node.js for Web
if [[ "$RUN_WEB" == true ]]; then
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version)
        print_success "Node.js: $NODE_VERSION"
    else
        print_error "Node.js not found"
        exit 1
    fi
fi

echo ""

# Function to run Flutter app
run_flutter() {
    print_header "Running Flutter App"
    cd "$FLUTTER_DIR"
    
    # Get dependencies
    print_step "Getting Flutter dependencies..."
    flutter pub get
    print_success "Dependencies installed"
    echo ""
    
    # List available devices
    print_step "Available Flutter devices:"
    flutter devices
    echo ""
    
    # Run Flutter app
    print_step "Starting Flutter app..."
    if [[ -n "$FLUTTER_DEVICE" ]]; then
        flutter run -d "$FLUTTER_DEVICE" &
    else
        flutter run &
    fi
    FLUTTER_PID=$!
    print_success "Flutter app started (PID: $FLUTTER_PID)"
}

# Function to run Web app
run_web() {
    print_header "Running Web App"
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
    
    # Run Web app
    print_step "Starting Web dev server on port $WEB_PORT..."
    if [[ "$BACKGROUND" == true ]]; then
        npm run dev -- --port "$WEB_PORT" &
        WEB_PID=$!
        print_success "Web dev server started (PID: $WEB_PID)"
    else
        npm run dev -- --port "$WEB_PORT"
    fi
}

# Run applications
if [[ "$RUN_FLUTTER" == true && "$RUN_WEB" == true ]]; then
    # Run both in parallel
    run_flutter
    echo ""
    run_web
    
    print_header "Both Apps Running"
    print_info "Flutter app PID: $FLUTTER_PID"
    print_info "Web app running on http://localhost:$WEB_PORT"
    echo ""
    print_info "Press Ctrl+C to stop all apps"
    
    # Wait for background processes
    wait
    
elif [[ "$RUN_FLUTTER" == true ]]; then
    run_flutter
    
    print_header "Flutter App Running"
    print_info "Press Ctrl+C to stop"
    wait $FLUTTER_PID
    
elif [[ "$RUN_WEB" == true ]]; then
    run_web
    
    if [[ "$BACKGROUND" == true ]]; then
        print_header "Web App Running"
        print_info "Web app running on http://localhost:$WEB_PORT"
        print_info "Web app PID: $WEB_PID"
        print_info "Press Ctrl+C to stop"
        wait $WEB_PID
    fi
fi