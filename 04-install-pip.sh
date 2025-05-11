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
    exit 0
fi

# Install Python and pip using Homebrew
echo "Installing Python and pip..."
brew install python

# Verify installation
echo "Verifying pip installation..."
pip3 --version

echo "pip has been successfully installed!"
echo "You can use pip3 to install Python packages" 