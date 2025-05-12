#!/bin/bash

# Exit on error
set -e

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please run 02-install-homebrew.sh first."
    exit 1
fi

# Check if pip is already installed
if command -v pip3 &> /dev/null; then
    echo "pip is already installed"
    pip3 --version
else
    # Install Python and pip using Homebrew
    echo "Installing Python and pip..."
    brew install python

    # Verify pip installation
    echo "Verifying pip installation..."
    pip3 --version
fi

# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "Installing pipx..."
    brew install pipx
    pipx ensurepath
    echo "pipx has been installed and added to PATH"
else
    echo "pipx is already installed"
fi

echo "Python package management tools have been successfully installed!"
echo "You can use pip3 to install Python packages"
echo "You can use pipx to install Python applications" 