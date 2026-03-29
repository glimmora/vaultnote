#!/bin/bash

# VaultNote Flutter Cache Utility
# Manages Flutter dependencies caching to avoid re-downloading

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
FLUTTER_DIR="$PROJECT_DIR/flutter"
CACHE_DIR="$HOME/.vaultnote-cache/flutter"
PUB_CACHE="$HOME/.pub-cache"

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
VaultNote Flutter Cache Utility

Usage: $(basename "$0") [COMMAND] [OPTIONS]

Commands:
    save        Save Flutter dependencies to cache
    restore     Restore Flutter dependencies from cache
    clean       Clean Flutter cache
    status      Show cache status
    backup      Backup pub-cache to external location
    restore-backup  Restore pub-cache from backup

Options:
    -h, --help  Show this help message

Examples:
    $(basename "$0") save           # Save current dependencies to cache
    $(basename "$0") restore        # Restore dependencies from cache
    $(basename "$0") status         # Show cache status
    $(basename "$0") backup ~/backup # Backup pub-cache to ~/backup

EOF
}

# Create cache directory if it doesn't exist
init_cache() {
    mkdir -p "$CACHE_DIR"
    mkdir -p "$CACHE_DIR/pubspec"
    mkdir -p "$CACHE_DIR/pub-cache"
}

# Save Flutter dependencies to cache
save_cache() {
    print_header "Saving Flutter Cache"
    
    init_cache
    
    cd "$FLUTTER_DIR"
    
    # Save pubspec.lock
    if [[ -f "pubspec.lock" ]]; then
        cp pubspec.lock "$CACHE_DIR/pubspec/pubspec.lock.$(date +%Y%m%d_%H%M%S)"
        print_success "Saved pubspec.lock"
    fi
    
    # Save pubspec.yaml hash for comparison
    if [[ -f "pubspec.yaml" ]]; then
        sha256sum pubspec.yaml > "$CACHE_DIR/pubspec/pubspec.yaml.sha256"
        print_success "Saved pubspec.yaml hash"
    fi
    
    # Backup pub-cache if it exists
    if [[ -d "$PUB_CACHE" ]]; then
        print_step "Backing up pub-cache..."
        rsync -a --delete "$PUB_CACHE/" "$CACHE_DIR/pub-cache/" 2>/dev/null || \
        cp -r "$PUB_CACHE"/* "$CACHE_DIR/pub-cache/" 2>/dev/null || true
        print_success "Pub-cache backed up"
    fi
    
    # Save Flutter SDK version
    if command -v flutter &> /dev/null; then
        flutter --version | head -1 > "$CACHE_DIR/flutter-version.txt"
        print_success "Saved Flutter version"
    fi
    
    echo ""
    print_success "Flutter cache saved successfully"
    print_info "Cache location: $CACHE_DIR"
}

# Restore Flutter dependencies from cache
restore_cache() {
    print_header "Restoring Flutter Cache"
    
    if [[ ! -d "$CACHE_DIR" ]]; then
        print_error "No cache found. Run 'save' first."
        exit 1
    fi
    
    cd "$FLUTTER_DIR"
    
    # Check if pubspec.yaml has changed
    if [[ -f "pubspec.yaml" && -f "$CACHE_DIR/pubspec/pubspec.yaml.sha256" ]]; then
        CURRENT_HASH=$(sha256sum pubspec.yaml | cut -d' ' -f1)
        CACHED_HASH=$(cat "$CACHE_DIR/pubspec/pubspec.yaml.sha256" | cut -d' ' -f1)
        
        if [[ "$CURRENT_HASH" != "$CACHED_HASH" ]]; then
            print_info "pubspec.yaml has changed, cache may be outdated"
        fi
    fi
    
    # Restore pub-cache if backup exists
    if [[ -d "$CACHE_DIR/pub-cache" ]]; then
        print_step "Restoring pub-cache..."
        mkdir -p "$PUB_CACHE"
        rsync -a "$CACHE_DIR/pub-cache/" "$PUB_CACHE/" 2>/dev/null || \
        cp -r "$CACHE_DIR/pub-cache"/* "$PUB_CACHE/" 2>/dev/null || true
        print_success "Pub-cache restored"
    fi
    
    # Get dependencies (will use cached packages if available)
    print_step "Getting Flutter dependencies..."
    flutter pub get
    print_success "Dependencies restored"
    
    echo ""
    print_success "Flutter cache restored successfully"
}

# Clean Flutter cache
clean_cache() {
    print_header "Cleaning Flutter Cache"
    
    if [[ -d "$CACHE_DIR" ]]; then
        rm -rf "$CACHE_DIR"
        print_success "Cache cleaned"
    else
        print_info "No cache to clean"
    fi
    
    # Also clean Flutter's own cache
    if [[ -d "$FLUTTER_DIR/.dart_tool" ]]; then
        rm -rf "$FLUTTER_DIR/.dart_tool"
        print_success "Cleaned .dart_tool"
    fi
    
    if [[ -d "$FLUTTER_DIR/build" ]]; then
        rm -rf "$FLUTTER_DIR/build"
        print_success "Cleaned build directory"
    fi
    
    echo ""
    print_success "Flutter cache cleaned"
}

# Show cache status
show_status() {
    print_header "Flutter Cache Status"
    
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
    
    # Show pubspec versions
    if [[ -d "$CACHE_DIR/pubspec" ]]; then
        echo -e "${CYAN}Cached pubspec versions:${NC}"
        ls -1 "$CACHE_DIR/pubspec/" 2>/dev/null | head -5
    fi
    
    # Show Flutter version
    if [[ -f "$CACHE_DIR/flutter-version.txt" ]]; then
        echo -e "${CYAN}Cached Flutter Version:${NC}"
        cat "$CACHE_DIR/flutter-version.txt"
    fi
    
    # Show pub-cache size
    if [[ -d "$CACHE_DIR/pub-cache" ]]; then
        if command -v du &> /dev/null; then
            PUB_CACHE_SIZE=$(du -sh "$CACHE_DIR/pub-cache" 2>/dev/null | cut -f1)
            echo -e "${CYAN}Pub-cache Size:${NC} $PUB_CACHE_SIZE"
        fi
    fi
    
    echo ""
}

# Backup pub-cache to external location
backup_cache() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") backup <directory>"
        exit 1
    fi
    
    print_header "Backing Up Pub-Cache"
    
    mkdir -p "$BACKUP_DIR"
    
    if [[ -d "$PUB_CACHE" ]]; then
        print_step "Backing up pub-cache to $BACKUP_DIR..."
        rsync -a "$PUB_CACHE/" "$BACKUP_DIR/pub-cache/" 2>/dev/null || \
        cp -r "$PUB_CACHE"/* "$BACKUP_DIR/pub-cache/" 2>/dev/null || true
        print_success "Pub-cache backed up to $BACKUP_DIR/pub-cache"
    else
        print_error "Pub-cache not found at $PUB_CACHE"
        exit 1
    fi
    
    # Save metadata
    if command -v flutter &> /dev/null; then
        flutter --version | head -1 > "$BACKUP_DIR/flutter-version.txt"
    fi
    
    echo ""
    print_success "Backup completed"
}

# Restore pub-cache from backup
restore_backup() {
    local BACKUP_DIR="$1"
    
    if [[ -z "$BACKUP_DIR" ]]; then
        print_error "Please specify backup directory"
        echo "Usage: $(basename "$0") restore-backup <directory>"
        exit 1
    fi
    
    print_header "Restoring Pub-Cache from Backup"
    
    if [[ ! -d "$BACKUP_DIR/pub-cache" ]]; then
        print_error "Backup not found at $BACKUP_DIR/pub-cache"
        exit 1
    fi
    
    print_step "Restoring pub-cache from $BACKUP_DIR..."
    mkdir -p "$PUB_CACHE"
    rsync -a "$BACKUP_DIR/pub-cache/" "$PUB_CACHE/" 2>/dev/null || \
    cp -r "$BACKUP_DIR/pub-cache"/* "$PUB_CACHE/" 2>/dev/null || true
    print_success "Pub-cache restored from $BACKUP_DIR/pub-cache"
    
    echo ""
    print_success "Restore completed"
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
    -h|--help)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac