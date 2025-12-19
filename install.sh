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

# Check for jq dependency and offer to install
if ! command -v jq &> /dev/null; then
    echo ""
    echo "jq is required but not installed."
    echo ""

    # Read from /dev/tty to support curl|bash usage
    read -p "Install jq now? [y/N] " -n 1 -r < /dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            if command -v brew &> /dev/null; then
                echo "Installing jq via Homebrew..."
                brew install jq
            else
                echo "Error: Homebrew not found. Install jq manually: https://jqlang.github.io/jq/download/"
                exit 1
            fi
        elif command -v apt &> /dev/null; then
            echo "Installing jq via apt..."
            sudo apt install -y jq
        elif command -v dnf &> /dev/null; then
            echo "Installing jq via dnf..."
            sudo dnf install -y jq
        elif command -v pacman &> /dev/null; then
            echo "Installing jq via pacman..."
            sudo pacman -S --noconfirm jq
        else
            echo "Error: Could not detect package manager. Install jq manually: https://jqlang.github.io/jq/download/"
            exit 1
        fi
    else
        echo ""
        echo "Install jq manually:"
        echo "  macOS:  brew install jq"
        echo "  Ubuntu: sudo apt install jq"
        echo "  Fedora: sudo dnf install jq"
        exit 1
    fi
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
echo "To uninstall:"
echo "  curl -fsSL https://kevinmaes.github.io/claudebar/uninstall.sh | bash"
echo ""
echo "  Or use the full GitHub URL:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash"
