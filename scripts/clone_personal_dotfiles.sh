#!/bin/bash
set -e

# Script to clone and manage personal dotfiles repository
# This is a sibling repository to the main dotfiles for private configurations

echo "🔐 Personal Dotfiles Setup"
echo "=========================="

# DOTFILES_DIR is set by setup.sh and exported
PERSONAL_DOTFILES_DIR="$(dirname "$DOTFILES_DIR")/personal_dotfiles"

# Personal dotfiles configuration (can be set via environment variables)
# PERSONAL_DOTFILES_REPO - Repository URL for personal dotfiles
# PERSONAL_DOTFILES_USERNAME - Username for HTTPS authentication
# PERSONAL_DOTFILES_PASSWORD - Password/token for HTTPS authentication
# PERSONAL_DOTFILES_AUTH_METHOD - Authentication method: https, ssh, or public

# Function to clone repository with authentication
clone_repository() {
    local repo_url="$1"
    local auth_method="$2"
    local username="$3"
    local password="$4"
    
    case "$auth_method" in
        https)
            if [ -n "$username" ] && [ -n "$password" ]; then
                # Construct URL with credentials
                local repo_url_with_auth=$(echo "$repo_url" | sed "s|https://|https://${username}:${password}@|")
                
                echo "📥 Cloning personal dotfiles with HTTPS authentication..."
                if git clone "$repo_url_with_auth" "$PERSONAL_DOTFILES_DIR" 2>/dev/null; then
                    echo "✅ Personal dotfiles cloned successfully"
                    
                    # Remove credentials from remote URL for security
                    cd "$PERSONAL_DOTFILES_DIR"
                    git remote set-url origin "$repo_url"
                    cd "$DOTFILES_DIR"
                    return 0
                else
                    echo "❌ Failed to clone personal dotfiles"
                    echo "💡 Please check your credentials and repository URL"
                    return 1
                fi
            else
                echo "⚠️  Username or password not provided for HTTPS authentication"
                return 1
            fi
            ;;
        ssh)
            echo "📥 Cloning personal dotfiles with SSH..."
            if git clone "$repo_url" "$PERSONAL_DOTFILES_DIR"; then
                echo "✅ Personal dotfiles cloned successfully"
                return 0
            else
                echo "❌ Failed to clone personal dotfiles"
                echo "💡 Please ensure your SSH key is configured and added to your git provider"
                return 1
            fi
            ;;
        public)
            echo "📥 Cloning public personal dotfiles repository..."
            if git clone "$repo_url" "$PERSONAL_DOTFILES_DIR"; then
                echo "✅ Personal dotfiles cloned successfully"
                return 0
            else
                echo "❌ Failed to clone personal dotfiles"
                echo "💡 Please check the repository URL"
                return 1
            fi
            ;;
        *)
            echo "❌ Invalid authentication method: $auth_method"
            echo "💡 Valid methods: https, ssh, public"
            return 1
            ;;
    esac
}

# Function to update existing repository
update_repository() {
    echo "📁 Personal dotfiles repository already exists at $PERSONAL_DOTFILES_DIR"
    echo "🔄 Attempting to update..."
    cd "$PERSONAL_DOTFILES_DIR"
    
    if git pull origin main 2>/dev/null || git pull origin master 2>/dev/null; then
        echo "✅ Personal dotfiles updated successfully"
        cd "$DOTFILES_DIR"
        return 0
    else
        echo "⚠️  Failed to update personal dotfiles (authentication issue?)"
        echo "💡 You may need to update credentials or check the repository"
        cd "$DOTFILES_DIR"
        return 1
    fi
}

# Function for interactive setup
interactive_setup() {
    echo "🔗 Do you want to clone a personal dotfiles repository? (y/n)"
    echo "💡 This is optional and stores your private configurations separately"
    read -r CLONE_PERSONAL
    
    if [[ ! "$CLONE_PERSONAL" =~ ^[Yy]$ ]]; then
        echo "⏭️  Skipping personal dotfiles setup"
        return 1
    fi
    
    echo ""
    echo "📝 Please provide your personal dotfiles repository details:"
    
    # Get repository URL
    echo -n "Repository URL (https://github.com/username/personal_dotfiles.git): "
    read -r PERSONAL_REPO_URL
    
    if [ -z "$PERSONAL_REPO_URL" ]; then
        echo "⚠️  No URL provided, skipping personal dotfiles setup"
        return 1
    fi
    
    echo ""
    echo "🔐 Choose authentication method:"
    echo "1) HTTPS with username/password (or token)"
    echo "2) SSH key (must be configured)"
    echo "3) Public repository (no authentication)"
    echo -n "Choose (1/2/3): "
    read -r AUTH_CHOICE
    
    case "$AUTH_CHOICE" in
        1) AUTH_METHOD="https" ;;
        2) AUTH_METHOD="ssh" ;;
        3) AUTH_METHOD="public" ;;
        *) 
            echo "⚠️  Invalid choice, skipping personal dotfiles setup"
            return 1
            ;;
    esac
    
    if [[ "$AUTH_METHOD" == "https" ]]; then
        echo ""
        echo "🔑 HTTPS Authentication:"
        echo -n "Username: "
        read -r GIT_USERNAME
        echo -n "Password/Token (input hidden): "
        read -rs GIT_PASSWORD
        echo ""
        
        if [ -z "$GIT_USERNAME" ] || [ -z "$GIT_PASSWORD" ]; then
            echo "⚠️  Username or password not provided, skipping personal dotfiles"
            return 1
        fi
    fi
    
    # Clone the repository
    clone_repository "$PERSONAL_REPO_URL" "$AUTH_METHOD" "$GIT_USERNAME" "$GIT_PASSWORD"
}

# Function for non-interactive setup
non_interactive_setup() {
    if [[ -z "$PERSONAL_DOTFILES_REPO" ]]; then
        echo "⏭️  No personal dotfiles repository specified in environment, skipping"
        return 1
    fi
    
    echo "🔗 Found personal dotfiles repository in environment: $PERSONAL_DOTFILES_REPO"
    
    local auth_method="${PERSONAL_DOTFILES_AUTH_METHOD:-public}"
    local username="$PERSONAL_DOTFILES_USERNAME"
    local password="$PERSONAL_DOTFILES_PASSWORD"
    
    echo "📥 Cloning personal dotfiles (non-interactive mode)..."
    clone_repository "$PERSONAL_DOTFILES_REPO" "$auth_method" "$username" "$password"
}

# Main logic
main() {
    # Check if personal_dotfiles already exists
    if [ -d "$PERSONAL_DOTFILES_DIR" ]; then
        if [ -d "$PERSONAL_DOTFILES_DIR/.git" ]; then
            # Repository already exists, just update it
            update_repository
        else
            echo "⚠️  Directory $PERSONAL_DOTFILES_DIR exists but is not a git repository"
            echo "💡 Please remove it manually if you want to clone the personal dotfiles"
            exit 1
        fi
    else
        # Directory doesn't exist, proceed with cloning
        echo "📁 Personal dotfiles directory not found, setting up..."
        
        # Check if running in non-interactive mode or environment variables are set
        if [[ -n "$PERSONAL_DOTFILES_REPO" ]] || [[ -n "$CI" ]] || [[ ! -t 0 ]]; then
            non_interactive_setup
        else
            interactive_setup
        fi
    fi
    
    # Final status
    if [ -d "$PERSONAL_DOTFILES_DIR" ]; then
        echo ""
        echo "✅ Personal dotfiles setup complete!"
        echo "📁 Personal dotfiles available at: $PERSONAL_DOTFILES_DIR"
        return 0
    else
        echo ""
        echo "⏭️  Personal dotfiles setup skipped"
        return 1
    fi
}

# Run main function
main "$@"
