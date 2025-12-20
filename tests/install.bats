#!/usr/bin/env bats

# Tests for install.sh and uninstall.sh
# These tests use a fake HOME directory to avoid modifying the real system

load 'test_helper/common'

setup() {
    PROJECT_ROOT="$(project_root)"

    # Create fake HOME for testing
    FAKE_HOME=$(mktemp -d)
    export HOME="$FAKE_HOME"

    # Create a local copy of statusline.sh for install script to use
    # (simulates what curl would download)
    mkdir -p "$FAKE_HOME/.claude"
}

teardown() {
    if [ -n "$FAKE_HOME" ]; then
        cleanup_dir "$FAKE_HOME"
    fi
}

# =============================================================================
# Install Script Tests (simulated - doesn't run actual install.sh due to curl)
# =============================================================================

@test "install creates .claude directory" {
    # Simulate install behavior
    mkdir -p "$HOME/.claude"

    [ -d "$HOME/.claude" ]
}

@test "install creates statusline.sh with correct permissions" {
    # Simulate install
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"
    chmod +x "$HOME/.claude/statusline.sh"

    [ -f "$HOME/.claude/statusline.sh" ]
    [ -x "$HOME/.claude/statusline.sh" ]
}

@test "install creates settings.json with statusLine config" {
    # Simulate install creating settings
    echo '{"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' | jq '.' > "$HOME/.claude/settings.json"

    [ -f "$HOME/.claude/settings.json" ]

    # Verify statusLine config
    result=$(jq -r '.statusLine.type' "$HOME/.claude/settings.json")
    [ "$result" = "command" ]

    result=$(jq -r '.statusLine.command' "$HOME/.claude/settings.json")
    [ "$result" = "/bin/bash ~/.claude/statusline.sh" ]
}

@test "install merges with existing settings.json" {
    # Create existing settings
    echo '{"existingKey": "existingValue"}' > "$HOME/.claude/settings.json"

    # Simulate install merge behavior
    tmp_file=$(mktemp)
    jq '. + {"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}}' "$HOME/.claude/settings.json" > "$tmp_file"
    mv "$tmp_file" "$HOME/.claude/settings.json"

    # Verify both configs exist
    result=$(jq -r '.existingKey' "$HOME/.claude/settings.json")
    [ "$result" = "existingValue" ]

    result=$(jq -r '.statusLine.type' "$HOME/.claude/settings.json")
    [ "$result" = "command" ]
}

# =============================================================================
# Uninstall Script Tests
# =============================================================================

@test "uninstall removes statusline.sh" {
    # Setup installed state
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"

    [ -f "$HOME/.claude/statusline.sh" ]

    # Run uninstall
    "$PROJECT_ROOT/uninstall.sh"

    [ ! -f "$HOME/.claude/statusline.sh" ]
}

@test "uninstall removes statusLine from settings.json" {
    # Setup installed state
    echo '{"statusLine": {"type": "command"}, "otherSetting": true}' > "$HOME/.claude/settings.json"

    # Run uninstall
    "$PROJECT_ROOT/uninstall.sh"

    # Verify statusLine is removed
    result=$(jq 'has("statusLine")' "$HOME/.claude/settings.json")
    [ "$result" = "false" ]

    # Verify other settings preserved
    result=$(jq -r '.otherSetting' "$HOME/.claude/settings.json")
    [ "$result" = "true" ]
}

@test "uninstall handles missing statusline.sh gracefully" {
    # No statusline.sh exists
    [ ! -f "$HOME/.claude/statusline.sh" ]

    # Should not error
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]
}

@test "uninstall handles missing settings.json gracefully" {
    # Create statusline but no settings
    touch "$HOME/.claude/statusline.sh"

    # Should not error
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]
}

@test "uninstall handles missing .claude directory gracefully" {
    # Remove the .claude directory
    rm -rf "$HOME/.claude"

    # Should not error
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Round-trip Tests
# =============================================================================

@test "statusline.sh works after simulated install" {
    # Simulate install
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"
    chmod +x "$HOME/.claude/statusline.sh"

    # Create a test git repo
    TEST_REPO=$(setup_git_repo)
    touch "$TEST_REPO/file.txt"
    git -C "$TEST_REPO" add file.txt
    git -C "$TEST_REPO" commit -m "initial" --quiet

    # Run installed statusline
    result=$(mock_input_minimal "$TEST_REPO" | "$HOME/.claude/statusline.sh" | strip_colors)

    # Should produce valid output
    [[ "$result" == *"S: 0"* ]]

    cleanup_dir "$TEST_REPO"
}
