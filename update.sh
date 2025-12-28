#!/bin/bash

# Claude Code Statusline Updater - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/update.sh | bash
# Or with --no-prompts to skip interactive prompts for new features

set -e

CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
VERSION_FILE="$CLAUDE_DIR/.claudebar-installed-version"
RAW_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/statusline.sh"
MANIFEST_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/options-manifest.json"

NO_PROMPTS=false

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        --no-prompts)
            NO_PROMPTS=true
            ;;
    esac
done

# Compare semver versions - returns 0 if $1 > $2
version_gt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

# Extract current preferences from existing statusline.sh
extract_preferences() {
    local script="$1"

    # Extract MODE value (look for hardcoded value, not the default pattern)
    CURRENT_MODE=$(grep -o 'MODE="[^"]*"' "$script" | head -1 | cut -d'"' -f2)
    # If it contains ${, it's the default pattern, so use empty
    if [[ "$CURRENT_MODE" == *'${'* ]]; then
        CURRENT_MODE=""
    fi

    # Extract PATH_MODE value
    CURRENT_PATH_MODE=$(grep -o 'PATH_MODE="[^"]*"' "$script" | head -1 | cut -d'"' -f2)
    if [[ "$CURRENT_PATH_MODE" == *'${'* ]]; then
        CURRENT_PATH_MODE=""
    fi

    # Check if shell command exists
    CURRENT_SHELL_CMD=false
    for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
        if [ -f "$rc_file" ] && grep -q "^claudebar()" "$rc_file"; then
            CURRENT_SHELL_CMD=true
            break
        fi
    done
}

# Restore extracted preferences to new script
restore_preferences() {
    local script="$1"

    if [ -n "$CURRENT_MODE" ]; then
        sed -i.bak "s/MODE=\"\${CLAUDEBAR_MODE:-icon}\"/MODE=\"$CURRENT_MODE\"/" "$script"
        rm -f "$script.bak"
    fi

    if [ -n "$CURRENT_PATH_MODE" ]; then
        sed -i.bak "s/PATH_MODE=\"\${CLAUDEBAR_DISPLAY_PATH:-path}\"/PATH_MODE=\"$CURRENT_PATH_MODE\"/" "$script"
        rm -f "$script.bak"
    fi
}

# Prompt for display mode - returns chosen mode or empty for "keep current"
prompt_display_mode() {
    echo ""
    echo "New feature available: Display Mode"
    echo ""
    echo "Choose display mode:"
    echo ""
    echo "  1) icon  - Emoji icons (recommended)"
    echo "     📂 parent/current | 🌿 main | 📄 S: 0 | ... | 🧠 42% (84k/200k)"
    echo ""
    echo "  2) label - Text labels"
    echo "     DIR: parent/current | BRANCH: main | STAGED: 0 | ... | Context: 42% (84k/200k)"
    echo ""
    echo "  3) none  - Minimal output"
    echo "     parent/current | main | S: 0 | ... | 42% (84k/200k)"
    echo ""
    echo "  4) Keep current setting"
    echo ""
    read -p "Enter choice [1-4]: " -n 1 -r < /dev/tty
    echo ""

    case "$REPLY" in
        1) echo "icon" ;;
        2) echo "label" ;;
        3) echo "none" ;;
        *) echo "" ;;
    esac
}

# Prompt for path mode - returns chosen mode or empty for "keep current"
prompt_path_mode() {
    echo ""
    echo "New feature available: Path Display Mode"
    echo ""
    echo "Choose path display mode:"
    echo ""
    echo "  1) project - Project name only (recommended)"
    echo "     📂 claudebar"
    echo ""
    echo "  2) path    - Parent/current folder"
    echo "     📂 kevinmaes/claudebar"
    echo ""
    echo "  3) both    - Project name with path"
    echo "     📂 claudebar (kevinmaes/claudebar)"
    echo ""
    echo "  4) Keep current setting"
    echo ""
    read -p "Enter choice [1-4]: " -n 1 -r < /dev/tty
    echo ""

    case "$REPLY" in
        1) echo "project" ;;
        2) echo "path" ;;
        3) echo "both" ;;
        *) echo "" ;;
    esac
}

# Prompt for shell command installation
prompt_shell_command() {
    echo ""
    echo "New feature available: Shell Command"
    echo ""
    echo "Add 'claudebar' command to your shell?"
    echo ""
    echo "This lets you run these commands from anywhere:"
    echo "  claudebar --version       Show installed version"
    echo "  claudebar --help          Show usage and available options"
    echo "  claudebar --update        Update to latest version"
    echo "  claudebar --check-update  Check if update is available"
    echo ""
    read -p "Install to shell? [y/N] " -n 1 -r < /dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "yes"
    else
        echo "no"
    fi
}

# Install shell command
install_shell_command() {
    # Detect shell config file
    if [ -n "${ZSH_VERSION:-}" ] || [ -f "$HOME/.zshrc" ]; then
        SHELL_RC="$HOME/.zshrc"
    else
        SHELL_RC="$HOME/.bashrc"
    fi

    # Remove old claudebar function if exists
    if [ -f "$SHELL_RC" ]; then
        sed -i.bak '/^# claudebar command$/d; /^claudebar() {/d' "$SHELL_RC" 2>/dev/null || true
        rm -f "$SHELL_RC.bak"
    fi

    # Add claudebar function
    {
        echo ""
        echo "# claudebar command"
        echo 'claudebar() { ~/.claude/statusline.sh "$@"; }'
    } >> "$SHELL_RC"

    echo "Added claudebar command to $SHELL_RC"
    echo "Run: source $SHELL_RC  (or restart your terminal)"
}

echo "Updating claudebar statusline..."

# Check if statusline.sh exists
if [ ! -f "$STATUSLINE_SCRIPT" ]; then
    echo "Error: statusline.sh not found. Run the install script first:"
    echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash"
    exit 1
fi

# Extract current preferences before downloading new version
extract_preferences "$STATUSLINE_SCRIPT"

# Get installed version
if [ -f "$VERSION_FILE" ]; then
    INSTALLED_VERSION=$(cat "$VERSION_FILE")
else
    # Try to extract from statusline.sh if no version file exists
    INSTALLED_VERSION=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$STATUSLINE_SCRIPT" 2>/dev/null | cut -d'"' -f2 || echo "0.0.0")
    if [ -z "$INSTALLED_VERSION" ]; then
        INSTALLED_VERSION="0.0.0"
    fi
fi
echo "Current version: $INSTALLED_VERSION"

# Download latest statusline.sh
echo "Downloading latest statusline.sh..."
curl -fsSL "$RAW_URL" -o "$STATUSLINE_SCRIPT"

# Get new version
NEW_VERSION=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$STATUSLINE_SCRIPT" | cut -d'"' -f2)
echo "New version: $NEW_VERSION"

# Restore existing preferences
restore_preferences "$STATUSLINE_SCRIPT"

# Handle retroactive options
if [ "$NO_PROMPTS" = true ]; then
    echo ""
    echo "Skipping new feature prompts (--no-prompts)."
    echo "You may miss new configuration options introduced since your last update."
    echo "Run 'claudebar --update' without --no-prompts to configure new features."
else
    # Check if jq is available for manifest parsing
    if command -v jq &> /dev/null; then
        # Download manifest
        MANIFEST=$(curl -fsSL "$MANIFEST_URL" 2>/dev/null || echo "")

        if [ -n "$MANIFEST" ]; then
            # Get list of new options (introduced after installed version)
            NEW_OPTIONS=$(echo "$MANIFEST" | jq -r --arg ver "$INSTALLED_VERSION" '
                .options[] |
                select(
                    (.introducedInVersion | split(".") | map(tonumber)) as $opt |
                    ($ver | split(".") | map(tonumber)) as $inst |
                    ($opt[0] > $inst[0]) or
                    ($opt[0] == $inst[0] and $opt[1] > $inst[1]) or
                    ($opt[0] == $inst[0] and $opt[1] == $inst[1] and ($opt[2] // 0) > ($inst[2] // 0))
                ) | .id
            ')

            # Process each new option
            for option_id in $NEW_OPTIONS; do
                case "$option_id" in
                    display_mode)
                        SELECTED=$(prompt_display_mode)
                        if [ -n "$SELECTED" ]; then
                            sed -i.bak "s/MODE=\"[^\"]*\"/MODE=\"$SELECTED\"/" "$STATUSLINE_SCRIPT"
                            rm -f "$STATUSLINE_SCRIPT.bak"
                            echo "Display mode set to: $SELECTED"
                        else
                            echo "Keeping current display mode"
                        fi
                        ;;
                    path_mode)
                        SELECTED=$(prompt_path_mode)
                        if [ -n "$SELECTED" ]; then
                            sed -i.bak "s/PATH_MODE=\"[^\"]*\"/PATH_MODE=\"$SELECTED\"/" "$STATUSLINE_SCRIPT"
                            rm -f "$STATUSLINE_SCRIPT.bak"
                            echo "Path mode set to: $SELECTED"
                        else
                            echo "Keeping current path mode"
                        fi
                        ;;
                    shell_command)
                        # Skip if already installed
                        if [ "$CURRENT_SHELL_CMD" = false ]; then
                            SELECTED=$(prompt_shell_command)
                            if [ "$SELECTED" = "yes" ]; then
                                install_shell_command
                            fi
                        fi
                        ;;
                esac
            done
        else
            echo "Warning: Could not download options manifest. Skipping retroactive prompts."
        fi
    else
        echo ""
        echo "Note: jq is not installed. Skipping new feature prompts."
        echo "Install jq and run 'claudebar --update' to configure new features."
    fi
fi

# Ensure executable permissions
chmod +x "$STATUSLINE_SCRIPT"

# Save new version
echo "$NEW_VERSION" > "$VERSION_FILE"

echo ""
echo "claudebar statusline updated successfully!"
echo "Restart Claude Code to see changes."
