#!/bin/bash

# Claude Code Statusline Installer - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash

set -e

CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
RAW_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/statusline.sh"

echo "Installing claudebar statusline..."

# Check for jq dependency
if ! command -v jq &> /dev/null; then
    echo ""
    echo "Error: jq is required but not installed."
    echo ""
    echo "Install jq with:"
    echo "  macOS:  brew install jq"
    echo "  Ubuntu: sudo apt install jq"
    echo "  Fedora: sudo dnf install jq"
    echo ""
    exit 1
fi

# Create ~/.claude directory if needed
if [ ! -d "$CLAUDE_DIR" ]; then
    echo "Creating $CLAUDE_DIR..."
    mkdir -p "$CLAUDE_DIR"
fi

# Download statusline.sh
echo "Downloading statusline.sh..."
curl -fsSL "$RAW_URL" -o "$STATUSLINE_SCRIPT"

# Set executable permissions
chmod +x "$STATUSLINE_SCRIPT"
echo "Set executable permissions on statusline.sh"

# Update settings.json
echo "Updating settings.json..."

if [ ! -f "$SETTINGS_FILE" ]; then
    # Create new settings file
    echo '{"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' | jq '.' > "$SETTINGS_FILE"
else
    # Merge statusLine config while preserving existing settings
    tmp_file=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "$tmp_file"
    mv "$tmp_file" "$SETTINGS_FILE"
fi

echo ""
echo "claudebar statusline installed successfully!"
echo ""
echo "Restart Claude Code to see your new statusline:"
echo "  📂 parent/current | 🌿 branch | 📄 S: 0 | U: 0 | A: 0"
echo ""
echo "To uninstall: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash"
