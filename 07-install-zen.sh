#!/bin/bash

# Exit on error
set -e

echo "Installing Zen Browser..."

# Add Flathub and install Zen Browser
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub app.zen_browser.zen

# Remove existing alias and add new one
sed -i '/alias zen=/d' ~/.bash_aliases
echo 'alias zen="flatpak run app.zen_browser.zen"' >> ~/.bash_aliases
source ~/.bash_aliases

echo "Zen Browser has been installed successfully!"
echo "You can now run it by typing 'zen' in your terminal."
echo "Please restart your terminal or run 'source ~/.bash_aliases' to use the alias." 