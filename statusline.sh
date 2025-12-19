#!/bin/bash

# Claude Code Statusline - claudebar
# https://github.com/kevinmaes/claudebar
#
# Displays: 📂 parent/current | 🌳 🌿 main | 📄 S: 0 | U: 2 | A: 1
#
# Configuration:
#   CLAUDEBAR_MODE: icon (default), label, or none
#   Set via: export CLAUDEBAR_MODE=label

# ANSI color codes
BLUE='\033[34m'
GREEN='\033[32m'
RESET='\033[0m'

# Display mode (icon, label, none)
MODE="${CLAUDEBAR_MODE:-icon}"

# Mode-specific labels
case "$MODE" in
    label)
        ICON_DIR="DIR:"
        ICON_WORKTREE="TREE"
        ICON_BRANCH="BRANCH:"
        ICON_FILES=""
        LABEL_STAGED="STAGED:"
        LABEL_UNSTAGED="UNSTAGED:"
        LABEL_ADDED="ADDED:"
        ;;
    none)
        ICON_DIR=""
        ICON_WORKTREE="[wt]"
        ICON_BRANCH=""
        ICON_FILES=""
        LABEL_STAGED="S:"
        LABEL_UNSTAGED="U:"
        LABEL_ADDED="A:"
        ;;
    *)  # icon (default)
        ICON_DIR="📂"
        ICON_WORKTREE="🌳"
        ICON_BRANCH="🌿"
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
        staged=$(echo "$git_status" | grep "^[MADRC]" | wc -l | tr -d ' ')

        # Count unstaged files (modified but not staged)
        unstaged=$(echo "$git_status" | grep "^.[MD]" | wc -l | tr -d ' ')

        # Count untracked/added (new) files
        added=$(echo "$git_status" | grep "^??" | wc -l | tr -d ' ')

        # Show counts in S: U: A: format with file icon
        if [ -n "$ICON_FILES" ]; then
            status="$status | ${ICON_FILES} ${LABEL_STAGED} $staged | ${LABEL_UNSTAGED} $unstaged | ${LABEL_ADDED} $added"
        else
            status="$status | ${LABEL_STAGED} $staged | ${LABEL_UNSTAGED} $unstaged | ${LABEL_ADDED} $added"
        fi
    fi
fi

echo -e "$status"
