#!/bin/bash
set -e

echo "🔧 Starting Arch system bootstrap..."

# Ensure cleanup happens even on script exit
trap 'rm -rf /tmp/yay' EXIT

echo "🏗️  EndeavourOS/Arch system bootstrap..."

# DOTFILES_DIR is set by setup.sh and exported
# Personal dotfiles configuration (can be set via environment variables)
# PERSONAL_DOTFILES_REPO - Repository URL for personal dotfiles
# PERSONAL_DOTFILES_USERNAME - Username for HTTPS authentication
# PERSONAL_DOTFILES_PASSWORD - Password/token for HTTPS authentication
# PERSONAL_DOTFILES_AUTH_METHOD - Authentication method: https, ssh, or public

# Update system (requires sudo)
echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

# Install essential tools (requires sudo)
echo "🔧 Installing essential bootstrap tools..."
sudo pacman -S --needed --noconfirm \
    git \
    curl \
    ansible \
    stow \
    python-pip \
    base-devel

# Install yay only if missing
if ! command -v yay >/dev/null 2>&1; then
    echo "📥 Installing yay AUR helper..."
    cd /tmp
    # Clean up any existing yay directory
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    # Cleanup handled by trap
else
    echo "✅ yay already installed"
fi

# Clone personal dotfiles repository (sibling to main dotfiles)
echo ""
echo "🔐 Setting up personal dotfiles repository..."
./scripts/clone_personal_dotfiles.sh

echo ""
echo "✅ System bootstrap complete!"
echo "💡 Essential tools installed: git, curl, ansible, stow, python-pip, base-devel, yay"
