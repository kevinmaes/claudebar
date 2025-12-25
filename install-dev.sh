#!/bin/bash

# Claude Code Statusline Installer (Dev Branch) - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/dev/install-dev.sh | bash
#
# This script installs from the dev branch for testing integrated features
# before the next release. For stable releases, use install.sh instead.

set -e

CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
RAW_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/dev/statusline.sh"

echo "Installing claudebar statusline (dev branch)..."
echo ""
echo "Note: This installs from the dev branch for testing pre-release features."
echo ""

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

# Download statusline.sh from dev branch
echo "Downloading statusline.sh from dev branch..."
curl -fsSL "$RAW_URL" -o "$STATUSLINE_SCRIPT"

# Ask for display mode preference
echo ""
echo "Choose display mode:"
echo "  1) icon  - Emoji icons 📂🌿📄 (default)"
echo "  2) label - Text labels"
echo "  3) none  - Minimal output"
echo ""
read -p "Enter choice [1-3]: " -n 1 -r < /dev/tty
echo ""

case "$REPLY" in
    2)
        MODE="label"
        ;;
    3)
        MODE="none"
        ;;
    *)
        MODE="icon"
        ;;
esac

# Update the mode in the script
sed -i.bak "s/MODE=\"\${CLAUDEBAR_MODE:-icon}\"/MODE=\"$MODE\"/" "$STATUSLINE_SCRIPT"
rm -f "$STATUSLINE_SCRIPT.bak"
echo "Display mode set to: $MODE"

# Ask about shell command installation
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
fi

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
echo "claudebar statusline installed successfully (dev branch)!"
echo ""
echo "Restart Claude Code to see your new statusline:"

case "$MODE" in
    label)
        echo "  DIR: parent/current | BRANCH: main | STAGED: 0 | ... | Context: 42% (84k/200k)"
        ;;
    none)
        echo "  parent/current | main | S: 0 | ... | 42% (84k/200k)"
        ;;
    *)
        echo "  📂 parent/current | 🌿 main | 📄 S: 0 | ... | 🧠 42% (84k/200k)"
        ;;
esac
echo ""
echo "To update to latest dev:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/dev/update-dev.sh | bash"
echo ""
echo "To switch to stable release:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash"
echo ""
echo "To uninstall:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash"
echo ""
