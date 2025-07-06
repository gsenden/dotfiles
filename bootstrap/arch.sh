#!/bin/bash
set -e

# Ensure cleanup happens even on script exit
trap 'rm -rf /tmp/yay' EXIT

# Redirect output to a log file
exec > >(tee -i /var/log/bootstrap.log) 2>&1

echo "🏗️  EndeavourOS/Arch bootstrap..."

# Update system (always safe to run)
echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

# Install tools (--needed prevents reinstalls)
echo "🔧 Installing bootstrap tools..."
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
    cd ~
    # Cleanup handled by trap
else
    echo "✅ yay already installed"
fi

echo "✅ Bootstrap complete!"