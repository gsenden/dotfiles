# Personal Dotfiles Integration

This setup supports cloning a separate "personal_dotfiles" repository alongside your main dotfiles. This is useful for storing private configurations, sensitive data, or personal customizations that you don't want in your public dotfiles repository.

## Architecture

The personal dotfiles functionality is implemented in a separate script (`scripts/clone_personal_dotfiles.sh`) that is called during the bootstrap process. This modular approach keeps the bootstrap script clean and allows the personal dotfiles script to be used independently.

## Directory Structure

```
~/
├── mydotfiles/           # Main public dotfiles repository
│   └── scripts/
│       └── clone_personal_dotfiles.sh  # Personal dotfiles management script
└── personal_dotfiles/    # Private personal dotfiles repository (sibling)
```

## Usage

### Automatic (during bootstrap)

The script is automatically called during the bootstrap process (`arch/bootstrap.sh`):

```bash
./setup.sh  # Will prompt for personal dotfiles setup
```

### Manual execution

You can also run the personal dotfiles script independently:

```bash
# Interactive mode
./scripts/clone_personal_dotfiles.sh

# With environment variables (non-interactive)
PERSONAL_DOTFILES_REPO="https://github.com/username/personal_dotfiles.git" \
PERSONAL_DOTFILES_AUTH_METHOD="https" \
PERSONAL_DOTFILES_USERNAME="username" \
PERSONAL_DOTFILES_PASSWORD="token" \
./scripts/clone_personal_dotfiles.sh
```

## Interactive Usage

During the bootstrap process, you'll be prompted:

1. **Repository URL**: Provide the Git URL for your personal dotfiles repository
2. **Authentication Method**: Choose from:
   - HTTPS with username/password (or personal access token)
   - SSH key authentication
   - Public repository (no authentication needed)

## Non-Interactive Usage

For automated setups, you can use environment variables:

```bash
# Required
export PERSONAL_DOTFILES_REPO="https://github.com/username/personal_dotfiles.git"

# Optional - Authentication method (defaults to 'public')
export PERSONAL_DOTFILES_AUTH_METHOD="https"  # or "ssh" or "public"

# Required for HTTPS authentication
export PERSONAL_DOTFILES_USERNAME="your_username"
export PERSONAL_DOTFILES_PASSWORD="your_password_or_token"

# Run setup
./setup.sh
```

## Authentication Methods

### HTTPS with Personal Access Token (Recommended)
```bash
export PERSONAL_DOTFILES_REPO="https://github.com/username/personal_dotfiles.git"
export PERSONAL_DOTFILES_AUTH_METHOD="https"
export PERSONAL_DOTFILES_USERNAME="your_username"
export PERSONAL_DOTFILES_PASSWORD="ghp_xxxxxxxxxxxxxxxxxxxx"  # GitHub Personal Access Token
```

### SSH Key Authentication
```bash
export PERSONAL_DOTFILES_REPO="git@github.com:username/personal_dotfiles.git"
export PERSONAL_DOTFILES_AUTH_METHOD="ssh"
# No username/password needed - uses your SSH key
```

### Public Repository
```bash
export PERSONAL_DOTFILES_REPO="https://github.com/username/personal_dotfiles.git"
export PERSONAL_DOTFILES_AUTH_METHOD="public"
# No credentials needed
```

## Security Notes

- For HTTPS authentication, use Personal Access Tokens instead of passwords
- Credentials are removed from the git remote URL after cloning for security
- SSH keys are the most secure option for private repositories
- The script supports hidden password input in interactive mode

## Integration with Package Selection

The package selection system automatically looks for the `personal_dotfiles` directory and will save your selections there if it exists, allowing you to maintain separate package preferences from your public dotfiles. Selections are stored in `personal_dotfiles/saved_selections/` directory.

## Troubleshooting

- **Authentication Failed**: Check your credentials and ensure your token/SSH key has repository access
- **Repository Not Found**: Verify the repository URL and that you have access to it
- **Directory Exists**: If the directory exists but isn't a git repository, remove it manually and re-run the setup
