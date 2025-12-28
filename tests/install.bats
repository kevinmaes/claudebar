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

    # Simulate install merge behavior (new * operator preserves nested settings)
    tmp_file=$(mktemp)
    jq '.statusLine = ((.statusLine // {}) * {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"})' "$HOME/.claude/settings.json" > "$tmp_file"
    mv "$tmp_file" "$HOME/.claude/settings.json"

    # Verify both configs exist
    result=$(jq -r '.existingKey' "$HOME/.claude/settings.json")
    [ "$result" = "existingValue" ]

    result=$(jq -r '.statusLine.type' "$HOME/.claude/settings.json")
    [ "$result" = "command" ]
}

@test "install preserves existing statusLine settings like padding" {
    # Create existing claudebar config with padding
    echo '{"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh", "padding": 0}}' > "$HOME/.claude/settings.json"

    # Simulate install merge behavior (should preserve padding)
    tmp_file=$(mktemp)
    jq '.statusLine = ((.statusLine // {}) * {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"})' "$HOME/.claude/settings.json" > "$tmp_file"
    mv "$tmp_file" "$HOME/.claude/settings.json"

    # Verify padding is preserved
    result=$(jq -r '.statusLine.padding' "$HOME/.claude/settings.json")
    [ "$result" = "0" ]

    # Verify command is still correct
    result=$(jq -r '.statusLine.command' "$HOME/.claude/settings.json")
    [ "$result" = "/bin/bash ~/.claude/statusline.sh" ]
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

@test "uninstall removes statusLine from settings.json when it is claudebar" {
    # Setup installed state with claudebar command
    echo '{"statusLine": {"type": "command", "command": "/bin/bash ~/.claude/statusline.sh"}, "otherSetting": true}' > "$HOME/.claude/settings.json"

    # Run uninstall
    "$PROJECT_ROOT/uninstall.sh"

    # Verify statusLine is removed
    result=$(jq 'has("statusLine")' "$HOME/.claude/settings.json")
    [ "$result" = "false" ]

    # Verify other settings preserved
    result=$(jq -r '.otherSetting' "$HOME/.claude/settings.json")
    [ "$result" = "true" ]
}

@test "uninstall skips statusLine when it is not claudebar" {
    # Setup with a different statusLine (not claudebar)
    echo '{"statusLine": {"type": "command", "command": "~/my-custom-statusline.sh"}, "otherSetting": true}' > "$HOME/.claude/settings.json"

    # Run uninstall
    run "$PROJECT_ROOT/uninstall.sh"

    # Should succeed
    [ "$status" -eq 0 ]

    # Verify statusLine is NOT removed
    result=$(jq 'has("statusLine")' "$HOME/.claude/settings.json")
    [ "$result" = "true" ]

    # Verify the command is unchanged
    result=$(jq -r '.statusLine.command' "$HOME/.claude/settings.json")
    [ "$result" = "~/my-custom-statusline.sh" ]

    # Verify output mentions skipping
    [[ "$output" == *"statusLine is not claudebar"* ]]
}

@test "uninstall removes version cache file" {
    # Setup cache file
    echo "1234567890|0.3.0" > "$HOME/.claude/.claudebar-version-cache"

    [ -f "$HOME/.claude/.claudebar-version-cache" ]

    # Run uninstall
    "$PROJECT_ROOT/uninstall.sh"

    # Verify cache file is removed
    [ ! -f "$HOME/.claude/.claudebar-version-cache" ]
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

@test "uninstall removes claudebar command from .zshrc" {
    # Setup: create .zshrc with claudebar function
    cat > "$HOME/.zshrc" << 'EOF'
# existing config
export PATH="/usr/local/bin:$PATH"

# claudebar command
claudebar() { ~/.claude/statusline.sh "$@"; }

# more config
alias ll="ls -la"
EOF

    # Run uninstall
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]

    # Verify claudebar function is removed
    ! grep -q "# claudebar command" "$HOME/.zshrc"
    ! grep -q "claudebar()" "$HOME/.zshrc"

    # Verify other config is preserved
    grep -q 'export PATH=' "$HOME/.zshrc"
    grep -q 'alias ll=' "$HOME/.zshrc"
}

@test "uninstall removes claudebar command from .bashrc" {
    # Setup: create .bashrc with claudebar function
    cat > "$HOME/.bashrc" << 'EOF'
# existing config
export EDITOR=vim

# claudebar command
claudebar() { ~/.claude/statusline.sh "$@"; }
EOF

    # Run uninstall
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]

    # Verify claudebar function is removed
    ! grep -q "# claudebar command" "$HOME/.bashrc"

    # Verify other config is preserved
    grep -q 'export EDITOR=vim' "$HOME/.bashrc"
}

@test "uninstall handles missing shell command silently" {
    # Setup: create shell configs without claudebar
    echo 'export PATH="/usr/local/bin:$PATH"' > "$HOME/.zshrc"
    echo 'export EDITOR=vim' > "$HOME/.bashrc"

    # Run uninstall - should not error or mention claudebar
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]

    # Should NOT mention removing claudebar command
    [[ "$output" != *"Removed claudebar command"* ]]
}

# =============================================================================
# Round-trip Tests
# =============================================================================

# =============================================================================
# Version File Tests
# =============================================================================

@test "install creates version file with correct version" {
    # Simulate install behavior
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"

    # Extract and save version (same as install.sh does)
    INSTALLED_VERSION=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$HOME/.claude/statusline.sh" | cut -d'"' -f2)
    echo "$INSTALLED_VERSION" > "$HOME/.claude/.claudebar-installed-version"

    # Verify file exists and contains version
    [ -f "$HOME/.claude/.claudebar-installed-version" ]

    # Version should match what's in statusline.sh
    result=$(cat "$HOME/.claude/.claudebar-installed-version")
    expected=$(grep -o 'CLAUDEBAR_VERSION="[^"]*"' "$PROJECT_ROOT/statusline.sh" | cut -d'"' -f2)
    [ "$result" = "$expected" ]
}

@test "uninstall removes version file" {
    # Setup: create version file
    echo "0.6.0" > "$HOME/.claude/.claudebar-installed-version"
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"

    [ -f "$HOME/.claude/.claudebar-installed-version" ]

    # Run uninstall
    "$PROJECT_ROOT/uninstall.sh"

    # Verify version file is removed
    [ ! -f "$HOME/.claude/.claudebar-installed-version" ]
}

@test "uninstall handles missing version file gracefully" {
    # Setup: no version file
    cp "$PROJECT_ROOT/statusline.sh" "$HOME/.claude/statusline.sh"
    [ ! -f "$HOME/.claude/.claudebar-installed-version" ]

    # Should not error
    run "$PROJECT_ROOT/uninstall.sh"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Options Manifest Tests
# =============================================================================

@test "options-manifest.json is valid JSON" {
    run jq '.' "$PROJECT_ROOT/options-manifest.json"
    [ "$status" -eq 0 ]
}

@test "options-manifest.json has required schema version" {
    result=$(jq -r '.schemaVersion' "$PROJECT_ROOT/options-manifest.json")
    [ "$result" = "1.0" ]
}

@test "options-manifest.json has options array" {
    result=$(jq '.options | type' "$PROJECT_ROOT/options-manifest.json")
    [ "$result" = '"array"' ]
}

@test "options-manifest.json options have required fields" {
    # Each option must have id, introducedInVersion, and description
    result=$(jq '[.options[] | select(.id == null or .introducedInVersion == null or .description == null)] | length' "$PROJECT_ROOT/options-manifest.json")
    [ "$result" = "0" ]
}

@test "options-manifest.json versions are valid semver format" {
    # All introducedInVersion values should match X.Y.Z pattern
    result=$(jq -r '.options[].introducedInVersion' "$PROJECT_ROOT/options-manifest.json" | grep -v '^[0-9]\+\.[0-9]\+\.[0-9]\+$' | wc -l | tr -d ' ')
    [ "$result" = "0" ]
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
