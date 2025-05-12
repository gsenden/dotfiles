#!/bin/bash

# Exit on error
set -e

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Remove existing .bash_aliases in home directory if it exists
if [ -f ~/.bash_aliases ]; then
    echo "Removing existing .bash_aliases..."
    rm ~/.bash_aliases
fi

# Create symlink
echo "Creating symlink to .bash_aliases..."
ln -s "${SCRIPT_DIR}/.bash_aliases" ~/.bash_aliases

echo "Installation complete! Please restart your terminal or run 'source ~/.bash_aliases' to apply changes." 