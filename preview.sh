#!/bin/bash

# Claude Code Statusline Preview - claudebar
# https://github.com/kevinmaes/claudebar
#
# For developers: Preview local statusline.sh changes without publishing.
# Copies the local statusline.sh to ~/.claude/statusline.sh
#
# Usage: ./preview.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SCRIPT="$SCRIPT_DIR/statusline.sh"
CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"

echo "claudebar preview - installing local statusline.sh..."

# Check that local statusline.sh exists
if [ ! -f "$LOCAL_SCRIPT" ]; then
    echo "Error: statusline.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required. Install with: brew install jq"
    exit 1
fi

# Create ~/.claude directory if needed
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating $CLAUDE_DIR..."
    mkdir -p "$CLAUDE_DIR"
fi

# Backup existing statusline.sh if present
if [ -f "$STATUSLINE_SCRIPT" ]; then
    cp "$STATUSLINE_SCRIPT" "$STATUSLINE_SCRIPT.backup"
    echo "Backed up existing statusline.sh to statusline.sh.backup"
fi

# Copy local statusline.sh
cp "$LOCAL_SCRIPT" "$STATUSLINE_SCRIPT"
chmod +x "$STATUSLINE_SCRIPT"
echo "Copied local statusline.sh to $STATUSLINE_SCRIPT"

# Ensure settings.json has statusLine configured
if [ ! -f "$SETTINGS_FILE" ]; then
    echo '{"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' | jq '.' > "$SETTINGS_FILE"
    echo "Created settings.json with statusLine config"
elif ! jq -e '.statusLine' "$SETTINGS_FILE" > /dev/null 2>&1; then
    tmp_file=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "$tmp_file"
    mv "$tmp_file" "$SETTINGS_FILE"
    echo "Added statusLine config to settings.json"
fi

echo ""
echo "Preview installed! Restart Claude Code to see changes."
echo ""
echo "To restore the previous version:"
echo "  cp ~/.claude/statusline.sh.backup ~/.claude/statusline.sh"
echo ""
