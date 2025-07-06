#!/bin/bash
set -e

echo "🔧 Starting Arch bootstrap..."

# Ensure cleanup happens even on script exit
trap 'rm -rf /tmp/yay' EXIT

echo "🏗️  EndeavourOS/Arch bootstrap..."

# Use DOTFILES_DIR if set, otherwise fallback to default
DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/mydotfiles"}
cd "$DOTFILES_DIR"

# Run interactive selections first (no sudo needed)
echo "🔧 Selecting applications..."

# Load previously installed selections if they exist
PREV_MONITORING=""
PREV_BROWSERS=""

if [ -f "$HOME/.dotfiles_monitoring" ]; then
    PREV_MONITORING=$(cat "$HOME/.dotfiles_monitoring" 2>/dev/null | tr -d '\n')
    echo "📋 Found previous monitoring selections: $PREV_MONITORING"
fi

if [ -f "$HOME/.dotfiles_browsers" ]; then
    PREV_BROWSERS=$(cat "$HOME/.dotfiles_browsers" 2>/dev/null | tr -d '\n')
    echo "📋 Found previous browser selections: $PREV_BROWSERS"
fi

# Check if we're in an interactive terminal
if [[ -t 0 ]] && [[ -t 1 ]]; then
    # Interactive mode - show selection menus
    echo "Select your monitoring applications:"
    if [ -n "$PREV_MONITORING" ]; then
        ./scripts/option_selector.sh "Monitoring Applications" htop btop atop glances --preselect "$PREV_MONITORING"
    else
        ./scripts/option_selector.sh "Monitoring Applications" htop btop atop glances --preselect btop
    fi
    MONITORING_JSON=$(tail -n 1 /tmp/option_selector_result.json 2>/dev/null || echo '["btop"]')
    
    echo "Select your web browsers:"
    if [ -n "$PREV_BROWSERS" ]; then
        ./scripts/option_selector.sh "Web Browsers" firefox chromium brave vivaldi zen --preselect "$PREV_BROWSERS"
    else
        ./scripts/option_selector.sh "Web Browsers" firefox chromium brave vivaldi zen --preselect vivaldi
    fi
    BROWSERS_JSON=$(tail -n 1 /tmp/option_selector_result.json 2>/dev/null || echo '["vivaldi"]')
else
    # Non-interactive mode - use previous selections or defaults
    echo "Running in non-interactive mode..."
    if [ -n "$PREV_MONITORING" ]; then
        MONITORING_JSON="[\"$(echo "$PREV_MONITORING" | sed 's/,/","/g')\"]"
        echo "Using previous monitoring apps: $PREV_MONITORING"
    else
        MONITORING_JSON='["btop"]'
        echo "Using default monitoring apps: btop"
    fi
    
    if [ -n "$PREV_BROWSERS" ]; then
        BROWSERS_JSON="[\"$(echo "$PREV_BROWSERS" | sed 's/,/","/g')\"]"
        echo "Using previous browsers: $PREV_BROWSERS"
    else
        BROWSERS_JSON='["vivaldi"]'
        echo "Using default browsers: vivaldi"
    fi
fi

# Save selections for Ansible to use
echo "📝 Saving selections..."
cat > /tmp/ansible_selections.yml << EOF
monitoring_apps: $MONITORING_JSON
browsers: $BROWSERS_JSON
EOF

echo "Selected monitoring apps: $(echo $MONITORING_JSON | tr -d '[]"' | tr ',' ' ')"
echo "Selected browsers: $(echo $BROWSERS_JSON | tr -d '[]"' | tr ',' ' ')"

# Update system (requires sudo)
echo "📦 Updating system..."
sudo pacman -Syu --noconfirm

# Install tools (requires sudo)
echo "🔧 Installing bootstrap tools..."
sudo pacman -S --needed --noconfirm \
    git \
    curl \
    ansible \
    stow \
    python-pip \
    base-devel

# Install yay only if missing
if ! command -v yay >/dev/null 2>&1; then
    echo "📥 Installing yay AUR helper..."
    cd /tmp
    # Clean up any existing yay directory
    rm -rf yay
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    # Cleanup handled by trap
else
    echo "✅ yay already installed"
fi

echo "✅ Bootstrap complete!"
echo "📋 Selections saved for Ansible..."