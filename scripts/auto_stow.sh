#!/bin/bash

# Auto-stow script
# Automatically stows all directories that contain a .config subfolder
# Usage: ./auto_stow.sh [OPTIONS]
# Options:
#   -d, --dry-run    Show what would be stowed without actually doing it
#   -u, --unstow     Unstow packages instead of stowing them
#   -v, --verbose    Show verbose output
#   -h, --help       Show this help message

set -euo pipefail

# Default options
DRY_RUN=false
UNSTOW=false
VERBOSE=false
FORCE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo "Auto-stow script - Automatically stows directories with .config subfolders"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --dry-run    Show what would be stowed without actually doing it"
    echo "  -u, --unstow     Unstow packages instead of stowing them"
    echo "  -v, --verbose    Show verbose output"
    echo "  -y, --yes        Skip confirmation prompt"
    echo "  -h, --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Stow all packages with .config folders"
    echo "  $0 -d                 # Dry run to see what would be stowed"
    echo "  $0 -u                 # Unstow all packages with .config folders"
    echo "  $0 -v                 # Verbose output"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -u|--unstow)
            UNSTOW=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -y|--yes)
            FORCE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}" >&2
            show_help
            exit 1
            ;;
    esac
done

# Function to log messages
log() {
    local level=$1
    shift
    case $level in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $*"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $*"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $*"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $*"
            ;;
    esac
}

# Check if stow is installed
if ! command -v stow &> /dev/null; then
    log "ERROR" "stow is not installed. Please install it first:"
    echo "  sudo pacman -S stow"
    exit 1
fi

# Change to dotfiles directory
cd "$DOTFILES_DIR"
log "INFO" "Working in directory: $DOTFILES_DIR"

# Find all directories with .config subfolders
packages_with_config=()
for dir in */; do
    # Remove trailing slash
    dir=${dir%/}
    
    # Skip if it's not a directory or if it's the scripts directory
    if [[ ! -d "$dir" ]] || [[ "$dir" == "scripts" ]] || [[ "$dir" == "docs" ]]; then
        continue
    fi
    
    # Check if it has a .config subfolder
    if [[ -d "$dir/.config" ]]; then
        packages_with_config+=("$dir")
        if [[ "$VERBOSE" == true ]]; then
            log "INFO" "Found package with .config: $dir"
        fi
    fi
done

# Check if any packages were found
if [[ ${#packages_with_config[@]} -eq 0 ]]; then
    log "WARNING" "No directories with .config subfolders found"
    exit 0
fi

# Show what will be processed
if [[ "$UNSTOW" == true ]]; then
    action="unstow"
    stow_flag="-D"
else
    action="stow"
    stow_flag=""
fi

if [[ "$DRY_RUN" == true ]]; then
    stow_flag="$stow_flag -n"
    log "INFO" "DRY RUN - The following packages would be ${action}ed:"
else
    log "INFO" "The following packages will be ${action}ed:"
fi

for package in "${packages_with_config[@]}"; do
    echo "  - $package"
done

echo ""

# Ask for confirmation if not a dry run
if [[ "$DRY_RUN" == false ]] && [[ "$FORCE" == false ]]; then
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "INFO" "Operation cancelled"
        exit 0
    fi
fi

# Process each package
success_count=0
error_count=0

for package in "${packages_with_config[@]}"; do
    log "INFO" "Processing $package..."
    
    # Build stow command
    stow_cmd="stow"
    if [[ "$stow_flag" != "" ]]; then
        stow_cmd="$stow_cmd $stow_flag"
    fi
    if [[ "$VERBOSE" == true ]]; then
        stow_cmd="$stow_cmd -v"
    fi
    stow_cmd="$stow_cmd $package"
    
    # Execute stow command
    if eval "$stow_cmd"; then
        if [[ "$DRY_RUN" == true ]]; then
            log "SUCCESS" "Would $action $package"
        else
            log "SUCCESS" "Successfully ${action}ed $package"
        fi
        success_count=$((success_count + 1))
    else
        log "ERROR" "Failed to $action $package"
        error_count=$((error_count + 1))
    fi
done

# Summary
echo ""
log "INFO" "Summary:"
log "SUCCESS" "$success_count packages processed successfully"
if [[ $error_count -gt 0 ]]; then
    log "ERROR" "$error_count packages failed"
    exit 1
else
    log "SUCCESS" "All packages processed successfully!"
fi
