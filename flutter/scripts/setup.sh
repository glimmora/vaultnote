#!/bin/bash

# VaultNote Complete Setup Script
# Installs Flutter, Android SDK, and configures environment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration - Get absolute paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULTNOTE_DIR="$(dirname "$SCRIPT_DIR")"
VAULTNOTE_FLUTTER_DIR="$VAULTNOTE_DIR/flutter"

FLUTTER_DIR="$HOME/flutter"
ANDROID_HOME="$HOME/android-sdk"

# Components to install
INSTALL_FLUTTER=true
INSTALL_ANDROID_SDK=true
INSTALL_OPENJDK=true
CONFIGURE_ENV=true

# Functions
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
    echo -e "${CYAN}→ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

show_help() {
    cat << EOF
VaultNote Setup Script

Usage: $(basename "$0") [OPTIONS]

Options:
    --no-flutter        Skip Flutter installation
    --no-android-sdk    Skip Android SDK installation
    --no-jdk            Skip OpenJDK installation
    --no-env            Skip environment configuration
    --flutter-only      Only install Flutter
    --sdk-only          Only install Android SDK
    -h, --help          Show this help message

Examples:
    $(basename "$0")                      # Full installation
    $(basename "$0") --flutter-only       # Install Flutter only
    $(basename "$0") --sdk-only           # Install Android SDK only
    $(basename "$0") --no-jdk             # Skip JDK (if already installed)

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-flutter)
            INSTALL_FLUTTER=false
            shift
            ;;
        --no-android-sdk)
            INSTALL_ANDROID_SDK=false
            shift
            ;;
        --no-jdk)
            INSTALL_OPENJDK=false
            shift
            ;;
        --no-env)
            CONFIGURE_ENV=false
            shift
            ;;
        --flutter-only)
            INSTALL_ANDROID_SDK=false
            INSTALL_OPENJDK=false
            shift
            ;;
        --sdk-only)
            INSTALL_FLUTTER=false
            INSTALL_OPENJDK=false
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    print_error "This script should not be run as root"
    print_info "Run without sudo: ./scripts/setup.sh"
    exit 1
fi

# Detect OS
detect_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$ID
    else
        OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
    print_info "Detected OS: $OS"
}

# Install system dependencies
install_system_deps() {
    print_header "Installing System Dependencies"
    
    case $OS in
        ubuntu|debian|linuxmint)
            print_step "Updating package lists..."
            sudo apt-get update -qq
            
            print_step "Installing required packages..."
            sudo apt-get install -y -qq \
                curl \
                git \
                unzip \
                xz-utils \
                zip \
                libglu1-mesa \
                wget \
                clang \
                cmake \
                ninja-build \
                pkg-config \
                libgtk-3-dev \
                liblzma-dev \
                libstdc++-12-dev > /dev/null 2>&1
            print_success "System dependencies installed"
            ;;
        fedora)
            print_step "Installing required packages..."
            sudo dnf install -y -q \
                curl \
                git \
                unzip \
                xz \
                zip \
                wget \
                clang \
                cmake \
                ninja-build \
                pkg-config \
                gtk3-devel > /dev/null 2>&1
            print_success "System dependencies installed"
            ;;
        arch|manjaro)
            print_step "Installing required packages..."
            sudo pacman -S --noconfirm --quiet \
                curl \
                git \
                unzip \
                xz \
                zip \
                wget \
                clang \
                cmake \
                ninja \
                pkgconf \
                gtk3 > /dev/null 2>&1
            print_success "System dependencies installed"
            ;;
        *)
            print_warning "Unknown OS. Please ensure you have: curl, git, unzip, xz-utils, zip"
            ;;
    esac
    echo ""
}

# Install OpenJDK
install_openjdk() {
    if command -v java &> /dev/null; then
        JAVA_VERSION=$(java -version 2>&1 | head -1 | cut -d'"' -f2 | cut -d'.' -f1)
        print_info "Java already installed: $(java -version 2>&1 | head -1)"
        
        if [[ $JAVA_VERSION -ge 11 ]]; then
            print_success "Java version is sufficient ($JAVA_VERSION)"
            return 0
        else
            print_warning "Java version $JAVA_VERSION detected. Installing Java 17..."
        fi
    fi
    
    print_header "Installing OpenJDK"
    
    case $OS in
        ubuntu|debian|linuxmint)
            sudo apt-get install -y -qq openjdk-17-jdk > /dev/null 2>&1
            ;;
        fedora)
            sudo dnf install -y -q java-17-openjdk-devel > /dev/null 2>&1
            ;;
        arch|manjaro)
            sudo pacman -S --noconfirm --quiet jdk-openjdk > /dev/null 2>&1
            ;;
        *)
            print_error "Please install OpenJDK 17 manually"
            return 1
            ;;
    esac
    
    print_success "OpenJDK installed"
    echo ""
}

# Install Flutter
install_flutter() {
    if command -v flutter &> /dev/null; then
        FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
        print_info "Flutter already installed: $FLUTTER_VERSION"
        
        # Get existing Flutter location
        FLUTTER_BIN=$(which flutter)
        FLUTTER_DIR=$(dirname $(dirname "$FLUTTER_BIN"))
        print_info "Flutter location: $FLUTTER_DIR"
        return 0
    fi
    
    # Check if Flutter exists in target directory
    if [[ -f "$FLUTTER_DIR/bin/flutter" ]]; then
        print_info "Flutter found at: $FLUTTER_DIR"
        return 0
    fi
    
    print_header "Installing Flutter"
    
    print_step "Creating Flutter directory..."
    mkdir -p "$FLUTTER_DIR"
    
    print_step "Downloading Flutter SDK..."
    cd /tmp
    
    # Use a stable Flutter version
    FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.0-stable.tar.xz"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O flutter.tar.xz "$FLUTTER_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o flutter.tar.xz "$FLUTTER_URL"
    else
        print_error "Neither wget nor curl found. Please install one of them."
        exit 1
    fi
    
    print_step "Extracting Flutter SDK..."
    tar xf flutter.tar.xz -C "$FLUTTER_DIR" --strip-components=1
    rm -f flutter.tar.xz
    
    # Add to PATH for this session
    export PATH="$PATH:$FLUTTER_DIR/bin"
    
    print_success "Flutter installed to: $FLUTTER_DIR"
    
    # Disable analytics
    flutter config --no-analytics > /dev/null 2>&1 || true
    
    echo ""
}

# Install Android Command Line Tools
install_android_sdk() {
    if [[ -d "$ANDROID_HOME" ]] && [[ -f "$ANDROID_HOME/platform-tools/adb" ]]; then
        print_info "Android SDK already installed at: $ANDROID_HOME"
        return 0
    fi
    
    print_header "Installing Android SDK"
    
    print_step "Creating Android SDK directory..."
    mkdir -p "$ANDROID_HOME"
    mkdir -p "$ANDROID_HOME/cmdline-tools"
    
    cd /tmp
    
    print_step "Downloading Android Command Line Tools..."
    CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    
    if command -v wget &> /dev/null; then
        wget -q --show-progress -O cmdline-tools.zip "$CMDLINE_TOOLS_URL"
    elif command -v curl &> /dev/null; then
        curl -L -o cmdline-tools.zip "$CMDLINE_TOOLS_URL"
    else
        print_error "Neither wget nor curl found."
        exit 1
    fi
    
    print_step "Extracting command line tools..."
    unzip -q cmdline-tools.zip
    mv cmdline-tools "$ANDROID_HOME/cmdline-tools/latest"
    rm -f cmdline-tools.zip
    
    # Add to PATH temporarily
    export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
    
    print_step "Setting up SDK components..."
    
    # Accept licenses
    yes | sdkmanager --licenses > /dev/null 2>&1 || true
    
    print_step "Installing required SDK components..."
    sdkmanager --update > /dev/null 2>&1 || true
    sdkmanager \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "cmdline-tools;latest" > /dev/null 2>&1
    
    print_success "Android SDK installed to: $ANDROID_HOME"
    echo ""
}

# Configure environment
configure_environment() {
    print_header "Configuring Environment"
    
    # Detect shell config
    SHELL_RC=""
    if [[ -n "$ZSH_VERSION" ]] && [[ -f "$HOME/.zshrc" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -f "$HOME/.bashrc" ]]; then
        SHELL_RC="$HOME/.bashrc"
    elif [[ -f "$HOME/.profile" ]]; then
        SHELL_RC="$HOME/.profile"
    else
        SHELL_RC="$HOME/.bashrc"
        touch "$SHELL_RC"
    fi
    
    print_info "Using shell config: $SHELL_RC"
    
    # Create environment file
    ENV_FILE="$HOME/.vaultnote_env"
    
    # Backup existing
    if [[ -f "$ENV_FILE" ]]; then
        cp "$ENV_FILE" "$ENV_FILE.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    cat > "$ENV_FILE" << EOF
# VaultNote Development Environment
# Generated: $(date)
# Source: $ENV_FILE

EOF

    # Add Flutter
    if [[ -n "$FLUTTER_DIR" ]] && [[ -d "$FLUTTER_DIR" ]]; then
        echo "export FLUTTER_HOME=\"$FLUTTER_DIR\"" >> "$ENV_FILE"
        echo "export PATH=\"\$PATH:\$FLUTTER_HOME/bin\"" >> "$ENV_FILE"
    fi
    
    # Add Android SDK
    if [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]]; then
        echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> "$ENV_FILE"
        echo "export ANDROID_SDK_ROOT=\"\$ANDROID_HOME\"" >> "$ENV_FILE"
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools\"" >> "$ENV_FILE"
    fi
    
    # Add Java if found
    if command -v java &> /dev/null; then
        JAVA_BIN=$(which java)
        if [[ -L "$JAVA_BIN" ]]; then
            JAVA_REAL=$(readlink -f "$JAVA_BIN")
            JAVA_HOME=$(dirname $(dirname "$JAVA_REAL"))
            echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$ENV_FILE"
        fi
    fi
    
    # Add Flutter settings
    cat >> "$ENV_FILE" << 'EOF'

# Flutter settings
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_STORAGE_BASE_URL="https://storage.googleapis.com"
EOF
    
    print_success "Created environment file: $ENV_FILE"
    
    # Add to shell config if not present
    if ! grep -q "vaultnote_env" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# VaultNote Environment" >> "$SHELL_RC"
        echo "if [ -f \"$HOME/.vaultnote_env\" ]; then" >> "$SHELL_RC"
        echo "    source \"$HOME/.vaultnote_env\"" >> "$SHELL_RC"
        echo "fi" >> "$SHELL_RC"
        print_success "Added environment to shell config"
    else
        print_info "Environment already in shell config"
    fi
    
    # Create aliases file
    ALIASES_FILE="$HOME/.vaultnote_aliases"
    
    cat > "$ALIASES_FILE" << EOF
# VaultNote Development Aliases
# Generated: $(date)

alias vn='cd $VAULTNOTE_FLUTTER_DIR'
alias vn-build='$VAULTNOTE_FLUTTER_DIR/scripts/build.sh'
alias vn-build-all='$VAULTNOTE_FLUTTER_DIR/scripts/build_all.sh'
alias vn-debug='$VAULTNOTE_FLUTTER_DIR/scripts/build_debug.sh'
alias vn-install='$VAULTNOTE_FLUTTER_DIR/scripts/install.sh'
alias vn-verify='$VAULTNOTE_FLUTTER_DIR/scripts/verify_release.sh'
alias vn-doctor='cd $VAULTNOTE_FLUTTER_DIR && flutter doctor -v'
alias vn-clean='cd $VAULTNOTE_FLUTTER_DIR && flutter clean && flutter pub get'
alias vn-setup='$VAULTNOTE_FLUTTER_DIR/scripts/setup.sh'
EOF
    
    print_success "Created aliases file: $ALIASES_FILE"
    
    if ! grep -q "vaultnote_aliases" "$SHELL_RC" 2>/dev/null; then
        echo "" >> "$SHELL_RC"
        echo "# VaultNote Aliases" >> "$SHELL_RC"
        echo "if [ -f \"$HOME/.vaultnote_aliases\" ]; then" >> "$SHELL_RC"
        echo "    source \"$HOME/.vaultnote_aliases\"" >> "$SHELL_RC"
        echo "fi" >> "$SHELL_RC"
        print_success "Added aliases to shell config"
    else
        print_info "Aliases already in shell config"
    fi
    
    # Create local.properties
    if [[ -d "$ANDROID_HOME" ]] && [[ -d "$FLUTTER_DIR" ]]; then
        LOCAL_PROPS="$VAULTNOTE_FLUTTER_DIR/android/local.properties"
        cat > "$LOCAL_PROPS" << EOF
# VaultNote Android Configuration
# Generated: $(date)

sdk.dir=$ANDROID_HOME
flutter.sdk=$FLUTTER_DIR
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF
        print_success "Created android/local.properties"
    fi
    
    # Source the environment
    source "$ENV_FILE"
    
    print_success "Environment configured"
    echo ""
}

# Run Flutter doctor
run_flutter_doctor() {
    print_header "Running Flutter Doctor"
    echo ""
    
    # Ensure PATH includes our installations
    export PATH="$PATH:$FLUTTER_DIR/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools"
    
    if command -v flutter &> /dev/null; then
        flutter doctor -v 2>&1 | head -30
    else
        print_warning "Flutter not in PATH"
    fi
    
    echo ""
}

# Show summary
show_summary() {
    print_header "Setup Complete!"
    echo ""
    print_success "VaultNote development environment is ready"
    echo ""
    
    print_info "Installed components:"
    [[ -n "$FLUTTER_DIR" ]] && [[ -d "$FLUTTER_DIR" ]] && echo "  ✓ Flutter: $FLUTTER_DIR"
    [[ -n "$ANDROID_HOME" ]] && [[ -d "$ANDROID_HOME" ]] && echo "  ✓ Android SDK: $ANDROID_HOME"
    command -v java &> /dev/null && echo "  ✓ Java: $(java -version 2>&1 | head -1)"
    echo ""
    
    print_info "Next steps:"
    echo ""
    echo "1. Reload your shell configuration:"
    echo -e "   ${GREEN}source $SHELL_RC${NC}"
    echo ""
    echo "2. Or start a new terminal session"
    echo ""
    echo "3. Navigate to the project:"
    echo -e "   ${GREEN}vn${NC}"
    echo ""
    echo "4. Create a signing key:"
    echo -e "   ${GREEN}./scripts/create_keystore.sh${NC}"
    echo ""
    echo "5. Build your first app:"
    echo -e "   ${GREEN}vn-debug${NC}  (debug build)"
    echo -e "   ${GREEN}vn-build${NC}  (release build)"
    echo ""
    
    print_info "Available aliases:"
    echo "  vn          - Navigate to Flutter project"
    echo "  vn-build    - Build release APK"
    echo "  vn-debug    - Quick debug build"
    echo "  vn-install  - Install on device"
    echo "  vn-doctor   - Run flutter doctor"
    echo "  vn-clean    - Clean and get dependencies"
    echo ""
    
    print_success "All done!"
    echo ""
}

# Main execution
main() {
    print_header "VaultNote Development Environment Setup"
    echo ""
    
    # Detect OS
    detect_os
    echo ""
    
    # Install system dependencies
    install_system_deps
    
    # Install OpenJDK
    if [[ "$INSTALL_OPENJDK" == true ]]; then
        install_openjdk
    fi
    
    # Install Flutter
    if [[ "$INSTALL_FLUTTER" == true ]]; then
        install_flutter
    fi
    
    # Install Android SDK
    if [[ "$INSTALL_ANDROID_SDK" == true ]]; then
        install_android_sdk
    fi
    
    # Configure environment
    if [[ "$CONFIGURE_ENV" == true ]]; then
        configure_environment
    fi
    
    # Run Flutter doctor
    run_flutter_doctor
    
    # Show summary
    show_summary
}

# Run main function
main "$@"
