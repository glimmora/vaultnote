#!/bin/bash

# VaultNote Node.js Cache Utility
# Manages Node.js dependencies caching to avoid re-downloading

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
WEB_DIR="$PROJECT_DIR/web"
CACHE_DIR="$HOME/.vaultnote-cache/node"
NPM_CACHE="$HOME/.npm"

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
VaultNote Node.js Cache Utility

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    save        Save Node.js dependencies to cache
    restore     Restore Node.js dependencies from cache
    clean       Clean Node.js cache
    status      Show cache status
    backup      Backup npm cache to external location
    restore-backup  Restore npm cache from backup
    optimize    Optimize npm cache settings

Options:
    -h, --help  Show this help message

Examples:
    $(basename "$0") save           # Save current dependencies to cache
    $(basename "$0") restore        # Restore dependencies from cache
    $(basename "$0") status         # Show cache status
    $(basename "$0") backup ~/backup # Backup npm cache to ~/backup
    $(basename "$0") optimize       # Optimize npm cache settings

EOF
}

# Create cache directory if it doesn't exist
init_cache() {
    mkdir -p "$CACHE_DIR"
    mkdir -p "$CACHE_DIR/package"
    mkdir -p "$CACHE_DIR/npm-cache"
}

# Save Node.js dependencies to cache
save_cache() {
    print_header "Saving Node.js Cache"
    
    init_cache
    
    cd "$WEB_DIR"
    
    # Save package-lock.json
    if [[ -f "package-lock.json" ]]; then
        cp package-lock.json "$CACHE_DIR/package/package-lock.json.$(date +%Y%m%d_%H%M%S)"
        print_success "Saved package-lock.json"
    fi
    
    # Save package.json hash for comparison
    if [[ -f "package.json" ]]; then
        sha256sum package.json > "$CACHE_DIR/package/package.json.sha256"
        print_success "Saved package.json hash"
    fi
    
    # Backup npm cache if it exists
    if [[ -d "$NPM_CACHE" ]]; then
        print_step "Backing up npm cache..."
        rsync -a --delete "$NPM_CACHE/" "$CACHE_DIR/npm-cache/" 2>/dev/null || \
        cp -r "$NPM_CACHE"/* "$CACHE_DIR/npm-cache/" 2>/dev/null || true
        print_success "Npm cache backed up"
    fi
    
    # Save Node.js version
    if command -v node &> /dev/null; then
        node --version > "$CACHE_DIR/node-version.txt"
        print_success "Saved Node.js version"
    fi
    
    # Save npm version
    if command -v npm &> /dev/null; then
        npm --version > "$CACHE_DIR/npm-version.txt"
        print_success "Saved npm version"
    fi
    
    echo ""
    print_success "Node.js cache saved successfully"
    print_info "Cache location: $CACHE_DIR"
}

# Restore Node.js dependencies from cache
restore_cache() {
    print_header "Restoring Node.js Cache"
    
    if [[ ! -d "$CACHE_DIR" ]]; then
        print_error "No cache found. Run 'save' first."
        exit 1
    fi
    
    cd "$WEB_DIR"
    
    # Check if package.json has changed
    if [[ -f "package.json" && -f "$CACHE_DIR/package/package.json.sha256" ]]; then
        CURRENT_HASH=$(sha256sum package.json | cut -d' ' -f1)
        CACHED_HASH=$(cat "$CACHE_DIR/package/package.json.sha256" | cut -d' ' -f1)
        
        if [[ "$CURRENT_HASH" != "$CACHED_HASH" ]]; then
            print_info "package.json has changed, cache may be outdated"
        fi
    fi
    
    # Restore npm cache if backup exists
    if [[ -d "$CACHE_DIR/npm-cache" ]]; then
        print_step "Restoring npm cache..."
        mkdir -p "$NPM_CACHE"
        rsync -a "$CACHE_DIR/npm-cache/" "$NPM_CACHE/" 2>/dev/null || \
        cp -r "$CACHE_DIR/npm-cache"/* "$NPM_CACHE/" 2>/dev/null || true
        print_success "Npm cache restored"
    fi
    
    # Install dependencies (will use cached packages if available)
    print_step "Installing Node.js dependencies..."
    npm install
    print_success "Dependencies restored"
    
    echo ""
    print_success "Node.js cache restored successfully"
}

# Clean Node.js cache
clean_cache() {
    print_header "Cleaning Node.js Cache"
    
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        print_success "Cache cleaned"
    else
        print_info "No cache to clean"
    fi
    
    # Also clean node_modules
    if [[ -d "$WEB_DIR/node_modules" ]]; then
        rm -rf "$WEB_DIR/node_modules"
        print_success "Cleaned node_modules"
    fi
    
    # Clean package-lock.json
    if [[ -f "$WEB_DIR/package-lock.json" ]]; then
        rm "$WEB_DIR/package-lock.json"
        print_success "Cleaned package-lock.json"
    fi
    
    # Clean npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
        print_success "Cleaned npm cache"
    fi
    
    echo ""
    print_success "Node.js cache cleaned"
}

# Show cache status
show_status() {
    print_header "Node.js Cache Status"
    
    if [[ ! -d "$CACHE_DIR" ]]; then
        print_info "No cache found"
        return
    fi
    
    echo -e "${CYAN}Cache Location:${NC} $CACHE_DIR"
    echo ""
    
    # Show cache size
    if command -v du &> /dev/null; then
        CACHE_SIZE=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        echo -e "${CYAN}Cache Size:${NC} $CACHE_SIZE"
    fi
    
    # Show package versions
    if [[ -d "$CACHE_DIR/package" ]]; then
        echo -e "${CYAN}Cached package versions:${NC}"
        ls -1 "$CACHE_DIR/package/" 2>/dev/null | head -5
    fi
    
    # Show Node.js version
    if [[ -f "$CACHE_DIR/node-version.txt" ]]; then
        echo -e "${CYAN}Cached Node.js Version:${NC}"
        cat "$CACHE_DIR/node-version.txt"
    fi
    
    # Show npm version
    if [[ -f "$CACHE_DIR/npm-version.txt" ]]; then
        echo -e "${CYAN}Cached npm Version:${NC}"
        cat "$CACHE_DIR/npm-version.txt"
    fi
    
    # Show npm cache size
    if [[ -d "$CACHE_DIR/npm-cache" ]]; then
        if command -v du &> /dev/null; then
            NPM_CACHE_SIZE=$(du -sh "$CACHE_DIR/npm-cache" 2>/dev/null | cut -f1)
            echo -e "${CYAN}Npm-cache Size:${NC} $NPM_CACHE_SIZE"
        fi
    fi
    
    echo ""
}

# Backup npm cache to external location
backup_cache() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") backup <directory>"
        exit 1
    fi
    
    print_header "Backing Up Npm Cache"
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$NPM_CACHE" ]]; then
        print_step "Backing up npm cache to $BACKUP_DIR..."
        rsync -a "$NPM_CACHE/" "$BACKUP_DIR/npm-cache/" 2>/dev/null || \
        cp -r "$NPM_CACHE"/* "$BACKUP_DIR/npm-cache/" 2>/dev/null || true
        print_success "Npm cache backed up to $BACKUP_DIR/npm-cache"
    else
        print_error "Npm cache not found at $NPM_CACHE"
        exit 1
    fi
    
    # Save metadata
    if command -v node &> /dev/null; then
        node --version > "$BACKUP_DIR/node-version.txt"
    fi
    
    if command -v npm &> /dev/null; then
        npm --version > "$BACKUP_DIR/npm-version.txt"
    fi
    
    echo ""
    print_success "Backup completed"
}

# Restore npm cache from backup
restore_backup() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") restore-backup <directory>"
        exit 1
    fi
    
    print_header "Restoring Npm Cache from Backup"
    
    if [[ ! -d "$BACKUP_DIR/npm-cache" ]]; then
        print_error "Backup not found at $BACKUP_DIR/npm-cache"
        exit 1
    fi
    
    print_step "Restoring npm cache from $BACKUP_DIR..."
    mkdir -p "$NPM_CACHE"
    rsync -a "$BACKUP_DIR/npm-cache/" "$NPM_CACHE/" 2>/dev/null || \
    cp -r "$BACKUP_DIR/npm-cache"/* "$NPM_CACHE/" 2>/dev/null || true
    print_success "Npm cache restored from $BACKUP_DIR/npm-cache"
    
    echo ""
    print_success "Restore completed"
}

# Optimize npm cache settings
optimize_cache() {
    print_header "Optimizing Npm Cache"
    
    if ! command -v npm &> /dev/null; then
        print_error "npm not found"
        exit 1
    fi
    
    # Set npm cache location
    print_step "Setting npm cache location..."
    npm config set cache "$NPM_CACHE"
    print_success "Npm cache location set to $NPM_CACHE"
    
    # Enable npm cache
    print_step "Enabling npm cache..."
    npm config set cache-min 86400
    npm config set cache-max 604800
    print_success "Npm cache enabled"
    
    # Set npm registry
    print_step "Setting npm registry..."
    npm config set registry https://registry.npmjs.org/
    print_success "Npm registry set"
    
    # Enable npm audit
    print_step "Enabling npm audit..."
    npm config set audit true
    print_success "Npm audit enabled"
    
    echo ""
    print_success "Npm cache optimized"
}

# Main
case "${1:-}" in
    save)
        save_cache
        ;;
    restore)
        restore_cache
        ;;
    clean)
        clean_cache
        ;;
    status)
        show_status
        ;;
    backup)
        backup_cache "$2"
        ;;
    restore-backup)
        restore_backup "$2"
        ;;
    optimize)
        optimize_cache
        ;;
    -h|--help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac