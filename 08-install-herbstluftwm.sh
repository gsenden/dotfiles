#!/bin/bash

# Exit on error
set -e

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Get the actual user's home directory
REAL_USER=$(logname)
REAL_HOME=$(eval echo ~$REAL_USER)

# Install herbstluftwm
echo "Installing herbstluftwm..."
apt-get update
apt-get install -y herbstluftwm

# Get the absolute path of the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create config directory if it doesn't exist
mkdir -p "${REAL_HOME}/.config"

# Remove existing herbstluftwm config if it exists
if [ -d "${REAL_HOME}/.config/herbstluftwm" ]; then
    echo "Removing existing herbstluftwm config..."
    rm -rf "${REAL_HOME}/.config/herbstluftwm"
fi

# Create symlink to the herbstluftwm directory
echo "Creating symlink to herbstluftwm config..."
if ! ln -s "${SCRIPT_DIR}/herbstluftwm" "${REAL_HOME}/.config/herbstluftwm"; then
    echo "Error: Failed to create symlink"
    exit 1
fi

# Fix permissions
chown -R "${REAL_USER}:${REAL_USER}" "${REAL_HOME}/.config/herbstluftwm"

# Verify the symlink was created
if [ ! -L "${REAL_HOME}/.config/herbstluftwm" ]; then
    echo "Error: Symlink was not created properly"
    exit 1
fi

echo "Installation complete!"
