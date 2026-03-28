#!/bin/bash

# VaultNote Environment Setup Script
# Configures environment variables by detecting existing installations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Get the vaultnote directory
# Scripts are at: /root/vaultnote/flutter/scripts/
# Flutter project is at: /root/vaultnote/flutter/
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_PROJECT_DIR="$(dirname "$SCRIPT_DIR")"  # /root/vaultnote/flutter

print_header "VaultNote Environment Configuration"
echo ""
print_info "Flutter project location: $FLUTTER_PROJECT_DIR"
echo ""

# Find Flutter
find_flutter() {
    # Method 1: Check if flutter command exists
    if command -v flutter &> /dev/null; then
        FLUTTER_BIN=$(which flutter)
        FLUTTER_HOME=$(dirname $(dirname "$FLUTTER_BIN"))
        print_success "Found Flutter: $FLUTTER_HOME"
        return 0
    fi
    
    # Method 2: Check common locations
    local locations=(
        "$HOME/flutter"
        "/opt/flutter"
        "/usr/local/flutter"
        "$HOME/.flutter"
    )
    
    for dir in "${locations[@]}"; do
        if [[ -f "$dir/bin/flutter" ]]; then
            FLUTTER_HOME="$dir"
            print_success "Found Flutter: $FLUTTER_HOME"
            return 0
        fi
    done
    
    print_info "Flutter not found in common locations"
    return 1
}

# Find Android SDK
find_android_sdk() {
    # Method 1: Check ANDROID_HOME environment variable
    if [[ -n "$ANDROID_HOME" && -d "$ANDROID_HOME" ]]; then
        print_success "ANDROID_HOME is set: $ANDROID_HOME"
        return 0
    fi
    
    # Method 2: Check ANDROID_SDK_ROOT
    if [[ -n "$ANDROID_SDK_ROOT" && -d "$ANDROID_SDK_ROOT" ]]; then
        ANDROID_HOME="$ANDROID_SDK_ROOT"
        print_success "Found Android SDK (ANDROID_SDK_ROOT): $ANDROID_HOME"
        return 0
    fi
    
    # Method 3: Check common locations
    local locations=(
        "$HOME/android-sdk"
        "$HOME/Android/Sdk"
        "$HOME/Library/Android/sdk"
        "/opt/android-sdk"
        "/usr/local/android-sdk"
    )
    
    for dir in "${locations[@]}"; do
        if [[ -d "$dir" ]]; then
            ANDROID_HOME="$dir"
            print_success "Found Android SDK: $ANDROID_HOME"
            return 0
        fi
    done
    
    # Method 4: Check inside Android Studio
    if [[ -d "$HOME/android-studio" ]]; then
        local studio_sdk="$HOME/Android/Sdk"
        if [[ -d "$studio_sdk" ]]; then
            ANDROID_HOME="$studio_sdk"
            print_success "Found Android SDK (from Android Studio): $ANDROID_HOME"
            return 0
        fi
    fi
    
    print_info "Android SDK not found"
    return 1
}

# Find Java
find_java() {
    # Method 1: Check JAVA_HOME
    if [[ -n "$JAVA_HOME" && -d "$JAVA_HOME" ]]; then
        print_success "JAVA_HOME is set: $JAVA_HOME"
        return 0
    fi
    
    # Method 2: Check java command
    if command -v java &> /dev/null; then
        JAVA_BIN=$(which java)
        # Try to resolve the actual Java home
        if [[ -L "$JAVA_BIN" ]]; then
            JAVA_REAL=$(readlink -f "$JAVA_BIN")
            JAVA_HOME=$(dirname $(dirname "$JAVA_REAL"))
        else
            # Fallback: check common locations
            local locations=(
                "/usr/lib/jvm/java-17-openjdk-amd64"
                "/usr/lib/jvm/java-17-openjdk"
                "/usr/lib/jvm/java-11-openjdk-amd64"
                "/usr/lib/jvm/default-java"
                "/usr"
            )
            for dir in "${locations[@]}"; do
                if [[ -f "$dir/bin/java" ]]; then
                    JAVA_HOME="$dir"
                    break
                fi
            done
        fi
        
        if [[ -n "$JAVA_HOME" ]]; then
            print_success "Found Java: $JAVA_HOME"
            return 0
        fi
    fi
    
    print_info "Java not found"
    return 1
}

# Detect shell config file
detect_shell_rc() {
    if [[ -n "$ZSH_VERSION" ]]; then
        SHELL_RC="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        if [[ -f "$HOME/.bashrc" ]]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.profile"
        fi
    else
        SHELL_RC="$HOME/.profile"
    fi
    
    # Create if doesn't exist
    if [[ ! -f "$SHELL_RC" ]]; then
        touch "$SHELL_RC"
    fi
    
    print_info "Using shell config: $SHELL_RC"
}

# Main configuration
configure_environment() {
    # Find all tools
    find_flutter || true
    find_android_sdk || true
    find_java || true
    
    echo ""
    
    # Create environment file
    ENV_FILE="$HOME/.vaultnote_env"
    print_info "Creating environment file: $ENV_FILE"
    
    cat > "$ENV_FILE" << EOF
# VaultNote Development Environment
# Generated: $(date)
# Source: $ENV_FILE

EOF

    # Add Flutter
    if [[ -n "$FLUTTER_HOME" ]]; then
        echo "export FLUTTER_HOME=\"$FLUTTER_HOME\"" >> "$ENV_FILE"
        echo "export PATH=\"\$PATH:\$FLUTTER_HOME/bin\"" >> "$ENV_FILE"
    fi
    
    # Add Android SDK
    if [[ -n "$ANDROID_HOME" ]]; then
        echo "export ANDROID_HOME=\"$ANDROID_HOME\"" >> "$ENV_FILE"
        echo "export ANDROID_SDK_ROOT=\"\$ANDROID_HOME\"" >> "$ENV_FILE"
        echo "export PATH=\"\$PATH:\$ANDROID_HOME/cmdline-tools/latest/bin:\$ANDROID_HOME/platform-tools\"" >> "$ENV_FILE"
    fi
    
    # Add Java
    if [[ -n "$JAVA_HOME" ]]; then
        echo "export JAVA_HOME=\"$JAVA_HOME\"" >> "$ENV_FILE"
    fi
    
    # Add Flutter settings
    cat >> "$ENV_FILE" << 'EOF'

# Flutter settings
export PUB_CACHE="$HOME/.pub-cache"
export FLUTTER_STORAGE_BASE_URL="https://storage.googleapis.com"
EOF
    
    print_success "Environment file created"
    
    # Add to shell config
    detect_shell_rc
    
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
    print_info "Creating aliases file: $ALIASES_FILE"
    
    cat > "$ALIASES_FILE" << EOF
# VaultNote Development Aliases
# Generated: $(date)

alias vn='cd $FLUTTER_PROJECT_DIR'
alias vn-build='$FLUTTER_PROJECT_DIR/scripts/build.sh'
alias vn-build-all='$FLUTTER_PROJECT_DIR/scripts/build_all.sh'
alias vn-debug='$FLUTTER_PROJECT_DIR/scripts/build_debug.sh'
alias vn-install='$FLUTTER_PROJECT_DIR/scripts/install.sh'
alias vn-verify='$FLUTTER_PROJECT_DIR/scripts/verify_release.sh'
alias vn-doctor='cd $FLUTTER_PROJECT_DIR && flutter doctor -v'
alias vn-clean='cd $FLUTTER_PROJECT_DIR && flutter clean && flutter pub get'
alias vn-setup='$FLUTTER_PROJECT_DIR/scripts/setup.sh'
EOF
    
    print_success "Aliases file created"
    
    # Add aliases to shell config
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
    
    # Create local.properties for Flutter project
    if [[ -n "$ANDROID_HOME" && -n "$FLUTTER_HOME" ]]; then
        LOCAL_PROPS="$FLUTTER_PROJECT_DIR/android/local.properties"
        cat > "$LOCAL_PROPS" << EOF
# VaultNote Android Configuration
# Generated: $(date)

sdk.dir=$ANDROID_HOME
flutter.sdk=$FLUTTER_HOME
flutter.buildMode=release
flutter.versionName=1.0.0
flutter.versionCode=1
EOF
        print_success "Created android/local.properties"
    fi
    
    echo ""
    print_header "Configuration Summary"
    echo ""
    
    if [[ -n "$FLUTTER_HOME" ]]; then
        print_success "Flutter: $FLUTTER_HOME"
    else
        print_info "Flutter: Not found (run ./scripts/setup.sh to install)"
    fi
    
    if [[ -n "$ANDROID_HOME" ]]; then
        print_success "Android SDK: $ANDROID_HOME"
    else
        print_info "Android SDK: Not found (run ./scripts/setup.sh to install)"
    fi
    
    if [[ -n "$JAVA_HOME" ]]; then
        print_success "Java: $JAVA_HOME"
    else
        print_info "Java: Not configured"
    fi
    
    echo ""
    print_info "VaultNote project: $FLUTTER_PROJECT_DIR"
    echo ""
    
    # Show available aliases
    print_info "Available aliases:"
    echo "  vn          - Navigate to VaultNote Flutter project"
    echo "  vn-build    - Build release APK"
    echo "  vn-build-all - Build all APK variants"
    echo "  vn-debug    - Quick debug build"
    echo "  vn-install  - Install on connected device"
    echo "  vn-verify   - Verify release build"
    echo "  vn-doctor   - Run flutter doctor"
    echo "  vn-clean    - Clean project and get dependencies"
    echo "  vn-setup    - Run setup script"
    echo ""
    
    print_header "Next Steps"
    echo ""
    print_info "1. Reload your shell configuration:"
    echo -e "   ${GREEN}source $SHELL_RC${NC}"
    echo ""
    print_info "2. Or start a new terminal session"
    echo ""
    print_info "3. Test the setup:"
    echo -e "   ${GREEN}vn${NC}           (navigate to project)"
    echo -e "   ${GREEN}flutter doctor${NC} (check Flutter installation)"
    echo ""
    
    print_success "Environment configuration complete!"
    echo ""
}

# Run configuration
configure_environment
