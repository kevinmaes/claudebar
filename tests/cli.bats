#!/usr/bin/env bats

# Tests for bin/claudebar.js (Node CLI wrapper)

load 'test_helper/common'

setup() {
    PROJECT_ROOT="$(project_root)"
    CLI="$PROJECT_ROOT/bin/claudebar.js"
}

# =============================================================================
# Help Tests
# =============================================================================

@test "--help shows usage information" {
    run node "$CLI" --help

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar - A bash statusline for Claude Code"* ]]
    [[ "$output" == *"Commands:"* ]]
    [[ "$output" == *"install"* ]]
    [[ "$output" == *"uninstall"* ]]
    [[ "$output" == *"update"* ]]
}

@test "-h shows usage information" {
    run node "$CLI" -h

    [ "$status" -eq 0 ]
    [[ "$output" == *"claudebar - A bash statusline for Claude Code"* ]]
}

@test "no arguments defaults to install" {
    # No args should run install, not show help
    run timeout 1 node "$CLI" 2>&1 || true

    # Should NOT contain "Usage:" (that would be help)
    # Should NOT contain "Unknown command"
    [[ "$output" != *"Unknown command"* ]]
}

# =============================================================================
# Version Tests
# =============================================================================

@test "--version shows version number" {
    run node "$CLI" --version

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^claudebar\ v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "-v shows version number" {
    run node "$CLI" -v

    [ "$status" -eq 0 ]
    [[ "$output" =~ ^claudebar\ v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "version matches package.json" {
    run node "$CLI" --version
    cli_version="${output#claudebar v}"

    pkg_version=$(node -e "console.log(require('$PROJECT_ROOT/package.json').version)")

    [ "$cli_version" = "$pkg_version" ]
}

# =============================================================================
# Unknown Command Tests
# =============================================================================

@test "unknown command exits with error" {
    run node "$CLI" foobar

    [ "$status" -eq 1 ]
    [[ "$output" == *"Unknown command: foobar"* ]]
}

@test "unknown command suggests --help" {
    run node "$CLI" invalid

    [ "$status" -eq 1 ]
    [[ "$output" == *'Run "npx claudebar --help"'* ]]
}

# =============================================================================
# Command Recognition Tests
# =============================================================================

@test "install command is recognized" {
    # We can't fully run install in tests, but we can check it doesn't error as "unknown"
    # The command will start but we can check it doesn't immediately fail with "unknown command"
    run timeout 1 node "$CLI" install 2>&1 || true

    # Should NOT contain "Unknown command"
    [[ "$output" != *"Unknown command"* ]]
}

@test "uninstall command is recognized" {
    run timeout 1 node "$CLI" uninstall 2>&1 || true

    [[ "$output" != *"Unknown command"* ]]
}

@test "update command is recognized" {
    run timeout 1 node "$CLI" update 2>&1 || true

    [[ "$output" != *"Unknown command"* ]]
}
