#!/bin/bash

# Exit on error
set -e

# Check if Homebrew is already installed
if command -v brew &> /dev/null; then
    echo "Homebrew is already installed"
    exit 0
fi

# Install dependencies
echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git

# Install Homebrew
echo "Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew to PATH if not already added
if ! grep -q "eval \"\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)\"" ~/.profile; then
    echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> ~/.profile
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Verify installation
echo "Verifying Homebrew installation..."
brew --version

echo "Homebrew has been successfully installed!"
echo "Please run 'source ~/.profile' or restart your terminal to start using Homebrew" 