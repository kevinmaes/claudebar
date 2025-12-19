#!/bin/bash

# Claude Code Statusline - claudebar
# https://github.com/kevinmaes/claudebar
#
# Displays: 📂 parent/current | 🌳 🌿 main | 📄 S: 0 | U: 2 | A: 1

# ANSI color codes
BLUE='\033[34m'
GREEN='\033[32m'
RESET='\033[0m'

# Read JSON input from Claude Code
input=$(cat)

# Get current working directory from input
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Change to the directory
cd "$cwd" 2>/dev/null || exit 0

# Get just the last two parts of the path (parent/current)
short_path=$(echo "$cwd" | awk -F'/' '{if (NF>1) print $(NF-1)"/"$NF; else print $NF}')

# Start building the status line
status="📂 ${BLUE}${short_path}${RESET}"

# Check if we're in a git repository
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Check if we're in a worktree (git-dir and git-common-dir differ)
    git_dir=$(git rev-parse --git-dir 2>/dev/null)
    git_common_dir=$(git rev-parse --git-common-dir 2>/dev/null)
    is_worktree=""
    if [ "$git_dir" != "$git_common_dir" ]; then
        is_worktree="🌳 "
    fi

    # Get current branch
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)

    if [ -n "$branch" ]; then
        status="$status | ${is_worktree}🌿 ${GREEN}${branch}${RESET}"

        # Get git status counts (skip optional locks for performance)
        git_status=$(git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)

        # Count staged files (added to index)
        staged=$(echo "$git_status" | grep "^[MADRC]" | wc -l | tr -d ' ')

        # Count unstaged files (modified but not staged)
        unstaged=$(echo "$git_status" | grep "^.[MD]" | wc -l | tr -d ' ')

        # Count untracked/added (new) files
        added=$(echo "$git_status" | grep "^??" | wc -l | tr -d ' ')

        # Show counts in S: U: A: format with file icon
        status="$status | 📄 S: $staged | U: $unstaged | A: $added"
    fi
fi

echo -e "$status"
