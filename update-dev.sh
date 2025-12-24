#!/bin/bash

# Claude Code Statusline Updater (Dev Branch) - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/dev/update-dev.sh | bash
#
# This script updates from the dev branch for testing integrated features
# before the next release. For stable releases, use update.sh instead.

set -e

STATUSLINE_SCRIPT="$HOME/.claude/statusline.sh"
RAW_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/dev/statusline.sh"

echo "Updating claudebar statusline (dev branch)..."
echo ""
echo "Note: This updates from the dev branch for testing pre-release features."
echo ""

# Check if statusline.sh exists
if [ ! -f "$STATUSLINE_SCRIPT" ]; then
    echo "Error: statusline.sh not found. Run the install script first:"
    echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/dev/install-dev.sh | bash"
    exit 1
fi

# Download latest statusline.sh from dev branch
echo "Downloading latest statusline.sh from dev branch..."
curl -fsSL "$RAW_URL" -o "$STATUSLINE_SCRIPT"

# Ensure executable permissions
chmod +x "$STATUSLINE_SCRIPT"

echo ""
echo "claudebar statusline updated successfully (dev branch)!"
echo "Restart Claude Code to see changes."
echo ""
echo "To switch to stable release:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/update.sh | bash"
echo ""
