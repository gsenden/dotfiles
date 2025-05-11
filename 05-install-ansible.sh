#!/bin/bash

# Exit on error
set -e

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Homebrew is not installed. Please run 02-install-homebrew.sh first."
    exit 1
fi

# Check if Ansible is already installed
if command -v ansible &> /dev/null; then
    echo "Ansible is already installed"
    ansible --version
    exit 0
fi

# Install Ansible using Homebrew
echo "Installing Ansible..."
brew install ansible

# Verify installation
echo "Verifying Ansible installation..."
ansible --version

echo "Ansible has been successfully installed!"
echo "You can now use Ansible to automate your infrastructure" 