#!/bin/bash

# Claude Code Statusline Uninstaller - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash

set -e

CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "Uninstalling claudebar statusline..."

# Remove statusline.sh
if [ -f "$STATUSLINE_SCRIPT" ]; then
    rm "$STATUSLINE_SCRIPT"
    echo "Removed $STATUSLINE_SCRIPT"
else
    echo "statusline.sh not found, skipping..."
fi

# Remove statusLine key from settings.json (only if it's claudebar)
if [ -f "$SETTINGS_FILE" ]; then
    if command -v jq &> /dev/null; then
        existing_command=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE")

        # Only remove if it's a claudebar statusLine
        if [[ "$existing_command" == *"claudebar"* ]] || [[ "$existing_command" == *".claude/statusline.sh"* ]]; then
            tmp_file=$(mktemp)
            jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp_file"
            mv "$tmp_file" "$SETTINGS_FILE"
            echo "Removed statusLine config from settings.json"
        elif [ -n "$existing_command" ]; then
            echo "Skipping settings.json: statusLine is not claudebar"
            echo "  Current command: $existing_command"
        else
            echo "No statusLine config found in settings.json"
        fi
    else
        echo "Warning: jq not found. Please manually remove the statusLine key from $SETTINGS_FILE"
    fi
else
    echo "settings.json not found, skipping..."
fi

# Remove version cache file
CACHE_FILE="$CLAUDE_DIR/.claudebar-version-cache"
if [ -f "$CACHE_FILE" ]; then
    rm "$CACHE_FILE"
    echo "Removed version cache"
fi

# Remove installed version file
VERSION_FILE="$CLAUDE_DIR/.claudebar-installed-version"
if [ -f "$VERSION_FILE" ]; then
    rm "$VERSION_FILE"
    echo "Removed installed version file"
fi

# Remove claudebar shell command from shell configs
for rc_file in "$HOME/.zshrc" "$HOME/.bashrc"; do
    if [ -f "$rc_file" ]; then
        if grep -q "^# claudebar command$" "$rc_file"; then
            # Remove the comment line and the function line
            sed -i.bak '/^# claudebar command$/d; /^claudebar() {/d' "$rc_file"
            rm -f "$rc_file.bak"
            echo "Removed claudebar command from $rc_file"
        fi
    fi
done

echo ""
echo "claudebar statusline uninstalled successfully!"
echo "Restart Claude Code to apply changes."
