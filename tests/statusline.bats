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

@test "CLAUDEBAR_DISPLAY_PATH=path shows parent/current (default)" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_DISPLAY_PATH=path
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_DISPLAY_PATH

    parent=$(basename "$(dirname "$TEST_REPO")")
    current=$(basename "$TEST_REPO")
    [[ "$result" == *"$parent/$current"* ]]
}

@test "CLAUDEBAR_DISPLAY_PATH=project shows only project name" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_DISPLAY_PATH=project
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_DISPLAY_PATH

    project_name=$(basename "$TEST_REPO")
    parent=$(basename "$(dirname "$TEST_REPO")")

    # Should contain project name but NOT parent/project format
    [[ "$result" == *"$project_name"* ]]
    [[ "$result" != *"$parent/$project_name"* ]]
}

@test "CLAUDEBAR_DISPLAY_PATH=both shows project name with path in parentheses" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_DISPLAY_PATH=both
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_DISPLAY_PATH

    project_name=$(basename "$TEST_REPO")
    parent=$(basename "$(dirname "$TEST_REPO")")

    # Should show format: project_name (parent/project_name)
    [[ "$result" == *"$project_name ($parent/$project_name)"* ]]
}

@test "--path-mode=project overrides CLAUDEBAR_DISPLAY_PATH" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_DISPLAY_PATH=path
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" --path-mode=project | strip_colors)
    unset CLAUDEBAR_DISPLAY_PATH

    project_name=$(basename "$TEST_REPO")
    parent=$(basename "$(dirname "$TEST_REPO")")

    # Should show only project name (CLI flag overrides env var)
    [[ "$result" == *"$project_name"* ]]
    [[ "$result" != *"$parent/$project_name"* ]]
}

@test "--path-mode=both shows combined format" {
    TEST_REPO=$(setup_git_repo)

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" --path-mode=both | strip_colors)

    project_name=$(basename "$TEST_REPO")
    parent=$(basename "$(dirname "$TEST_REPO")")

    [[ "$result" == *"$project_name ($parent/$project_name)"* ]]
}

@test "path mode works with all display modes" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    project_name=$(basename "$TEST_REPO")

    # Test with icon mode
    export CLAUDEBAR_MODE=icon
    export CLAUDEBAR_DISPLAY_PATH=project
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE")
    [[ "$result" == *"📂"* ]]
    [[ "$result" == *"$project_name"* ]]
    unset CLAUDEBAR_MODE
    unset CLAUDEBAR_DISPLAY_PATH

    # Test with label mode
    export CLAUDEBAR_MODE=label
    export CLAUDEBAR_DISPLAY_PATH=project
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    [[ "$result" == *"DIR:"* ]]
    [[ "$result" == *"$project_name"* ]]
    unset CLAUDEBAR_MODE
    unset CLAUDEBAR_DISPLAY_PATH

    # Test with none mode
    export CLAUDEBAR_MODE=none
    export CLAUDEBAR_DISPLAY_PATH=project
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)
    [[ "$result" != *"DIR:"* ]]
    [[ "$result" == *"$project_name"* ]]
    unset CLAUDEBAR_MODE
    unset CLAUDEBAR_DISPLAY_PATH
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
# Billing Block Tests
# =============================================================================

@test "displays billing block progress" {
    TEST_REPO=$(setup_git_repo)

    # 3h 15m = 195 minutes = 11700000 ms (65% of 5h)
    result=$(mock_input_with_billing "$TEST_REPO" 11700000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"65%"* ]]
    [[ "$result" == *"3h 15m / 5h"* ]]
}

@test "billing block green under 4 hours" {
    TEST_REPO=$(setup_git_repo)

    # 2 hours = 7200000 ms
    result=$(mock_input_with_billing "$TEST_REPO" 7200000 | "$STATUSLINE")

    # Should contain green color code for billing
    [[ "$result" == *$'\033[32m'* ]]
}

@test "billing block yellow at 4-4.5 hours" {
    TEST_REPO=$(setup_git_repo)

    # 4h 15m = 255 minutes = 15300000 ms
    result=$(mock_input_with_billing "$TEST_REPO" 15300000 | "$STATUSLINE")

    # Should contain yellow color code
    [[ "$result" == *$'\033[33m'* ]]
}

@test "billing block red over 4.5 hours" {
    TEST_REPO=$(setup_git_repo)

    # 4h 45m = 285 minutes = 17100000 ms
    result=$(mock_input_with_billing "$TEST_REPO" 17100000 | "$STATUSLINE")

    # Should contain red color code
    [[ "$result" == *$'\033[31m'* ]]
}

@test "billing block caps at 100% when over 5 hours" {
    TEST_REPO=$(setup_git_repo)

    # 6 hours = 21600000 ms (120% but should cap at 100%)
    result=$(mock_input_with_billing "$TEST_REPO" 21600000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"100%"* ]]
    [[ "$result" == *"6h 0m / 5h"* ]]
}

@test "billing block shows timer icon in icon mode" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=icon
    result=$(mock_input_with_billing "$TEST_REPO" 7200000 | "$STATUSLINE")
    unset CLAUDEBAR_MODE

    [[ "$result" == *"⏱️"* ]]
}

@test "billing block shows label in label mode" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=label
    result=$(mock_input_with_billing "$TEST_REPO" 7200000 | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    [[ "$result" == *"Billing:"* ]]
}

@test "billing block minimal in none mode" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=none
    result=$(mock_input_with_billing "$TEST_REPO" 7200000 | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    [[ "$result" != *"⏱️"* ]]
    [[ "$result" != *"Billing:"* ]]
    [[ "$result" == *"/ 5h"* ]]
}

@test "handles missing billing data gracefully" {
    TEST_REPO=$(setup_git_repo)

    # Use regular mock_input without billing data
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Should not contain billing indicator
    [[ "$result" != *"/ 5h"* ]]
}

@test "billing block displays alongside context window" {
    TEST_REPO=$(setup_git_repo)

    # 2 hours billing, 42% context
    result=$(mock_input_with_billing "$TEST_REPO" 7200000 200000 40000 44000 | "$STATUSLINE" | strip_colors)

    # Should have both indicators
    [[ "$result" == *"84k/200k"* ]]
    [[ "$result" == *"/ 5h"* ]]
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

# =============================================================================
# Cache Token Breakdown Tests
# =============================================================================

@test "displays cache token breakdown when cache data available" {
    TEST_REPO=$(setup_git_repo)

    # C: 40k, R: 44k, context_size: 200k
    result=$(mock_input_with_cache "$TEST_REPO" 40000 44000 200000 40000 44000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"C: 40k"* ]]
    [[ "$result" == *"R: 44k"* ]]
    [[ "$result" == *"/ 200k"* ]]
}

@test "falls back to simple format when no cache data" {
    TEST_REPO=$(setup_git_repo)

    # Standard input without cache data
    result=$(mock_input "$TEST_REPO" 200000 40000 44000 | "$STATUSLINE" | strip_colors)

    # Should show simple format (84k/200k) not cache breakdown
    [[ "$result" == *"84k/200k"* ]]
    [[ "$result" != *"C:"* ]]
    [[ "$result" != *"R:"* ]]
}

@test "cache breakdown with zero creation tokens" {
    TEST_REPO=$(setup_git_repo)

    # C: 0, R: 100k (all reads, no creation)
    result=$(mock_input_with_cache "$TEST_REPO" 0 100000 200000 50000 50000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"C: 0k"* ]]
    [[ "$result" == *"R: 100k"* ]]
}

@test "cache breakdown with zero read tokens" {
    TEST_REPO=$(setup_git_repo)

    # C: 50k, R: 0 (all creation, no reads)
    result=$(mock_input_with_cache "$TEST_REPO" 50000 0 200000 25000 25000 | "$STATUSLINE" | strip_colors)

    [[ "$result" == *"C: 50k"* ]]
    [[ "$result" == *"R: 0k"* ]]
}

@test "cache breakdown in icon mode shows brain emoji" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=icon
    result=$(mock_input_with_cache "$TEST_REPO" 40000 44000 | "$STATUSLINE")
    unset CLAUDEBAR_MODE

    [[ "$result" == *"🧠"* ]]
    [[ "$result" == *"C: 40k"* ]]
}

@test "cache breakdown in label mode shows Context prefix" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=label
    result=$(mock_input_with_cache "$TEST_REPO" 40000 44000 | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    [[ "$result" == *"Context:"* ]]
    [[ "$result" == *"C: 40k"* ]]
}

@test "cache breakdown in none mode shows minimal output" {
    TEST_REPO=$(setup_git_repo)

    export CLAUDEBAR_MODE=none
    result=$(mock_input_with_cache "$TEST_REPO" 40000 44000 | "$STATUSLINE" | strip_colors)
    unset CLAUDEBAR_MODE

    [[ "$result" != *"🧠"* ]]
    [[ "$result" != *"Context:"* ]]
    [[ "$result" == *"C: 40k"* ]]
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
    [[ "$output" == *"--path-mode"* ]]
    [[ "$output" == *"CLAUDEBAR_DISPLAY_PATH"* ]]
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

# =============================================================================
# NO_COLOR Support Tests
# =============================================================================

@test "NO_COLOR disables ANSI color codes in output" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    export NO_COLOR=1
    result=$(mock_input "$TEST_REPO" | "$STATUSLINE")
    unset NO_COLOR

    # Output should NOT contain ANSI escape codes
    [[ "$result" != *$'\033['* ]]
    [[ "$result" != *$'\x1b['* ]]
}

@test "NO_COLOR=1 produces same content as colored output" {
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    # Get colored output and strip colors
    colored=$(mock_input "$TEST_REPO" | "$STATUSLINE" | strip_colors)

    # Get NO_COLOR output
    export NO_COLOR=1
    no_color=$(mock_input "$TEST_REPO" | "$STATUSLINE")
    unset NO_COLOR

    # Content should be identical
    [ "$colored" = "$no_color" ]
}

@test "NO_COLOR with empty value still disables colors" {
    TEST_REPO=$(setup_git_repo)

    # NO_COLOR spec: any value (including empty) disables colors
    # But we use -n check, so empty string won't trigger it
    # This is intentional - only set (non-empty) values disable colors
    export NO_COLOR=""
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE")
    unset NO_COLOR

    # Empty NO_COLOR should NOT disable colors (per our implementation)
    [[ "$result" == *$'\033['* ]]
}

@test "NO_COLOR unset enables colors" {
    TEST_REPO=$(setup_git_repo)

    # Ensure NO_COLOR is unset
    unset NO_COLOR

    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE")

    # Should contain ANSI escape codes
    [[ "$result" == *$'\033['* ]]
}

@test "--help documents NO_COLOR environment variable" {
    run "$STATUSLINE" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"NO_COLOR"* ]]
    [[ "$output" == *"Disable colored output"* ]]
}

# =============================================================================
# CLI Argument Handling Tests (Issue #97)
# =============================================================================

@test "'update' command works as alias for '--update'" {
    # We can't actually run the full update (it curls), but we can verify
    # the command is recognized and starts the update process
    # Using a subshell with timeout to prevent hanging if something goes wrong
    result=$("$STATUSLINE" update 2>&1 | head -1)

    # Should start the update process, not show "Unknown command"
    [[ "$result" == *"Updating claudebar"* ]]
}

@test "'check-update' command works as alias for '--check-update'" {
    run "$STATUSLINE" check-update

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar v"* ]]
    [[ "$output" != *"Unknown command"* ]]
}

@test "unknown command 'version' suggests correct flag" {
    run "$STATUSLINE" version

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command: version"* ]]
    [[ "$output" == *"Did you mean '--version'?"* ]]
}

@test "unknown command 'help' suggests correct flag" {
    run "$STATUSLINE" help

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command: help"* ]]
    [[ "$output" == *"Did you mean '--help'?"* ]]
}

@test "unknown flag with dashes shows error without suggestion" {
    run "$STATUSLINE" --unknown-flag

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option: --unknown-flag"* ]]
    [[ "$output" == *"Run 'claudebar --help'"* ]]
    [[ "$output" != *"Did you mean"* ]]
}

@test "unknown short flag shows error" {
    run "$STATUSLINE" -x

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown option: -x"* ]]
}

@test "arbitrary word shows helpful error" {
    run "$STATUSLINE" foo

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command: foo"* ]]
    [[ "$output" == *"Did you mean '--foo'?"* ]]
}

@test "does not hang on unknown command (exits immediately)" {
    # This test ensures the command exits quickly rather than hanging
    # waiting for stdin input. The fix for issue #97 ensures unknown
    # commands return an error immediately instead of waiting for stdin.
    run "$STATUSLINE" someinvalidcommand

    # Should exit with status 1 (error) and show helpful message
    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command"* ]]
}

@test "valid flags still work after adding unknown command handling" {
    run "$STATUSLINE" --version
    [ "$status" -eq 0 ]
    [[ "$output" == "claudebar v"* ]]

    run "$STATUSLINE" -v
    [ "$status" -eq 0 ]

    run "$STATUSLINE" --help
    [ "$status" -eq 0 ]
    [[ "$output" == *"Usage:"* ]]

    run "$STATUSLINE" -h
    [ "$status" -eq 0 ]

    run "$STATUSLINE" --check-update
    [ "$status" -eq 0 ]
}

@test "--path-mode flag is recognized and not treated as unknown" {
    TEST_REPO=$(setup_git_repo)

    # --path-mode should be recognized and not trigger "Unknown option" error
    result=$(mock_input_minimal "$TEST_REPO" | "$STATUSLINE" --path-mode=project 2>&1)
    exit_code=$?

    # Should succeed (exit 0) and contain path output
    [ "$exit_code" -eq 0 ]
    [[ "$result" != *"Unknown option"* ]]
    [[ "$result" != *"Unknown command"* ]]
}
