#!/bin/bash

# Exit on error
set -e

# Check if Ansible is installed
if ! command -v ansible &> /dev/null; then
    echo "Ansible is not installed. Please run 05-install-ansible.sh first."
    exit 1
fi

# Install libcanberra
echo "Installing libcanberra..."
sudo apt-get update
sudo apt-get install -y libcanberra-gtk-module libcanberra-gtk3-module

# Run the Ansible playbook
echo "Installing Zen Browser using Ansible..."
ansible-playbook -i ansible/inventory.ini ansible/install_zen.yml

echo "Zen Browser installation completed!" 