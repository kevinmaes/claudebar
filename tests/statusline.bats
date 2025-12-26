#!/usr/bin/env bats

# Tests for statusline.sh

load 'test_helper/common'

setup() {
    PROJECT_ROOT="$(project_root)"
    STATUSLINE="$PROJECT_ROOT/statusline.sh"
}

teardown() {
    if [ -n "$TEST_REPO" ]; then
        cleanup_dir "$TEST_REPO"
    fi
    if [ -n "$TEST_DIR" ]; then
        cleanup_dir "$TEST_DIR"
    fi
}

# =============================================================================
# Path Display Tests
# =============================================================================

@test "displays short path (parent/current)" {
    TEST_REPO=$(setup_git_repo)

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Should contain the last two path components
    parent=$(basename "$(dirname "$TEST_REPO")")
    current=$(basename "$TEST_REPO")
    [[ "$result" == *"$parent/$current"* ]]
}

# =============================================================================
# Git Branch Detection Tests
# =============================================================================

@test "displays git branch name" {
    TEST_REPO=$(setup_git_repo)
    # Create initial commit so we have a branch
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"main"* ]] || [[ "$result" == *"master"* ]]
}

@test "displays custom branch name" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet
    git -C "$TEST_REPO" checkout -b feature/test-branch --quiet

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"feature/test-branch"* ]]
}

# =============================================================================
# Git Status Count Tests
# =============================================================================

@test "shows staged file count" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    # Stage a new file
    echo "new content" > "$TEST_REPO/staged.txt"
    git -C "$TEST_REPO" add staged.txt

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"S: 1"* ]]
}

@test "shows unstaged file count" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    # Modify tracked file without staging
    echo "modified" >> "$TEST_REPO/file.txt"

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"U: 1"* ]]
}

@test "shows untracked/added file count" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    # Create untracked files
    touch "$TEST_REPO/untracked1.txt"
    touch "$TEST_REPO/untracked2.txt"

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"A: 2"* ]]
}

@test "shows zero counts for clean repo" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"S: 0"* ]]
    [[ "$result" == *"U: 0"* ]]
    [[ "$result" == *"A: 0"* ]]
}

# =============================================================================
# Display Mode Tests
# =============================================================================

@test "icon mode shows emoji icons" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    export CLAUDEBAR_MODE=icon
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE")
    unset CLAUDEBAR_MODE

    [[ "$result" == *"📂"* ]]
    [[ "$result" == *"🌿"* ]]
    [[ "$result" == *"📄"* ]]
    [[ "$result" == *"🧠"* ]]
}

@test "label mode shows text labels" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    export CLAUDEBAR_MODE=label
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    [[ "$result" == *"DIR:"* ]]
    [[ "$result" == *"BRANCH:"* ]]
    [[ "$result" == *"STAGED:"* ]]
    [[ "$result" == *"Context:"* ]]
}

@test "none mode shows minimal output" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    export CLAUDEBAR_MODE=none
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    # Should NOT contain emojis or full labels
    [[ "$result" != *"📂"* ]]
    [[ "$result" != *"DIR:"* ]]
    [[ "$result" != *"BRANCH:"* ]]
    # Should still have S: U: A:
    [[ "$result" == *"S:"* ]]
}

# =============================================================================
# Context Window Tests
# =============================================================================

@test "displays context window usage" {
    TEST_REPO=$(setup_git_repo)

    # 84k tokens out of 200k = 42%
    result=$(mock_input "$TEST_REPO" 200000 40000 44000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"42%"* ]]
    [[ "$result" == *"84k/200k"* ]]
}

@test "context window green when under 50%" {
    TEST_REPO=$(setup_git_repo)

    # 20k tokens out of 200k = 10%
    result=$(mock_input "$TEST_REPO" 200000 10000 10000 | "$STATUSLINE")

    # Should contain green color code
    [[ "$result" == *$'\033[32m'* ]]
}

@test "context window yellow when 50-79%" {
    TEST_REPO=$(setup_git_repo)

    # 120k tokens out of 200k = 60%
    result=$(mock_input "$TEST_REPO" 200000 60000 60000 | "$STATUSLINE")

    # Should contain yellow color code
    [[ "$result" == *$'\033[33m'* ]]
}

@test "context window red when 80%+" {
    TEST_REPO=$(setup_git_repo)

    # 180k tokens out of 200k = 90%
    result=$(mock_input "$TEST_REPO" 200000 90000 90000 | "$STATUSLINE")

    # Should contain red color code
    [[ "$result" == *$'\033[31m'* ]]
}

# =============================================================================
# Edge Case Tests
# =============================================================================

@test "handles non-git directory gracefully" {
    TEST_DIR=$(setup_temp_dir)

    result=$(mock_input_minimal "$TEST_DIR" | "$STATUSLINE" | strip_colors)

    # Should show path but no git info
    current=$(basename "$TEST_DIR")
    [[ "$result" == *"$current"* ]]
    # Should NOT show branch or status counts
    [[ "$result" != *"S:"* ]]
}

@test "handles missing context window data" {
    TEST_REPO=$(setup_git_repo)

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Should not contain context percentage
    [[ "$result" != *"%"* ]]
}

@test "handles empty git repo (no commits)" {
    TEST_REPO=$(setup_git_repo)

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Should show path but may not show branch (no commits yet)
    current=$(basename "$TEST_REPO")
    [[ "$result" == *"$current"* ]]
}

# =============================================================================
# Version and Update Tests
# =============================================================================

@test "--version flag outputs version" {
    run "$STATUSLINE" --version

    [ "$status" -eq 0 ]
    [[ "$output" == "claudebar v"* ]]
}

@test "-v flag outputs version" {
    run "$STATUSLINE" -v

    [ "$status" -eq 0 ]
    [[ "$output" == "claudebar v"* ]]
}

@test "--check-update shows current version" {
    run "$STATUSLINE" --check-update

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar v"* ]]
}

@test "--help flag outputs usage information" {
    run "$STATUSLINE" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar v"* ]]
    [[ "$output" == *"Usage:"* ]]
    [[ "$output" == *"--version"* ]]
    [[ "$output" == *"--help"* ]]
    [[ "$output" == *"--check-update"* ]]
    [[ "$output" == *"--update"* ]]
}

@test "-h flag outputs usage information" {
    run "$STATUSLINE" -h

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar v"* ]]
    [[ "$output" == *"Usage:"* ]]
}

@test "statusline hides version when no update available" {
    TEST_REPO=$(setup_git_repo)

    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Version should NOT appear in normal output (only shown when update available)
    [[ "$result" != *"claudebar v"* ]]
}

@test "version comparison: newer version detected" {
    # Define the function inline (same logic as in statusline.sh)
    version_gt() {
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
    }

    version_gt "1.0.0" "0.9.0" && result="greater" || result="not_greater"
    [ "$result" = "greater" ]

    version_gt "0.2.2" "0.2.1" && result="greater" || result="not_greater"
    [ "$result" = "greater" ]
}

@test "version comparison: same version not detected as newer" {
    version_gt() {
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
    }

    version_gt "0.2.1" "0.2.1" && result="greater" || result="not_greater"
    [ "$result" = "not_greater" ]
}

@test "version comparison: older version not detected as newer" {
    version_gt() {
        [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$1" ]
    }

    version_gt "0.1.0" "0.2.0" && result="greater" || result="not_greater"
    [ "$result" = "not_greater" ]
}

# =============================================================================
# Claude Code Update Tests
# =============================================================================

@test "get_claude_code_version detects version from VSCode extensions" {
    # Create mock VSCode extension directory
    MOCK_VSCODE="$BATS_TMPDIR/mock_vscode"
    mkdir -p "$MOCK_VSCODE/anthropic.claude-code-2.0.75-darwin-arm64"

    # Define the function with custom path
    get_claude_code_version() {
        local version=""
        if [ -d "$MOCK_VSCODE" ]; then
            version=$(ls -1d "$MOCK_VSCODE"/anthropic.claude-code-* 2>/dev/null \
                | sort -V | tail -1 \
                | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
        echo "$version"
    }

    result=$(get_claude_code_version)
    [ "$result" = "2.0.75" ]

    rm -rf "$MOCK_VSCODE"
}

@test "get_claude_code_version returns latest when multiple versions installed" {
    # Create mock VSCode extension directory with multiple versions
    MOCK_VSCODE="$BATS_TMPDIR/mock_vscode_multi"
    mkdir -p "$MOCK_VSCODE/anthropic.claude-code-2.0.53-darwin-arm64"
    mkdir -p "$MOCK_VSCODE/anthropic.claude-code-2.0.75-darwin-arm64"

    get_claude_code_version() {
        local version=""
        if [ -d "$MOCK_VSCODE" ]; then
            version=$(ls -1d "$MOCK_VSCODE"/anthropic.claude-code-* 2>/dev/null \
                | sort -V | tail -1 \
                | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
        echo "$version"
    }

    result=$(get_claude_code_version)
    [ "$result" = "2.0.75" ]

    rm -rf "$MOCK_VSCODE"
}

@test "CLAUDEBAR_SHOW_CLAUDE_UPDATE=false disables Claude Code update check" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    export CLAUDEBAR_SHOW_CLAUDE_UPDATE=false
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_SHOW_CLAUDE_UPDATE

    # Should not contain Claude Code update indicator
    [[ "$result" != *"↑ CC"* ]]
}

@test "Claude Code cache file uses separate path from claudebar cache" {
    # The script should define separate cache files
    run grep "CLAUDE_CODE_CACHE_FILE" "$STATUSLINE"

    [ "$status" -eq 0 ]
    [[ "$output" == *"claude-code-version-cache"* ]]
}
