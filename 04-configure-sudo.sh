#!/bin/bash

# Exit on error
set -e

# Get the current user
CURRENT_USER=$(whoami)

# Create a temporary file for the sudoers entry
TEMP_FILE=$(mktemp)

# Create the sudoers entry
echo "$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" > "$TEMP_FILE"

# Check if the entry already exists
if sudo grep -q "^$CURRENT_USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers; then
    echo "Sudo is already configured to not ask for password for $CURRENT_USER"
    rm "$TEMP_FILE"
    exit 0
fi

# Add the entry to sudoers using visudo
echo "Adding sudo configuration for $CURRENT_USER..."
echo "Please enter your password one last time to make this change:"
sudo visudo -cf "$TEMP_FILE" && sudo sh -c "cat $TEMP_FILE >> /etc/sudoers"

# Clean up
rm "$TEMP_FILE"

echo "Sudo has been configured to not ask for password for $CURRENT_USER"
echo "You can test this by running: sudo whoami" 