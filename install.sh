#!/bin/bash

# Claude Code Statusline Installer - claudebar
# https://github.com/kevinmaes/claudebar
#
# Usage: curl -fsSL https://kevinmaes.github.io/claudebar/install.sh | bash
# or curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash

set -e

# Parse command line flags
SKIP_SHELL_PROMPT=false
for arg in "$@"; do
    case "$arg" in
        --skip-shell-prompt)
            SKIP_SHELL_PROMPT=true
            ;;
    esac
done

CLAUDE_DIR="$HOME/.claude"
STATUSLINE_SCRIPT="$CLAUDE_DIR/statusline.sh"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
VERSION_FILE="$CLAUDE_DIR/.claudebar-installed-version"
RAW_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/statusline.sh"
PACKAGE_JSON_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/package.json"
UPDATE_URL="https://raw.githubusercontent.com/kevinmaes/claudebar/main/update.sh"

# Compare semver versions - returns 0 if $1 > $2
version_gt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

# Check for existing installation
if [ -f "$STATUSLINE_SCRIPT" ]; then
    # Get installed version
    if [ -f "$VERSION_FILE" ]; then
        INSTALLED_VERSION=$(cat "$VERSION_FILE")
    else
        INSTALLED_VERSION=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$STATUSLINE_SCRIPT" 2>/dev/null | cut -d'"' -f2 || echo "unknown")
    fi

    # Fetch latest version from package.json
    LATEST_VERSION=$(curl -fsSL "$PACKAGE_JSON_URL" 2>/dev/null | grep '"version"' | head -1 | sed 's/.*"version": *"\([^"]*\)".*/\1/' || echo "")

    echo ""
    if [ -n "$LATEST_VERSION" ] && version_gt "$LATEST_VERSION" "$INSTALLED_VERSION"; then
        echo "claudebar v$INSTALLED_VERSION is installed. (v$LATEST_VERSION available)"
    else
        echo "claudebar v$INSTALLED_VERSION is already installed."
    fi
    echo ""
    echo "What would you like to do?"
    echo ""
    echo "  1) Update       - Update to latest (preserves config)"
    echo "  2) Reinstall    - Fresh install (reconfigure all options)"
    echo "  3) Cancel       - Exit without changes"
    echo ""
    read -p "Enter choice [1-3]: " -n 1 -r < /dev/tty
    echo ""

    case "$REPLY" in
        1)
            echo ""
            echo "Running update..."
            # Execute update script
            curl -fsSL "$UPDATE_URL" | bash
            exit 0
            ;;
        2)
            echo ""
            echo "Proceeding with fresh install..."
            ;;
        *)
            echo ""
            echo "Installation cancelled."
            exit 0
            ;;
    esac
fi

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

# Ask for display mode preference
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
read -p "Enter choice [1-3]: " -n 1 -r < /dev/tty
echo ""

case "$REPLY" in
    2)
        MODE="label"
        EXAMPLE="DIR: parent/current | BRANCH: main | STAGED: 0 | ... | Context: 42% (84k/200k)"
        ;;
    3)
        MODE="none"
        EXAMPLE="parent/current | main | S: 0 | ... | 42% (84k/200k)"
        ;;
    *)
        MODE="icon"
        EXAMPLE="📂 parent/current | 🌿 main | 📄 S: 0 | ... | 🧠 42% (84k/200k)"
        ;;
esac

# Update the mode in the script
sed -i.bak "s/MODE=\"\${CLAUDEBAR_MODE:-icon}\"/MODE=\"$MODE\"/" "$STATUSLINE_SCRIPT"
rm -f "$STATUSLINE_SCRIPT.bak"
echo ""
echo "Display mode set to: $MODE"
echo "  $EXAMPLE"

# Ask for path display mode preference
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
read -p "Enter choice [1-3]: " -n 1 -r < /dev/tty
echo ""

case "$REPLY" in
    2)
        PATH_MODE="path"
        PATH_EXAMPLE="📂 kevinmaes/claudebar"
        ;;
    3)
        PATH_MODE="both"
        PATH_EXAMPLE="📂 claudebar (kevinmaes/claudebar)"
        ;;
    *)
        PATH_MODE="project"
        PATH_EXAMPLE="📂 claudebar"
        ;;
esac

# Update the path mode in the script
sed -i.bak "s/PATH_MODE=\"\${CLAUDEBAR_DISPLAY_PATH:-path}\"/PATH_MODE=\"$PATH_MODE\"/" "$STATUSLINE_SCRIPT"
rm -f "$STATUSLINE_SCRIPT.bak"
echo ""
echo "Path display set to: $PATH_MODE"
echo "  $PATH_EXAMPLE"

# Ask about shell command installation (skip for npx installs)
if [ "$SKIP_SHELL_PROMPT" = false ]; then
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
    # Check for existing non-claudebar statusLine configuration
    existing_command=$(jq -r '.statusLine.command // ""' "$SETTINGS_FILE")
    if [ -n "$existing_command" ] && \
       [[ "$existing_command" != *"claudebar"* ]] && \
       [[ "$existing_command" != *".claude/statusline.sh"* ]]; then
        echo ""
        echo "Warning: An existing statusLine configuration was found:"
        echo "  command: $existing_command"
        echo ""
        read -p "Overwrite with claudebar? [y/N] " -n 1 -r < /dev/tty
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled. Your existing statusLine was preserved."
            exit 0
        fi
    fi

    # Merge statusLine config while preserving existing settings like padding
    tmp_file=$(mktemp)
    jq '.statusLine = ((.statusLine // {}) * {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"})' "$SETTINGS_FILE" > "$tmp_file"
    mv "$tmp_file" "$SETTINGS_FILE"
fi

# Save installed version for future update comparisons
INSTALLED_VERSION=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$STATUSLINE_SCRIPT" | cut -d'"' -f2)
echo "$INSTALLED_VERSION" > "$CLAUDE_DIR/.claudebar-installed-version"

echo ""
echo "claudebar statusline installed successfully!"
echo ""
echo "Restart Claude Code to see your new statusline:"
echo "  $EXAMPLE"
echo ""
echo "To uninstall:"
echo "  curl -fsSL https://kevinmaes.github.io/claudebar/uninstall.sh | bash"
echo ""
echo "  Or use the full GitHub URL:"
echo "  curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash"
