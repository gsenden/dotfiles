#!/bin/bash
set -e

echo "📦 Starting package selection and management..."

# Use DOTFILES_DIR if set, otherwise fallback to default
DOTFILES_DIR=${DOTFILES_DIR:-"$HOME/mydotfiles"}
cd "$DOTFILES_DIR"

# Run interactive selections first (no sudo needed)
echo "🔧 Selecting applications..."

# Load available packages from config
echo "📋 Loading available packages from arch/packages.yml..."

# Get all package categories dynamically
CATEGORIES=$(grep '^available_' arch/packages.yml | sed 's/:$//' | sed 's/^available_//')

echo "Found package categories: $CATEGORIES"

# Initialize arrays to store package lists and selections
declare -A PACKAGES
declare -A PREVIOUS_SELECTIONS
declare -A SELECTED_JSON

# Load packages and previous selections for each category
for category in $CATEGORIES; do
    # Get packages for this category
    PACKAGES[$category]=$(awk "/^available_${category}:/{flag=1; next} /^[a-zA-Z]/{flag=0} flag && /^  - /{print \$2}" arch/packages.yml | tr '\n' ' ')
    
    # Load previous selections if they exist
    if [ -f "$HOME/.dotfiles_${category}" ]; then
        PREVIOUS_SELECTIONS[$category]=$(cat "$HOME/.dotfiles_${category}" 2>/dev/null | tr -d '\n')
        echo "📋 Found previous ${category} selections: ${PREVIOUS_SELECTIONS[$category]}"
    else
        PREVIOUS_SELECTIONS[$category]=""
    fi
    
    echo "Available ${category}: ${PACKAGES[$category]}"
done

# Check if we're in an interactive terminal
if [[ -t 0 ]] && [[ -t 1 ]]; then
    # Interactive mode - show selection menus for each category
    for category in $CATEGORIES; do
        # Convert category name to readable format
        readable_name=$(echo "$category" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
        
        echo "Select your ${readable_name}:"
        if [ -n "${PREVIOUS_SELECTIONS[$category]}" ]; then
            ./scripts/option_selector.sh "$readable_name" ${PACKAGES[$category]} --preselect "${PREVIOUS_SELECTIONS[$category]}"
        else
            # Use first package as default
            default_package=$(echo ${PACKAGES[$category]} | awk '{print $1}')
            ./scripts/option_selector.sh "$readable_name" ${PACKAGES[$category]} --preselect "$default_package"
        fi
        SELECTED_JSON[$category]=$(tail -n 1 /tmp/option_selector_result.json 2>/dev/null || echo "[\"$(echo ${PACKAGES[$category]} | awk '{print $1}')\"]")
    done
else
    # Non-interactive mode - use previous selections or defaults
    echo "Running in non-interactive mode..."
    for category in $CATEGORIES; do
        if [ -n "${PREVIOUS_SELECTIONS[$category]}" ]; then
            SELECTED_JSON[$category]="[\"$(echo "${PREVIOUS_SELECTIONS[$category]}" | sed 's/,/","/g')\"]"
            echo "Using previous ${category}: ${PREVIOUS_SELECTIONS[$category]}"
        else
            default_package=$(echo ${PACKAGES[$category]} | awk '{print $1}')
            SELECTED_JSON[$category]="[\"$default_package\"]"
            echo "Using default ${category}: $default_package"
        fi
    done
fi

# Save selections for Ansible to use
echo "📝 Saving selections..."

# Generate Ansible variables file dynamically
cat > /tmp/ansible_selections.yml << EOF
# Dynamically generated package selections
EOF

for category in $CATEGORIES; do
    # Remove '_apps' suffix if it already exists in category name to avoid double suffix
    clean_category=$(echo "$category" | sed 's/_apps$//')
    echo "${clean_category}_apps: ${SELECTED_JSON[$category]}" >> /tmp/ansible_selections.yml
    echo "Selected ${category}: $(echo ${SELECTED_JSON[$category]} | tr -d '[]"' | tr ',' ' ')"
done

echo "✅ Package selection complete!"
echo "📋 Selections saved for Ansible..."
