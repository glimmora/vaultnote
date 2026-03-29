#!/bin/bash

# VaultNote Cache Manager
# Unified cache management for Flutter and Node.js dependencies

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$PROJECT_DIR/scripts"
CACHE_BASE_DIR="$HOME/.vaultnote-cache"

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
VaultNote Cache Manager

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    save-all        Save all caches (Flutter + Node.js)
    restore-all     Restore all caches (Flutter + Node.js)
    clean-all       Clean all caches
    status          Show status of all caches
    backup-all      Backup all caches to external location
    restore-all-backup  Restore all caches from backup
    init            Initialize cache directories
    optimize        Optimize all cache settings

Options:
    -h, --help      Show this help message

Examples:
    $(basename "$0") save-all       # Save all caches
    $(basename "$0") restore-all    # Restore all caches
    $(basename "$0") status         # Show all cache status
    $(basename "$0") backup-all ~/backup # Backup all caches
    $(basename "$0") init           # Initialize cache directories

EOF
}

# Initialize cache directories
init_caches() {
    print_header "Initializing Cache Directories"
    
    mkdir -p "$CACHE_BASE_DIR"
    mkdir -p "$CACHE_BASE_DIR/flutter"
    mkdir -p "$CACHE_BASE_DIR/node"
    
    print_success "Cache directories initialized"
    print_info "Cache location: $CACHE_BASE_DIR"
}

# Save all caches
save_all() {
    print_header "Saving All Caches"
    
    # Save Flutter cache
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Saving Flutter cache..."
        "$SCRIPTS_DIR/flutter-cache.sh" save
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Save Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Saving Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" save
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    print_success "All caches saved"
}

# Restore all caches
restore_all() {
    print_header "Restoring All Caches"
    
    # Restore Flutter cache
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Restoring Flutter cache..."
        "$SCRIPTS_DIR/flutter-cache.sh" restore
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Restore Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Restoring Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" restore
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    print_success "All caches restored"
}

# Clean all caches
clean_all() {
    print_header "Cleaning All Caches"
    
    # Clean Flutter cache
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Cleaning Flutter cache..."
        "$SCRIPTS_DIR/flutter-cache.sh" clean
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Clean Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Cleaning Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" clean
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    
    # Clean base cache directory
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        rm -rf "$CACHE_BASE_DIR"
        print_success "Base cache directory cleaned"
    fi
    
    echo ""
    print_success "All caches cleaned"
}

# Show status of all caches
show_status() {
    print_header "Cache Status Overview"
    
    echo -e "${CYAN}Cache Base Directory:${NC} $CACHE_BASE_DIR"
    echo ""
    
    # Show Flutter cache status
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Flutter Cache Status:"
        "$SCRIPTS_DIR/flutter-cache.sh" status
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Show Node.js cache status
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Node.js Cache Status:"
        "$SCRIPTS_DIR/node-cache.sh" status
    else
        print_error "Node.js cache script not found"
    fi
    
    # Show total cache size
    if [[ -d "$CACHE_BASE_DIR" ]]; then
        if command -v du &> /dev/null; then
            TOTAL_SIZE=$(du -sh "$CACHE_BASE_DIR" 2>/dev/null | cut -f1)
            echo -e "${CYAN}Total Cache Size:${NC} $TOTAL_SIZE"
        fi
    fi
    
    echo ""
}

# Backup all caches to external location
backup_all() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") backup-all <directory>"
        exit 1
    fi
    
    print_header "Backing Up All Caches"
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup Flutter cache
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Backing up Flutter cache..."
        "$SCRIPTS_DIR/flutter-cache.sh" backup "$BACKUP_DIR/flutter"
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Backup Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Backing up Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" backup "$BACKUP_DIR/node"
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    print_success "All caches backed up to $BACKUP_DIR"
}

# Restore all caches from backup
restore_all_backup() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") restore-all-backup <directory>"
        exit 1
    fi
    
    print_header "Restoring All Caches from Backup"
    
    # Restore Flutter cache
    if [[ -f "$SCRIPTS_DIR/flutter-cache.sh" ]]; then
        print_step "Restoring Flutter cache..."
        "$SCRIPTS_DIR/flutter-cache.sh" restore-backup "$BACKUP_DIR/flutter"
    else
        print_error "Flutter cache script not found"
    fi
    
    echo ""
    
    # Restore Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Restoring Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" restore-backup "$BACKUP_DIR/node"
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    print_success "All caches restored from $BACKUP_DIR"
}

# Optimize all cache settings
optimize_all() {
    print_header "Optimizing All Cache Settings"
    
    # Optimize Node.js cache
    if [[ -f "$SCRIPTS_DIR/node-cache.sh" ]]; then
        print_step "Optimizing Node.js cache..."
        "$SCRIPTS_DIR/node-cache.sh" optimize
    else
        print_error "Node.js cache script not found"
    fi
    
    echo ""
    
    # Set up cache environment variables
    print_step "Setting up cache environment variables..."
    
    # Create environment file if it doesn't exist
    ENV_FILE="$HOME/.vaultnote_env"
    if [[ ! -f "$ENV_FILE" ]]; then
        cat > "$ENV_FILE" << EOF
# VaultNote Cache Environment Variables
export VAULTNOTE_CACHE_DIR="$CACHE_BASE_DIR"
export PUB_CACHE="$HOME/.pub-cache"
export npm_config_cache="$HOME/.npm"
EOF
        print_success "Environment file created at $ENV_FILE"
    else
        print_info "Environment file already exists at $ENV_FILE"
    fi
    
    echo ""
    print_success "All cache settings optimized"
}

# Main
case "${1:-}" in
    save-all)
        save_all
        ;;
    restore-all)
        restore_all
        ;;
    clean-all)
        clean_all
        ;;
    status)
        show_status
        ;;
    backup-all)
        backup_all "$2"
        ;;
    restore-all-backup)
        restore_all_backup "$2"
        ;;
    init)
        init_caches
        ;;
    optimize)
        optimize_all
        ;;
    -h|--help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac