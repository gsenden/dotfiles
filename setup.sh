#!/bin/bash

# Exit on error
set -e

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit 1
fi

# Clone the dotfiles repository if not already cloned
if [ ! -d "$HOME/mydotfiles" ]; then
  git clone https://github.com/gsenden/dotfiles.git "$HOME/mydotfiles"
fi

# Run the bootstrap script
bash "$HOME/mydotfiles/bootstrap.sh"

# Run the Ansible playbook
ansible-playbook "$HOME/mydotfiles/ansible/playbook.yml" --ask-become-pass

# Use GNU Stow to manage dotfiles
cd "$HOME/mydotfiles/dotfiles"
stow -v -t "$HOME" *

# Done
echo "Setup complete!"
