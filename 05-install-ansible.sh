#!/bin/bash

# Exit on error
set -e

# Check if pipx is installed
if ! command -v pipx &> /dev/null; then
    echo "pipx is not installed. Please run 04-install-pip.sh first."
    exit 1
fi

# Check if Ansible is already installed
if command -v ansible &> /dev/null; then
    echo "Ansible is already installed"
    ansible --version
    exit 0
fi

# Install Ansible using pipx
echo "Installing Ansible..."
pipx install ansible

# Verify installation
echo "Verifying Ansible installation..."
ansible --version

echo "Ansible has been successfully installed!"
echo "You can now use Ansible to automate your infrastructure" 