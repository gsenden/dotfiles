#!/bin/bash

# Default values
REMOTE_HOST="nas"
SSH_USER="$USER"  
REMOTE_DIR="/volume1/config/dotfiles/ssh"

# Create local .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Copy all files from remote .ssh directory
echo "Copying SSH files from remote..."
rsync -avz --progress "${SSH_USER}@${REMOTE_HOST}:${REMOTE_DIR}/" ~/.ssh/

# Set correct permissions
echo "Setting correct permissions..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_rsa
chmod 644 ~/.ssh/id_rsa.pub
chmod 644 ~/.ssh/known_hosts
chmod 644 ~/.ssh/config 2>/dev/null || true

echo "Done! SSH files have been copied from ${REMOTE_HOST} to ~/.ssh/" 

# Add SSH key to ssh-agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa

# Verify SSH key
ssh-add -l
