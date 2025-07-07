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
CATEGORIES=$(grep '^[a-zA-Z]' arch/packages.yml | grep ':$' | sed 's/:$//')

echo "Found package categories: $CATEGORIES"

# Initialize arrays to store package lists and selections
declare -A DISPLAY_NAMES
declare -A PACKAGE_NAMES
declare -A DEFAULT_PACKAGES
declare -A PREVIOUS_SELECTIONS
declare -A SELECTED_JSON

# Load packages and previous selections for each category
for category in $CATEGORIES; do
    # Extract package info from the new YAML structure
    # Get display names, package names, and defaults
    DISPLAY_NAMES[$category]=$(python3 -c "
import yaml
with open('arch/packages.yml', 'r') as f:
    data = yaml.safe_load(f)
packages = data.get('${category}', [])
for pkg in packages:
    print(pkg['display_name'])
" | tr '\n' '|' | sed 's/|$//')
    
    PACKAGE_NAMES[$category]=$(python3 -c "
import yaml
with open('arch/packages.yml', 'r') as f:
    data = yaml.safe_load(f)
packages = data.get('${category}', [])
for pkg in packages:
    print(pkg['package_name'])
" | tr '\n' ' ')
    
    DEFAULT_PACKAGES[$category]=$(python3 -c "
import yaml
with open('arch/packages.yml', 'r') as f:
    data = yaml.safe_load(f)
packages = data.get('${category}', [])
defaults = []
for pkg in packages:
    if pkg.get('default', False):
        defaults.append(pkg['package_name'])
print(','.join(defaults) if defaults else '')
")
    
    # Load previous selections if they exist, otherwise use defaults
    if [ -f ".saved_selections/${category}" ]; then
        PREVIOUS_SELECTIONS[$category]=$(cat ".saved_selections/${category}" 2>/dev/null | tr -d '\n')
        echo "📋 Found previous ${category} selections: ${PREVIOUS_SELECTIONS[$category]}"
    else
        PREVIOUS_SELECTIONS[$category]="${DEFAULT_PACKAGES[$category]}"
        echo "📋 Using default ${category} selections: ${DEFAULT_PACKAGES[$category]}"
    fi
    
    echo "Available ${category}: ${DISPLAY_NAMES[$category]}" | tr '|' ', '
done

# Check if we're in an interactive terminal
if [[ -t 0 ]] && [[ -t 1 ]]; then
    # Interactive mode - show selection menus for each category
    for category in $CATEGORIES; do
        # Convert category name to readable format
        readable_name=$(echo "$category" | sed 's/_/ /g' | sed 's/\b\w/\U&/g')
        
        # Create a mapping file for display names to package names
        echo "Creating mapping for ${category}..."
        python3 -c "
import yaml
with open('arch/packages.yml', 'r') as f:
    data = yaml.safe_load(f)
packages = data.get('${category}', [])
mapping = {}
for pkg in packages:
    mapping[pkg['display_name']] = pkg['package_name']

with open('/tmp/display_to_package_${category}.txt', 'w') as f:
    for display, package in mapping.items():
        f.write(f'{display}|{package}\n')
"
        
        # Get display names for the selector (properly quoted)
        display_options_array=()
        IFS='|' read -ra DISPLAY_ARRAY <<< "${DISPLAY_NAMES[$category]}"
        for display_name in "${DISPLAY_ARRAY[@]}"; do
            display_options_array+=("$display_name")
        done
        
        # Convert previous package selections to display names for preselection
        if [ -n "${PREVIOUS_SELECTIONS[$category]}" ]; then
            preselect_display=$(python3 -c "
import yaml
with open('arch/packages.yml', 'r') as f:
    data = yaml.safe_load(f)
packages = data.get('${category}', [])
package_to_display = {}
for pkg in packages:
    package_to_display[pkg['package_name']] = pkg['display_name']

selected_packages = '${PREVIOUS_SELECTIONS[$category]}'.split(',')
display_names = []
for pkg in selected_packages:
    if pkg.strip() in package_to_display:
        display_names.append(package_to_display[pkg.strip()])
print(','.join(display_names))
")
            echo "Select your ${readable_name}:"
            ./scripts/option_selector.sh "$readable_name" "${display_options_array[@]}" --preselect "$preselect_display"
        else
            echo "Select your ${readable_name}:"
            ./scripts/option_selector.sh "$readable_name" "${display_options_array[@]}"
        fi
        
        # Convert selected display names back to package names
        selected_display_json=$(tail -n 1 /tmp/option_selector_result.json 2>/dev/null || echo "[]")
        SELECTED_JSON[$category]=$(python3 -c "
import json
import yaml

# Load the mapping
mapping = {}
with open('/tmp/display_to_package_${category}.txt', 'r') as f:
    for line in f:
        display, package = line.strip().split('|', 1)
        mapping[display] = package

# Convert selected display names to package names
selected_display = json.loads('$selected_display_json')
selected_packages = []
for display in selected_display:
    if display in mapping:
        selected_packages.append(mapping[display])

print(json.dumps(selected_packages))
")
    done
else
    # Non-interactive mode - use previous selections or defaults
    echo "Running in non-interactive mode..."
    for category in $CATEGORIES; do
        if [ -n "${PREVIOUS_SELECTIONS[$category]}" ]; then
            SELECTED_JSON[$category]="[\"$(echo "${PREVIOUS_SELECTIONS[$category]}" | sed 's/,/","/g')\"]"
            echo "Using previous ${category}: ${PREVIOUS_SELECTIONS[$category]}"
        else
            if [ -n "${DEFAULT_PACKAGES[$category]}" ]; then
                SELECTED_JSON[$category]="[\"$(echo "${DEFAULT_PACKAGES[$category]}" | sed 's/,/","/g')\"]"
                echo "Using default ${category}: ${DEFAULT_PACKAGES[$category]}"
            else
                # Fallback to first package if no defaults
                first_package=$(echo "${PACKAGE_NAMES[$category]}" | awk '{print $1}')
                SELECTED_JSON[$category]="[\"$first_package\"]"
                echo "Using fallback ${category}: $first_package"
            fi
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
    # Use the category name as-is for the variable name since it already ends with '_apps'
    echo "${category}: ${SELECTED_JSON[$category]}" >> /tmp/ansible_selections.yml
    echo "Selected ${category}: $(echo ${SELECTED_JSON[$category]} | tr -d '[]"' | tr ',' ' ')"
    
    # Save selections to memory files for next run
    selected_packages=$(echo ${SELECTED_JSON[$category]} | tr -d '[]"' | sed 's/, */,/g' | sed 's/^,//' | sed 's/,$//')
    
    # Create saved selections directory if it doesn't exist
    mkdir -p .saved_selections
    
    echo "$selected_packages" > ".saved_selections/${category}"
    echo "💾 Saved ${category} selections to memory: $selected_packages"
done

echo "✅ Package selection complete!"
echo "📋 Selections saved for Ansible..."
