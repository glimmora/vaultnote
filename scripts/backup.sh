#!/bin/bash

# =============================================================================
# VaultNote Backup Script
# =============================================================================
# Creates a compressed zip archive of the entire project directory.
# Excludes cache/temporary directories while explicitly including build outputs.
# Calculates build output size and optionally pushes size info to GitHub.
# =============================================================================

# Exit immediately on error, treat unset variables as errors, and catch
# failures in piped commands so every failure is handled gracefully.
set -euo pipefail

# -----------------------------------------------------------------------------
# Color definitions for terminal output
# -----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# -----------------------------------------------------------------------------
# Project paths
# Derive the project root from the script's location so the script works
# regardless of the caller's working directory.
# -----------------------------------------------------------------------------
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPTS_DIR")"

# Build output directories to include in the archive and measure
BUILD_DIRS=("dist" "build" "build-output" "web/dist" "flutter/build")

# -----------------------------------------------------------------------------
# Helper functions for consistent, colored terminal output
# -----------------------------------------------------------------------------
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}[OK] $1${NC}"
}

print_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

print_info() {
    echo -e "${YELLOW}[INFO] $1${NC}"
}

print_step() {
    echo -e "${CYAN}[STEP] $1${NC}"
}

# -----------------------------------------------------------------------------
# Cleanup handler: remove temporary files on exit, interrupt, or error
# -----------------------------------------------------------------------------
TEMP_FILE=""
cleanup() {
    if [[ -n "$TEMP_FILE" && -f "$TEMP_FILE" ]]; then
        rm -f "$TEMP_FILE"
    fi
}
trap cleanup EXIT

# -----------------------------------------------------------------------------
# Validate prerequisites — ensure zip and git are available
# -----------------------------------------------------------------------------
check_prerequisites() {
    print_step "Checking prerequisites..."

    if ! command -v zip &> /dev/null; then
        print_error "'zip' is not installed. Install it with: sudo apt install zip"
        exit 1
    fi
    print_success "zip is available"

    if ! command -v git &> /dev/null; then
        print_error "'git' is not installed. Git integration will be skipped."
        HAS_GIT=false
    else
        HAS_GIT=true
        print_success "git is available"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Prompt the user for the backup destination directory.
# Falls back to ~/vaultnote-backups if the user provides no input.
# -----------------------------------------------------------------------------
prompt_destination() {
    print_step "Selecting backup destination..."

    local default_dest="$HOME/vaultnote-backups"
    read -rp "Enter backup destination path [${default_dest}]: " BACKUP_DEST

    # Use default when the user presses Enter without typing a path
    BACKUP_DEST="${BACKUP_DEST:-$default_dest}"

    # Create the destination directory if it does not exist
    if [[ ! -d "$BACKUP_DEST" ]]; then
        print_info "Directory '$BACKUP_DEST' does not exist. Creating it..."
        if ! mkdir -p "$BACKUP_DEST"; then
            print_error "Failed to create directory: $BACKUP_DEST"
            exit 1
        fi
        print_success "Created directory: $BACKUP_DEST"
    fi

    # Verify the destination is writable
    if [[ ! -w "$BACKUP_DEST" ]]; then
        print_error "No write permission for: $BACKUP_DEST"
        exit 1
    fi

    print_success "Backup destination: $BACKUP_DEST"
    echo ""
}

# -----------------------------------------------------------------------------
# Calculate and display the total size of all existing build output directories.
# Returns the human-readable size via the global BUILD_OUTPUT_SIZE variable.
# -----------------------------------------------------------------------------
calculate_build_size() {
    print_step "Calculating build output size..."

    local total_bytes=0
    local found_dirs=()

    for dir in "${BUILD_DIRS[@]}"; do
        local full_path="$PROJECT_DIR/$dir"
        if [[ -d "$full_path" ]]; then
            local dir_size
            dir_size=$(du -sb "$full_path" 2>/dev/null | cut -f1)
            total_bytes=$((total_bytes + dir_size))
            found_dirs+=("$dir")
            print_info "  $dir: $(numfmt --to=iec-i "$dir_size" 2>/dev/null || echo "${dir_size} bytes")"
        fi
    done

    if [[ ${#found_dirs[@]} -eq 0 ]]; then
        print_info "No build output directories found."
        BUILD_OUTPUT_SIZE="0 B"
        BUILD_OUTPUT_BYTES=0
    else
        BUILD_OUTPUT_SIZE="$(numfmt --to=iec-i "$total_bytes" 2>/dev/null || echo "${total_bytes} bytes")"
        BUILD_OUTPUT_BYTES=$total_bytes
        print_success "Total build output size: $BUILD_OUTPUT_SIZE"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Remove build-output directories from .gitignore so they can be tracked.
# Creates a backup of .gitignore before making changes.
# -----------------------------------------------------------------------------
ensure_build_dirs_tracked() {
    if [[ "$HAS_GIT" != true ]]; then
        print_info "Git not available — skipping .gitignore update."
        return
    fi

    local gitignore="$PROJECT_DIR/.gitignore"
    if [[ ! -f "$gitignore" ]]; then
        print_info "No .gitignore found — nothing to update."
        return
    fi

    print_step "Ensuring build directories are not ignored by git..."

    # Build a list of gitignore patterns that would exclude build directories
    local patterns_to_remove=("build/" "dist/" "build-output/")
    local modified=false

    # Back up the original .gitignore
    cp "$gitignore" "${gitignore}.bak"

    for pattern in "${patterns_to_remove[@]}"; do
        if grep -qxF "$pattern" "$gitignore"; then
            # Remove the exact matching line
            sed -i "\|^${pattern}$|d" "$gitignore"
            print_info "Removed '$pattern' from .gitignore"
            modified=true
        fi
    done

    if [[ "$modified" == true ]]; then
        print_success ".gitignore updated (backup at .gitignore.bak)"
    else
        # No changes needed — remove the unnecessary backup
        rm -f "${gitignore}.bak"
        print_success "Build directories already tracked by git"
    fi
    echo ""
}

# -----------------------------------------------------------------------------
# Create the zip archive, excluding cache and temporary directories while
# explicitly including build output directories.
# -----------------------------------------------------------------------------
create_backup_archive() {
    print_header "Creating Backup Archive"

    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local archive_name="vaultnote-backup-${timestamp}.zip"
    local archive_path="${BACKUP_DEST}/${archive_name}"

    print_step "Preparing file list..."

    # ------------------------------------------------------------------
    # Directories and patterns to EXCLUDE from the archive.
    # Each -x flag is passed to zip to skip matching paths.
    # ------------------------------------------------------------------
    local exclude_patterns=(
        "*/node_modules/*"
        "*/.git/*"
        "*/.dart_tool/*"
        "*/.pnpm-store/*"
        "*/.cache/*"
        "*/.npm/*"
        "*/.gradle/*"
        "*/tmp/*"
        "*/temp/*"
        "*/.vscode/*"
        "*/.idea/*"
        "*/coverage/*"
        "*/.sass-cache/*"
        "*/ios/Pods/*"
        "*.tmp"
        "*.temp"
        "*.log"
        "*.swp"
        "*.swo"
        ".DS_Store"
        "Thumbs.db"
    )

    print_info "Excluding cache and temporary directories:"
    for p in "${exclude_patterns[@]}"; do
        echo -e "    ${RED}-${NC} $p"
    done
    echo ""

    # ------------------------------------------------------------------
    # Build the zip command.
    # -r  : recurse into directories
    # -9  : maximum compression
    # -x  : exclude patterns (applied per file path)
    # ------------------------------------------------------------------
    print_step "Compressing project directory..."
    print_info "Source: $PROJECT_DIR"
    print_info "Destination: $archive_path"

    # Build the exclude argument array
    local exclude_args=()
    for p in "${exclude_patterns[@]}"; do
        exclude_args+=(-x "$p")
    done

    # Change to the project root so archive paths are relative
    if cd "$PROJECT_DIR"; then
        # Temporarily disable exit-on-error so we can handle zip failures
        set +e
        zip -r -9 "$archive_path" . "${exclude_args[@]}" > /dev/null 2>&1
        local zip_status=$?
        set -e

        if [[ $zip_status -ne 0 ]]; then
            print_error "zip command failed with exit code $zip_status"
            exit 1
        fi
    else
        print_error "Failed to change to project directory: $PROJECT_DIR"
        exit 1
    fi

    # Verify the archive was actually created and is not empty
    if [[ ! -f "$archive_path" ]]; then
        print_error "Backup archive was not created: $archive_path"
        exit 1
    fi

    local archive_size
    archive_size=$(du -h "$archive_path" | cut -f1)
    print_success "Archive created successfully"
    print_info "File: $archive_path"
    print_info "Size: $archive_size"
    echo ""

    # Store for the summary
    ARCHIVE_PATH="$archive_path"
    ARCHIVE_SIZE="$archive_size"
}

# -----------------------------------------------------------------------------
# Write a build-size metadata file and optionally commit + push it to GitHub.
# -----------------------------------------------------------------------------
push_build_size_to_github() {
    print_header "GitHub Build Size Integration"

    if [[ "$HAS_GIT" != true ]]; then
        print_info "Git not available — skipping GitHub push."
        return
    fi

    # Verify the project directory is a git repository
    if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &> /dev/null; then
        print_info "Project is not a git repository — skipping GitHub push."
        return
    fi

    # Verify a remote named 'origin' exists
    if ! git -C "$PROJECT_DIR" remote get-url origin &> /dev/null; then
        print_info "No 'origin' remote configured — skipping GitHub push."
        return
    fi

    print_step "Generating build size metadata..."

    # Create a JSON metadata file with build size information
    local metadata_file="$PROJECT_DIR/build-size.json"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Collect per-directory sizes
    local dir_sizes_json=""
    for dir in "${BUILD_DIRS[@]}"; do
        local full_path="$PROJECT_DIR/$dir"
        if [[ -d "$full_path" ]]; then
            local dir_bytes
            dir_bytes=$(du -sb "$full_path" 2>/dev/null | cut -f1)
            local dir_human
            dir_human=$(numfmt --to=iec-i "$dir_bytes" 2>/dev/null || echo "${dir_bytes} bytes")
            # Normalize path: replace / with _ for JSON key
            local key
            key=$(echo "$dir" | tr '/' '_')
            dir_sizes_json="${dir_sizes_json}    \"${key}\": {\"bytes\": ${dir_bytes}, \"human\": \"${dir_human}\"},\n"
        fi
    done

    # Remove trailing comma from last entry
    dir_sizes_json=$(echo -e "$dir_sizes_json" | sed '$ s/,$//')

    cat > "$metadata_file" << EOF
{
  "timestamp": "${timestamp}",
  "total_build_bytes": ${BUILD_OUTPUT_BYTES:-0},
  "total_build_human": "${BUILD_OUTPUT_SIZE:-0 B}",
  "directories": {
${dir_sizes_json}
  }
}
EOF

    print_success "Build size metadata written to: build-size.json"
    cat "$metadata_file"
    echo ""

    # Attempt to commit and push the metadata file
    print_step "Attempting to push build size to GitHub..."

    # Save current branch so we can restore it if needed
    local current_branch
    current_branch=$(git -C "$PROJECT_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)

    # Stash any uncommitted changes to avoid accidental commits
    local stashed=false
    if ! git -C "$PROJECT_DIR" diff --quiet 2>/dev/null || \
       ! git -C "$PROJECT_DIR" diff --cached --quiet 2>/dev/null; then
        git -C "$PROJECT_DIR" stash push -q -m "backup-script-stash" -- build-size.json .gitignore 2>/dev/null || true
        stashed=true
    fi

    set +e

    # Add, commit, and push the metadata file
    git -C "$PROJECT_DIR" add build-size.json
    git -C "$PROJECT_DIR" commit -q -m "chore: update build size metadata [skip ci]" -- build-size.json 2>/dev/null
    local commit_status=$?

    if [[ $commit_status -eq 0 ]]; then
        git -C "$PROJECT_DIR" push -q origin "$current_branch" 2>/dev/null
        local push_status=$?

        if [[ $push_status -eq 0 ]]; then
            print_success "Build size metadata pushed to GitHub (branch: $current_branch)"
        else
            print_info "Push failed — the commit was created locally but could not be pushed."
            print_info "You can push manually later with: git push origin $current_branch"
        fi
    else
        print_info "No changes to commit (build-size.json is unchanged)."
    fi

    set -e

    # Restore stashed changes if we stashed anything
    if [[ "$stashed" == true ]]; then
        git -C "$PROJECT_DIR" stash pop -q 2>/dev/null || true
    fi

    echo ""
}

# -----------------------------------------------------------------------------
# Print a summary of the completed backup operation
# -----------------------------------------------------------------------------
print_summary() {
    print_header "Backup Summary"
    echo ""
    echo -e "${CYAN}Archive:${NC}"
    echo -e "  Path: ${ARCHIVE_PATH}"
    echo -e "  Size: ${ARCHIVE_SIZE}"
    echo ""
    echo -e "${CYAN}Build Output:${NC}"
    echo -e "  Total Size: ${BUILD_OUTPUT_SIZE}"
    echo ""
    echo -e "${CYAN}Included Build Directories:${NC}"
    for dir in "${BUILD_DIRS[@]}"; do
        if [[ -d "$PROJECT_DIR/$dir" ]]; then
            echo -e "  ${GREEN}✓${NC} $dir"
        else
            echo -e "  ${YELLOW}—${NC} $dir (not present)"
        fi
    done
    echo ""
    print_success "Backup completed successfully!"
    echo ""
}

# =============================================================================
# Main execution flow
# =============================================================================
main() {
    print_header "VaultNote Backup Script"
    echo ""

    # Step 1 — Validate environment
    check_prerequisites

    # Step 2 — Ask where to save the backup
    prompt_destination

    # Step 3 — Measure build output size
    calculate_build_size

    # Step 4 — Ensure build directories are tracked by git
    ensure_build_dirs_tracked

    # Step 5 — Create the zip archive
    create_backup_archive

    # Step 6 — Push build size metadata to GitHub (best-effort)
    push_build_size_to_github

    # Step 7 — Display final summary
    print_summary
}

# Run the main function
main
