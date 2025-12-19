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

# Remove statusLine key from settings.json
if [ -f "$SETTINGS_FILE" ]; then
    if command -v jq &> /dev/null; then
        tmp_file=$(mktemp)
        jq 'del(.statusLine)' "$SETTINGS_FILE" > "$tmp_file"
        mv "$tmp_file" "$SETTINGS_FILE"
        echo "Removed statusLine config from settings.json"
    else
        echo "Warning: jq not found. Please manually remove the statusLine key from $SETTINGS_FILE"
    fi
else
    echo "settings.json not found, skipping..."
fi

echo ""
echo "claudebar statusline uninstalled successfully!"
echo "Restart Claude Code to apply changes."
