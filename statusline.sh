#!/bin/bash

# Claude Code Statusline - claudebar
# https://github.com/kevinmaes/claudebar
#
# Displays (two lines):
#   Line 1: 📂 parent/current | 🌿 main | 📄 S: 0 | U: 2 | A: 1
#   Line 2: 🤖 Sonnet 4 | 🧠 42% ▮▮▯▯▯ (84k/200k) | ↑ v0.3.1 (only if update available)
#
# Configuration:
#   CLAUDEBAR_MODE: icon (default), label, or none
#   CLAUDEBAR_DISPLAY_PATH: path (default), project, or both
#   Set via: export CLAUDEBAR_MODE=label
#
# CLI flags:
#   --version, -v          Show version and exit
#   --help, -h             Show usage and available options
#   --check-update         Check for updates (bypass cache)
#   --update               Download and install latest version
#   --path-mode=MODE       Override CLAUDEBAR_DISPLAY_PATH (path|project|both)

# Version (updated by changesets)
CLAUDEBAR_VERSION="0.9.1"

# Cache settings
CACHE_FILE="$HOME/.claude/.claudebar-version-cache"
CLAUDE_CODE_CACHE_FILE="$HOME/.claude/.claude-code-version-cache"
CACHE_TTL=86400  # 24 hours in seconds

# Feature flags
SHOW_CLAUDE_UPDATE="${CLAUDEBAR_SHOW_CLAUDE_UPDATE:-true}"

# Path display mode (path, project, both)
PATH_MODE="${CLAUDEBAR_DISPLAY_PATH:-path}"

# ANSI color codes (disabled when NO_COLOR is set)
# See https://no-color.org/
if [ -n "${NO_COLOR:-}" ]; then
    BLUE=''
    GREEN=''
    YELLOW=''
    RED=''
    RESET=''
else
    BLUE='\033[34m'
    GREEN='\033[32m'
    YELLOW='\033[33m'
    RED='\033[31m'
    RESET='\033[0m'
fi

# Display mode (icon, label, none)
MODE="${CLAUDEBAR_MODE:-icon}"

# Mode-specific labels
case "$MODE" in
    label)
        ICON_DIR="DIR:"
        ICON_WORKTREE="TREE"
        ICON_BRANCH="BRANCH:"
        ICON_MODEL="MODEL:"
        ICON_FILES=""
        LABEL_STAGED="STAGED:"
        LABEL_UNSTAGED="UNSTAGED:"
        LABEL_ADDED="ADDED:"
        ;;
    none)
        ICON_DIR=""
        ICON_WORKTREE="[wt]"
        ICON_BRANCH=""
        ICON_MODEL=""
        ICON_FILES=""
        LABEL_STAGED="S:"
        LABEL_UNSTAGED="U:"
        LABEL_ADDED="A:"
        ;;
    *)  # icon (default)
        ICON_DIR="📂"
        ICON_WORKTREE="🌳"
        ICON_BRANCH="🌿"
        ICON_MODEL="🤖"
        ICON_FILES="📄"
        LABEL_STAGED="S:"
        LABEL_UNSTAGED="U:"
        LABEL_ADDED="A:"
        ;;
esac

# Compare semver versions: returns 0 if $1 > $2
version_gt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
}

# Get installed Claude Code version
get_claude_code_version() {
    local version=""

    # Method 1: Check VSCode extension directory
    if [ -d "$HOME/.vscode/extensions" ]; then
        # Find the latest anthropic.claude-code extension
        # shellcheck disable=SC2012  # ls is safe here; extension names are predictable
        version=$(ls -1d "$HOME/.vscode/extensions"/anthropic.claude-code-* 2>/dev/null \
            | sort -V | tail -1 \
            | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # Method 2: Check Cursor extension directory (fallback)
    if [ -z "$version" ] && [ -d "$HOME/.cursor/extensions" ]; then
        # shellcheck disable=SC2012  # ls is safe here; extension names are predictable
        version=$(ls -1d "$HOME/.cursor/extensions"/anthropic.claude-code-* 2>/dev/null \
            | sort -V | tail -1 \
            | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # Method 3: Try claude CLI (fallback)
    if [ -z "$version" ]; then
        version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    echo "$version"
}

# Check for Claude Code updates with caching
# shellcheck disable=SC2120  # Function accepts optional "force" argument
check_claude_code_updates() {
    local now remote_version cached_time cached_version
    now=$(date +%s)

    # Read cache if exists
    if [ -f "$CLAUDE_CODE_CACHE_FILE" ]; then
        cached_time=$(cut -d'|' -f1 "$CLAUDE_CODE_CACHE_FILE" 2>/dev/null)
        cached_version=$(cut -d'|' -f2 "$CLAUDE_CODE_CACHE_FILE" 2>/dev/null)

        # Use cache if fresh (unless force check)
        if [ "${1:-}" != "force" ] && [ -n "$cached_time" ] && [ $((now - cached_time)) -lt $CACHE_TTL ]; then
            echo "$cached_version"
            return
        fi
    fi

    # Fetch remote version from VS Code marketplace (timeout 2s, silent)
    remote_version=$(curl -fsSL --connect-timeout 2 \
        -H "Accept: application/json;api-version=3.0-preview.1" \
        -H "Content-Type: application/json" \
        -X POST \
        "https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery" \
        -d '{"filters":[{"criteria":[{"filterType":7,"value":"anthropic.claude-code"}]}],"flags":914}' 2>/dev/null \
        | jq -r '.results[0].extensions[0].versions[0].version // empty' 2>/dev/null)

    # Update cache
    if [ -n "$remote_version" ]; then
        echo "${now}|${remote_version}" > "$CLAUDE_CODE_CACHE_FILE" 2>/dev/null
        echo "$remote_version"
    elif [ -n "$cached_version" ]; then
        echo "$cached_version"  # Use stale cache if fetch fails
    fi
}

# Check for updates with caching
check_for_updates() {
    local now remote_version cached_time cached_version
    now=$(date +%s)

    # Read cache if exists
    if [ -f "$CACHE_FILE" ]; then
        cached_time=$(cut -d'|' -f1 "$CACHE_FILE" 2>/dev/null)
        cached_version=$(cut -d'|' -f2 "$CACHE_FILE" 2>/dev/null)

        # Use cache if fresh (unless force check)
        if [ "${1:-}" != "force" ] && [ -n "$cached_time" ] && [ $((now - cached_time)) -lt $CACHE_TTL ]; then
            echo "$cached_version"
            return
        fi
    fi

    # Fetch remote version (timeout 2s, silent)
    remote_version=$(curl -fsSL --connect-timeout 2 \
        "https://raw.githubusercontent.com/kevinmaes/claudebar/main/package.json" 2>/dev/null \
        | jq -r '.version // empty' 2>/dev/null)

    # Update cache
    if [ -n "$remote_version" ]; then
        echo "${now}|${remote_version}" > "$CACHE_FILE" 2>/dev/null
        echo "$remote_version"
    elif [ -n "$cached_version" ]; then
        echo "$cached_version"  # Use stale cache if fetch fails
    fi
}

# Handle CLI flags before reading stdin
# Check for --path-mode flag (can be combined with other flags)
for arg in "$@"; do
    case "$arg" in
        --path-mode=*)
            PATH_MODE="${arg#--path-mode=}"
            ;;
    esac
done

case "${1:-}" in
    --version|-v)
        echo "claudebar v$CLAUDEBAR_VERSION"
        exit 0
        ;;
    --help|-h)
        echo "claudebar v$CLAUDEBAR_VERSION"
        echo ""
        echo "Usage: claudebar [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --version, -v          Show installed version"
        echo "  --help, -h             Show this help message"
        echo "  --check-update         Check if an update is available"
        echo "  --update               Download and install the latest version"
        echo "  --path-mode=MODE       Override path display (path|project|both)"
        echo ""
        echo "Environment Variables:"
        echo "  CLAUDEBAR_MODE         Display mode: icon (default), label, none"
        echo "  CLAUDEBAR_DISPLAY_PATH Path display: path (default), project, both"
        echo "  NO_COLOR               Disable colored output (any value)"
        exit 0
        ;;
    --check-update|check-update)
        echo "claudebar v$CLAUDEBAR_VERSION"
        remote_version=$(check_for_updates force)
        if [ -n "$remote_version" ]; then
            if version_gt "$remote_version" "$CLAUDEBAR_VERSION"; then
                echo "Update available: v$remote_version"
                echo "Run: claudebar --update"
            else
                echo "You're up to date!"
            fi
        else
            echo "Could not check for updates (offline?)"
        fi
        exit 0
        ;;
    --update|update)
        echo "Updating claudebar..."
        curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/update.sh | bash
        exit $?
        ;;
    --path-mode=*)
        # Valid flag, already processed above - continue to normal execution
        ;;
    -*)
        # Unknown flag starting with dash
        echo "Unknown option: $1"
        echo "Run 'claudebar --help' for usage information."
        exit 1
        ;;
    ?*)
        # Non-empty argument without dash (like 'update' instead of '--update')
        echo "Unknown command: $1"
        echo "Did you mean '--$1'?"
        echo "Run 'claudebar --help' for usage information."
        exit 1
        ;;
esac

# Read JSON input from Claude Code
input=$(cat)

# Get current working directory from input
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Get model display name
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Change to the directory
cd "$cwd" 2>/dev/null || exit 0

# Get path display based on PATH_MODE
short_path=$(echo "$cwd" | awk -F'/' '{if (NF>1) print $(NF-1)"/"$NF; else print $NF}')
project_name=$(basename "$cwd")

case "$PATH_MODE" in
    project)
        display_path="$project_name"
        ;;
    both)
        display_path="$project_name ($short_path)"
        ;;
    *)  # path (default)
        display_path="$short_path"
        ;;
esac

# Start building the status line
if [ -n "$ICON_DIR" ]; then
    status="${ICON_DIR} ${BLUE}${display_path}${RESET}"
else
    status="${BLUE}${display_path}${RESET}"
fi

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check if we're in a worktree (git-dir and git-common-dir differ)
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)

    # Get current branch
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        # If in a worktree, show worktree name separately
        if [ "$git_dir" != "$git_common_dir" ]; then
            worktree_name=$(basename "$cwd")
            if [ -n "$ICON_WORKTREE" ]; then
                status="$status | ${ICON_WORKTREE} ${GREEN}${worktree_name}${RESET}"
            else
                status="$status | ${GREEN}${worktree_name}${RESET}"
            fi
        fi

        # Show branch
        if [ -n "$ICON_BRANCH" ]; then
            status="$status | ${ICON_BRANCH} ${GREEN}${branch}${RESET}"
        else
            status="$status | ${GREEN}${branch}${RESET}"
        fi

        # Get git status counts (skip optional locks for performance)
        git_status=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)

        # Count staged files (added to index)
        staged=$(echo "$git_status" | grep -c "^[MADRC]" || true)

        # Count unstaged files (modified but not staged)
        unstaged=$(echo "$git_status" | grep -c "^.[MD]" || true)

        # Count untracked/added (new) files
        added=$(echo "$git_status" | grep -c "^??" || true)

        # Show counts in S: U: A: format with file icon
        # Colors: Green=staged (ready), Yellow=unstaged (modified), Red=untracked (new)
        if [ -n "$ICON_FILES" ]; then
            status="$status | ${ICON_FILES} ${GREEN}${LABEL_STAGED} $staged${RESET} | ${YELLOW}${LABEL_UNSTAGED} $unstaged${RESET} | ${RED}${LABEL_ADDED} $added${RESET}"
        else
            status="$status | ${GREEN}${LABEL_STAGED} $staged${RESET} | ${YELLOW}${LABEL_UNSTAGED} $unstaged${RESET} | ${RED}${LABEL_ADDED} $added${RESET}"
        fi
    fi
fi

# Second line: Claude Code specific info (model + context + update indicator)
line2=""

# Model display (first)
if [ -n "$model_name" ]; then
    if [ -n "$ICON_MODEL" ]; then
        line2="${ICON_MODEL} ${model_name}"
    else
        line2="${model_name}"
    fi
fi

# Context window visualization
context_size=$(echo "$input" | jq -r '.context_window.context_window_size // empty')

if [ -n "$context_size" ] && [ "$context_size" -gt 0 ] 2>/dev/null; then
    # Calculate total tokens used
    current_tokens=$(echo "$input" | jq '.context_window | (.total_input_tokens // 0) + (.total_output_tokens // 0)')
    percent=$((current_tokens * 100 / context_size))

    # Get cache token breakdown (graceful fallback to 0 if not present)
    cache_creation=$(echo "$input" | jq '.context_window.current_usage.cache_creation_input_tokens // 0')
    cache_read=$(echo "$input" | jq '.context_window.current_usage.cache_read_input_tokens // 0')

    # Color based on usage threshold
    if [ "$percent" -ge 80 ]; then
        CTX_COLOR="$RED"
    elif [ "$percent" -ge 50 ]; then
        CTX_COLOR="$YELLOW"
    else
        CTX_COLOR="$GREEN"
    fi

    # Token counts in k format
    current_k=$((current_tokens / 1000))
    total_k=$((context_size / 1000))
    cache_creation_k=$((cache_creation / 1000))
    cache_read_k=$((cache_read / 1000))

    # Build progress bar (5 segments)
    bar_width=5
    filled=$((percent * bar_width / 100))
    empty=$((bar_width - filled))
    bar="${CTX_COLOR}"
    for ((i=0; i<filled; i++)); do bar+="▮"; done
    bar+="${RESET}"
    for ((i=0; i<empty; i++)); do bar+="▯"; done

    # Format: 42% ▮▮▯▯▯ (C: 40k | R: 44k / 200k) if cache data available
    # Otherwise fallback: 42% ▮▮▯▯▯ (84k/200k)
    if [ -n "$line2" ]; then
        separator=" | "
    else
        separator=""
    fi

    # Determine display format based on cache data availability
    if [ "$cache_creation" -gt 0 ] || [ "$cache_read" -gt 0 ]; then
        # Cache data available - show breakdown
        token_display="(C: ${cache_creation_k}k | R: ${cache_read_k}k / ${total_k}k)"
    else
        # No cache data - fallback to simple format
        token_display="(${current_k}k/${total_k}k)"
    fi

    if [ "$MODE" = "label" ]; then
        line2="${line2}${separator}Context: ${CTX_COLOR}${percent}%${RESET} ${bar} ${token_display}"
    elif [ "$MODE" = "none" ]; then
        line2="${line2}${separator}${CTX_COLOR}${percent}%${RESET} ${bar} ${token_display}"
    else
        line2="${line2}${separator}🧠 ${CTX_COLOR}${percent}%${RESET} ${bar} ${token_display}"
    fi
fi

# Billing block visualization (5-hour blocks)
FIVE_HOURS_MS=18000000
duration_ms=$(echo "$input" | jq -r '.cost.total_duration_ms // empty')

if [ -n "$duration_ms" ] && [ "$duration_ms" -gt 0 ] 2>/dev/null; then
    # Calculate percentage of 5-hour block
    billing_percent=$((duration_ms * 100 / FIVE_HOURS_MS))
    # Cap at 100% for display
    [ "$billing_percent" -gt 100 ] && billing_percent=100

    # Convert to hours and minutes
    total_minutes=$((duration_ms / 60000))
    hours=$((total_minutes / 60))
    minutes=$((total_minutes % 60))

    # Color based on thresholds: green < 4h, yellow 4-4.5h, red > 4.5h
    if [ "$total_minutes" -ge 270 ]; then
        BILL_COLOR="$RED"
    elif [ "$total_minutes" -ge 240 ]; then
        BILL_COLOR="$YELLOW"
    else
        BILL_COLOR="$GREEN"
    fi

    # Build progress bar (5 segments)
    bar_width=5
    filled=$((billing_percent * bar_width / 100))
    empty=$((bar_width - filled))
    billing_bar="${BILL_COLOR}"
    for ((i=0; i<filled; i++)); do billing_bar+="▮"; done
    billing_bar+="${RESET}"
    for ((i=0; i<empty; i++)); do billing_bar+="▯"; done

    # Format time display
    time_display="${hours}h ${minutes}m"

    # Add separator if line2 has content
    if [ -n "$line2" ]; then
        separator=" | "
    else
        separator=""
    fi

    if [ "$MODE" = "label" ]; then
        line2="${line2}${separator}Billing: ${BILL_COLOR}${billing_percent}%${RESET} ${billing_bar} (${time_display} / 5h)"
    elif [ "$MODE" = "none" ]; then
        line2="${line2}${separator}${BILL_COLOR}${billing_percent}%${RESET} ${billing_bar} (${time_display} / 5h)"
    else
        line2="${line2}${separator}⏱️ ${BILL_COLOR}${billing_percent}%${RESET} ${billing_bar} (${time_display} / 5h)"
    fi
fi

# Update indicator (only shown when newer version available)
remote_version=$(check_for_updates 2>/dev/null)
if [ -n "$remote_version" ] && version_gt "$remote_version" "$CLAUDEBAR_VERSION"; then
    if [ -n "$line2" ]; then
        line2="${line2} | ${YELLOW}↑ claudebar v${remote_version}${RESET}"
    else
        line2="${YELLOW}↑ claudebar v${remote_version}${RESET}"
    fi
fi

# Claude Code update indicator (only shown when newer version available)
if [ "$SHOW_CLAUDE_UPDATE" = "true" ]; then
    installed_claude_version=$(get_claude_code_version 2>/dev/null)
    if [ -n "$installed_claude_version" ]; then
        latest_claude_version=$(check_claude_code_updates 2>/dev/null)
        if [ -n "$latest_claude_version" ] && version_gt "$latest_claude_version" "$installed_claude_version"; then
            if [ -n "$line2" ]; then
                line2="${line2} | ${YELLOW}↑ CC v${latest_claude_version}${RESET}"
            else
                line2="${YELLOW}↑ CC v${latest_claude_version}${RESET}"
            fi
        fi
    fi
fi

# Append second line if it has content
if [ -n "$line2" ]; then
    status="$status\n$line2"
fi

echo -e "$status"
