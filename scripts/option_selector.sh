#!/bin/bash

# Check if we have arguments
if [ $# -eq 0 ]; then
    echo "Usage: $0 <category> [--preselect option1,option2] <option1> <option2> ..."
    echo "Example: $0 'Development Tools' git docker code"
    echo "Example: $0 'Development Tools' --preselect git,docker git docker code vim"
    exit 1
fi

category="$1"
shift

# Parse arguments to find preselect flag and options
preselected=()
options=()
i=0
args=("$@")

while [ $i -lt ${#args[@]} ]; do
    if [[ "${args[i]}" == "--preselect" && $((i + 1)) -lt ${#args[@]} ]]; then
        # Found preselect flag, next argument is the comma-separated list
        IFS=',' read -ra preselected <<< "${args[$((i + 1))]}"
        i=$((i + 2))  # Skip both --preselect and its value
    else
        # Regular option
        options+=("${args[i]}")
        i=$((i + 1))
    fi
done

selected=("${preselected[@]}")

# Function to check if option is selected
is_selected() {
    local pkg="$1"
    for selected_pkg in "${selected[@]}"; do
        [[ "$selected_pkg" == "$pkg" ]] && return 0
    done
    return 1
}

# Function to toggle selection
toggle_selection() {
    local pkg="$1"
    if is_selected "$pkg"; then
        # Remove from selected
        for i in "${!selected[@]}"; do
            if [[ "${selected[i]}" == "$pkg" ]]; then
                unset 'selected[i]'
            fi
        done
        # Reindex array
        selected=("${selected[@]}")
    else
        # Add to selected
        selected+=("$pkg")
    fi
}

# Function to display menu
display_menu() {
    clear
    echo "=========================================================="
    echo "= Select one or more $category"
    echo "=========================================================="
    echo "Use ↑/↓ arrows to navigate, SPACE to select/deselect, ENTER to confirm"
    if [ ${#preselected[@]} -gt 0 ]; then
        echo "Pre-selected: ${preselected[*]}"
    fi
    echo "Selected: ${#selected[@]}/${#options[@]}"
    echo ""
    
    for i in "${!options[@]}"; do
        local prefix="  "
        local suffix=""
        
        # Highlight current item
        if [[ $i -eq $current_index ]]; then
            prefix="► "
        fi
        
        # Show selection status
        if is_selected "${options[i]}"; then
            suffix=" ✅"
        else
            suffix=" ⬜"
        fi
        
        echo "${prefix}${suffix} ${options[i]}"
    done
    
    echo ""
    echo "Selected options: ${selected[*]}"
}

# Check if running in non-interactive mode (called by Ansible)
if [[ -n "$ANSIBLE_MANAGED" ]] || [[ ! -t 0 ]]; then
    # Non-interactive mode - auto-select all options (or use preselected if any)
    echo ""
    echo "========================================="
    echo "=== $category ==="
    echo "========================================="
    
    if [ ${#preselected[@]} -gt 0 ]; then
        echo "Running in non-interactive mode - using pre-selected options"
        selected=("${preselected[@]}")
        for item in "${selected[@]}"; do
            echo "   ✅ Pre-selected $item"
        done
    else
        echo "Running in non-interactive mode - selecting all options"
        selected=("${options[@]}")
        for item in "${options[@]}"; do
            echo "   ✅ Auto-selected $item"
        done
    fi
    
    echo ""
    echo "✅ Selected from $category: ${#selected[@]} options"
    echo "   📋 List: ${selected[*]}"
    echo ""
else
    # Interactive mode
    current_index=0
    
    display_menu
    
    while true; do
    # Read key input properly
    IFS= read -rsn1 key
    
    # Handle different key types
    case "$key" in
        $'\x1b') # ESC sequence (arrow keys)
            IFS= read -rsn2 key
            case "$key" in
                '[A') # Up arrow
                    if [[ $current_index -gt 0 ]]; then
                        ((current_index--))
                        display_menu
                    fi
                    ;;
                '[B') # Down arrow
                    if [[ $current_index -lt $((${#options[@]} - 1)) ]]; then
                        ((current_index++))
                        display_menu
                    fi
                    ;;
            esac
            ;;
        ' ') # Spacebar - toggle selection
            toggle_selection "${options[current_index]}"
            display_menu
            ;;
        $'\n'|$'\r'|'') # Enter key
            break
            ;;
        'q'|'Q') # Quit
            selected=()
            break
            ;;
        'a'|'A') # Select all
            selected=("${options[@]}")
            display_menu
            ;;
        'n'|'N') # Select none
            selected=()
            display_menu
            ;;
    esac    done
fi

# Restore terminal (if needed)
# stty echo icanon

clear
echo "✅ Selection complete for $category"
echo "Selected: ${selected[*]}"

# Output JSON for Ansible
echo "["
for i in "${!selected[@]}"; do
    echo -n "\"${selected[i]}\""
    [ $i -lt $((${#selected[@]} - 1)) ] && echo ","
done
echo "]"