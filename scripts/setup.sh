#!/bin/bash

# VaultNote Auto Setup Script
# Detects and installs missing dependencies automatically

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
LOG_FILE="$SCRIPTS_DIR/logs/setup-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory
mkdir -p "$SCRIPTS_DIR/logs"

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

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "unknown"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install package based on OS
install_package() {
    local package="$1"
    local os="$2"
    
    case $os in
        linux)
            if command_exists apt-get; then
                sudo apt-get update && sudo apt-get install -y "$package"
            elif command_exists yum; then
                sudo yum install -y "$package"
            elif command_exists dnf; then
                sudo dnf install -y "$package"
            else
                log_error "Unsupported package manager for $package"
                return 1
            fi
            ;;
        macos)
            if command_exists brew; then
                brew install "$package"
            else
                log_error "Homebrew not found. Please install Homebrew first."
                return 1
            fi
            ;;
        windows)
            if command_exists choco; then
                choco install "$package" -y
            elif command_exists scoop; then
                scoop install "$package"
            else
                log_error "No package manager found. Please install Chocolatey or Scoop."
                return 1
            fi
            ;;
        *)
            log_error "Unsupported OS: $os"
            return 1
            ;;
    esac
}

# Setup Node.js and npm
setup_nodejs() {
    print_step "Setting up Node.js..."
    
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js already installed: $NODE_VERSION"
        return 0
    fi
    
    # Install Node.js using nvm if available
    if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
        source "$HOME/.nvm/nvm.sh"
        nvm install node
        nvm use node
        print_success "Node.js installed via nvm"
    else
        # Install Node.js using package manager
        local os=$(detect_os)
        install_package "nodejs" "$os"
        install_package "npm" "$os"
        print_success "Node.js installed"
    fi
}

# Setup npm cache
setup_npm_cache() {
    print_step "Setting up npm cache..."
    
    # Set npm cache directory
    npm config set cache "$HOME/.npm" --global
    
    # Enable package-lock
    npm config set package-lock true --global
    
    print_success "npm cache configured"
}

# Setup pnpm (optional but recommended)
setup_pnpm() {
    print_step "Setting up pnpm..."
    
    if command_exists pnpm; then
        PNPM_VERSION=$(pnpm --version)
        print_success "pnpm already installed: $PNPM_VERSION"
        return 0
    fi
    
    # Install pnpm
    npm install -g pnpm
    
    # Configure pnpm store
    pnpm config set store-dir "$HOME/.pnpm-store"
    
    print_success "pnpm installed and configured"
}

# Setup Java (for Android development)
setup_java() {
    print_step "Setting up Java..."
    
    if command_exists java; then
        JAVA_VERSION=$(java -version 2>&1 | head -1)
        print_success "Java already installed: $JAVA_VERSION"
        return 0
    fi
    
    # Install Java
    local os=$(detect_os)
    case $os in
        linux)
            install_package "openjdk-17-jdk" "$os"
            ;;
        macos)
            install_package "openjdk@17" "$os"
            ;;
        windows)
            install_package "openjdk17" "$os"
            ;;
    esac
    
    # Set JAVA_HOME
    if [[ -f "/usr/lib/jvm/java-17-openjdk-amd64/bin/java" ]]; then
        export JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"
        echo "export JAVA_HOME=\"/usr/lib/jvm/java-17-openjdk-amd64\"" >> "$HOME/.bashrc"
    fi
    
    print_success "Java installed"
}

# Setup Android SDK
setup_android_sdk() {
    print_step "Setting up Android SDK..."
    
    # Set Android SDK path
    ANDROID_SDK_ROOT="$HOME/Android/Sdk"
    export ANDROID_SDK_ROOT
    export ANDROID_HOME="$ANDROID_SDK_ROOT"
    
    # Add to PATH
    export PATH="$ANDROID_SDK_ROOT/emulator:$ANDROID_SDK_ROOT/tools/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
    
    # Create SDK directory
    mkdir -p "$ANDROID_SDK_ROOT"
    
    # Download and install Android command line tools
    if [[ ! -d "$ANDROID_SDK_ROOT/cmdline-tools" ]]; then
        local os=$(detect_os)
        case $os in
            linux)
                wget -q "https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip" -O /tmp/android-tools.zip
                ;;
            macos)
                wget -q "https://dl.google.com/android/repository/commandlinetools-mac-9477386_latest.zip" -O /tmp/android-tools.zip
                ;;
            windows)
                wget -q "https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip" -O /tmp/android-tools.zip
                ;;
        esac
        
        unzip -q /tmp/android-tools.zip -d "$ANDROID_SDK_ROOT"
        mv "$ANDROID_SDK_ROOT/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools-latest"
        mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
        mv "$ANDROID_SDK_ROOT/cmdline-tools-latest" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        rm /tmp/android-tools.zip
    fi
    
    # Accept licenses
    yes | "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" --licenses > /dev/null 2>&1 || true
    
    # Install essential packages
    "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" \
        "platform-tools" \
        "platforms;android-34" \
        "build-tools;34.0.0" \
        "sources;android-34" > /dev/null 2>&1 || true
    
    print_success "Android SDK configured"
}

# Setup Flutter
setup_flutter() {
    print_step "Setting up Flutter..."
    
    if command_exists flutter; then
        FLUTTER_VERSION=$(flutter --version | head -1)
        print_success "Flutter already installed: $FLUTTER_VERSION"
        return 0
    fi
    
    # Install Flutter
    local os=$(detect_os)
    case $os in
        linux)
            # Download Flutter
            wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.10.0-stable.tar.xz" -O /tmp/flutter.tar.xz
            tar xf /tmp/flutter.tar.xz -C "$HOME"
            rm /tmp/flutter.tar.xz
            
            # Add to PATH
            echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> "$HOME/.bashrc"
            export PATH="$HOME/flutter/bin:$PATH"
            ;;
        macos)
            # Download Flutter
            wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.10.0-stable.zip" -O /tmp/flutter.zip
            unzip -q /tmp/flutter.zip -d "$HOME"
            rm /tmp/flutter.zip
            
            # Add to PATH
            echo "export PATH=\"\$HOME/flutter/bin:\$PATH\"" >> "$HOME/.zshrc"
            export PATH="$HOME/flutter/bin:$PATH"
            ;;
        windows)
            # Download Flutter
            wget -q "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.10.0-stable.zip" -O /tmp/flutter.zip
            unzip -q /tmp/flutter.zip -d "$HOME"
            rm /tmp/flutter.zip
            
            # Add to PATH via PowerShell
            powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';$HOME\flutter\bin', 'User')"
            export PATH="$HOME/flutter/bin:$PATH"
            ;;
    esac
    
    # Configure Flutter
    flutter config --no-analytics
    flutter doctor
    
    print_success "Flutter installed and configured"
}

# Setup Git hooks (optional)
setup_git_hooks() {
    print_step "Setting up Git hooks..."
    
    if [[ -d "$PROJECT_DIR/.git" ]]; then
        # Create pre-commit hook
        cat > "$PROJECT_DIR/.git/hooks/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for VaultNote
# Runs tests before committing

set -e

cd "$(git rev-parse --show-toplevel)"

# Run tests if they exist
if [[ -f "scripts/test.sh" ]]; then
    echo "Running tests before commit..."
    ./scripts/test.sh
fi

# Check for TODO/FIXME/HACK comments
if git diff --cached --name-only | xargs grep -l "TODO\|FIXME\|HACK" 2>/dev/null; then
    echo "Warning: Found TODO/FIXME/HACK comments in staged files"
    # Uncomment to make it fail:
    # exit 1
fi

echo "Pre-commit checks passed"
EOF
        
        chmod +x "$PROJECT_DIR/.git/hooks/pre-commit"
        print_success "Git hooks configured"
    else
        print_info "Not a Git repository, skipping hooks"
    fi
}

# Main setup function
main() {
    print_header "VaultNote Auto Setup"
    echo ""
    
    log "Starting setup process..."
    
    # Detect OS
    OS=$(detect_os)
    print_info "Detected OS: $OS"
    echo ""
    
    # Setup components
    setup_nodejs
    setup_npm_cache
    setup_pnpm
    setup_java
    setup_android_sdk
    setup_flutter
    setup_git_hooks
    
    echo ""
    print_header "Setup Complete"
    echo ""
    
    # Print summary
    print_info "Setup Summary:"
    echo -e "  Node.js: $(command_exists node && node --version || echo "Not installed")"
    echo -e "  npm: $(command_exists npm && npm --version || echo "Not installed")"
    echo -e "  pnpm: $(command_exists pnpm && pnpm --version || echo "Not installed")"
    echo -e "  Java: $(command_exists java && java -version 2>&1 | head -1 || echo "Not installed")"
    echo -e "  Flutter: $(command_exists flutter && flutter --version | head -1 || echo "Not installed")"
    echo -e "  Android SDK: [[ -d \"$ANDROID_SDK_ROOT\" ]] && echo \"Configured\" || echo \"Not configured\")"
    echo ""
    
    print_success "All dependencies installed successfully!"
    log "Setup completed successfully"
}

# Run main function
main "$@"