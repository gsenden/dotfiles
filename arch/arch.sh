#!/bin/bash
set -e

echo "🚀 Starting Arch Linux setup..."

# Use DOTFILES_DIR if set, otherwise fallback to default
DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/mydotfiles"}
cd "$DOTFILES_DIR"

# Step 1: System Bootstrap - Install essential tools
echo "🔧 Step 1: System Bootstrap"
./arch/bootstrap.sh

# Step 2: Package Selection and Management
echo "📦 Step 2: Package Selection and Management"
./arch/package_manager.sh

# Step 3: Run Ansible to install/manage packages
echo "⚙️  Step 3: Package Installation with Ansible"
if [ -f "arch/playbook.yml" ]; then
    # Check if we have selection data from package manager
    if [ -f "/tmp/ansible_selections.yml" ]; then
        echo "📋 Using selections from package manager..."
        ansible-playbook arch/playbook.yml --extra-vars "@/tmp/ansible_selections.yml"
    else
        echo "⚠️  No selections found, running with defaults..."
        ansible-playbook arch/playbook.yml
    fi
else
    echo "⚠️  No Ansible playbook found, skipping..."
fi
