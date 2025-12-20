#!/bin/bash

# Common test helper functions for claudebar tests

# Create a temporary git repository for testing
setup_git_repo() {
    TEST_REPO=$(mktemp -d)
    git -C "$TEST_REPO" init --quiet
    git -C "$TEST_REPO" config user.email "test@example.com"
    git -C "$TEST_REPO" config user.name "Test User"
    echo "$TEST_REPO"
}

# Create a temporary directory (non-git)
setup_temp_dir() {
    mktemp -d
}

# Clean up temporary directory
cleanup_dir() {
    local dir="$1"
    if [ -n "$dir" ] && [ -d "$dir" ]; then
        rm -rf "$dir"
    fi
}

# Generate mock JSON input for statusline.sh
mock_input() {
    local cwd="$1"
    local context_size="${2:-200000}"
    local input_tokens="${3:-40000}"
    local output_tokens="${4:-44000}"

    cat <<EOF
{
    "workspace": {
        "current_dir": "$cwd"
    },
    "context_window": {
        "context_window_size": $context_size,
        "total_input_tokens": $input_tokens,
        "total_output_tokens": $output_tokens
    }
}
EOF
}

# Generate minimal JSON input (no context window)
mock_input_minimal() {
    local cwd="$1"
    cat <<EOF
{
    "workspace": {
        "current_dir": "$cwd"
    }
}
EOF
}

# Strip ANSI color codes from output for easier assertion
strip_colors() {
    sed 's/\x1b\[[0-9;]*m//g'
}

# Get the project root directory
project_root() {
    cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd
}
