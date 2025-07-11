#!/bin/bash
set -e

DOTFILES_DIR="$HOME/mydotfiles"
REPO_URL="https://github.com/gsenden/dotfiles.git"

# Export DOTFILES_DIR so all scripts can use it
export DOTFILES_DIR

echo "🚀 Starting setup..."

# Handle dotfiles directory
if [ ! -d "$DOTFILES_DIR" ]; then
    echo "📁 Cloning dotfiles repository..."
    git clone "$REPO_URL" "$DOTFILES_DIR"
elif [ -d "$DOTFILES_DIR/.git" ]; then
    echo "📁 Updating existing dotfiles..."
    cd "$DOTFILES_DIR"
    git pull origin main
else
    echo "⚠️  Dotfiles directory exists but is not a git repo"
    echo "Please remove $DOTFILES_DIR or fix manually"
    exit 1
fi

cd "$DOTFILES_DIR"

# Run bootstrap (should be idempotent)
echo "🏗️  Running bootstrap..."
if command -v pacman >/dev/null 2>&1; then
    echo "📦 Detected Arch based distro"
    DOTFILES_DIR="$DOTFILES_DIR" ./arch/arch.sh
else
    echo "❌ Unsupported distribution"
    exit 1
fi

# Setup dotfiles with Stow (handles conflicts gracefully)
# echo "🔗 Setting up dotfiles with Stow..."
# for dir in vim bash git; do
#     if [ -d "$dir" ]; then
#         echo "  📄 Stowing $dir..."
#         stow --restow "$dir" 2>/dev/null || {
#             echo "  ⚠️  Conflict with $dir, use 'stow --adopt $dir' to resolve"
#         }
#     fi
# done

echo "✅ Setup complete!"
echo "💡 Rerun anytime to update your configuration"