#!/bin/bash

# Claude Code Statusline - claudebar
# https://github.com/kevinmaes/claudebar
#
# Displays (two lines):
#   Line 1: 📂 parent/current | 🌿 main | 📄 S: 0 | U: 2 | A: 1
#   Line 2: 🤖 Sonnet 4 | 🧠 42% ▮▮▯▯▯ (84k/200k)
#
# Configuration:
#   CLAUDEBAR_MODE: icon (default), label, or none
#   Set via: export CLAUDEBAR_MODE=label

# ANSI color codes
BLUE='\033[34m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

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

# Read JSON input from Claude Code
input=$(cat)

# Get current working directory from input
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Get model display name
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# Change to the directory
cd "$cwd" 2>/dev/null || exit 0

# Get just the last two parts of the path (parent/current)
short_path=$(echo "$cwd" | awk -F'/' '{if (NF>1) print $(NF-1)"/"$NF; else print $NF}')

# Start building the status line
if [ -n "$ICON_DIR" ]; then
    status="${ICON_DIR} ${BLUE}${short_path}${RESET}"
else
    status="${BLUE}${short_path}${RESET}"
fi

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check if we're in a worktree (git-dir and git-common-dir differ)
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    is_worktree=""
    if [ "$git_dir" != "$git_common_dir" ]; then
        is_worktree="${ICON_WORKTREE} "
    fi

    # Get current branch
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        if [ -n "$ICON_BRANCH" ]; then
            status="$status | ${is_worktree}${ICON_BRANCH} ${GREEN}${branch}${RESET}"
        else
            status="$status | ${is_worktree}${GREEN}${branch}${RESET}"
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

# Second line: Claude Code specific info (model + context)
line2=""

# Model display
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

    # Build progress bar (5 segments)
    bar_width=5
    filled=$((percent * bar_width / 100))
    empty=$((bar_width - filled))
    bar="${CTX_COLOR}"
    for ((i=0; i<filled; i++)); do bar+="▮"; done
    bar+="${RESET}"
    for ((i=0; i<empty; i++)); do bar+="▯"; done

    # Format: 42% ▮▮▯▯▯ (84k/200k)
    if [ -n "$line2" ]; then
        separator=" | "
    else
        separator=""
    fi

    if [ "$MODE" = "label" ]; then
        line2="${line2}${separator}Context: ${CTX_COLOR}${percent}%${RESET} ${bar} (${current_k}k/${total_k}k)"
    elif [ "$MODE" = "none" ]; then
        line2="${line2}${separator}${CTX_COLOR}${percent}%${RESET} ${bar} (${current_k}k/${total_k}k)"
    else
        line2="${line2}${separator}🧠 ${CTX_COLOR}${percent}%${RESET} ${bar} (${current_k}k/${total_k}k)"
    fi
fi

# Append second line if it has content
if [ -n "$line2" ]; then
    status="$status\n$line2"
fi

echo -e "$status"
