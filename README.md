# claudebar

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub release](https://img.shields.io/github/v/release/kevinmaes/claudebar?color=blue)](https://github.com/kevinmaes/claudebar/releases)
[![CI](https://github.com/kevinmaes/claudebar/actions/workflows/ci.yml/badge.svg)](https://github.com/kevinmaes/claudebar/actions/workflows/ci.yml)
[![Contributing](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)
[![Changelog](https://img.shields.io/badge/changelog-Keep%20a%20Changelog-orange.svg)](CHANGELOG.md)

A bash statusline for Claude Code.

```
📂 parent/current | 🌿 main | 📄 S: 0 | U: 2 | A: 1
claudebar v0.3.0 | 🤖 Sonnet 4 | 🧠 42% ▮▮▯▯▯ (84k/200k)
```

## Why claudebar?

**Lightweight & Fast** - Pure bash with no runtime dependencies beyond `jq`. No Node.js required.

**Install in Seconds** - One curl command and you're running. Built-in update checker notifies you of new releases with a simple `↑` indicator.

**Git-First Design** - See your branch, staged files, unstaged changes, and untracked files at a glance. Includes worktree support for advanced workflows.

**Visual Context Tracking** - Color-coded progress bars (▮▮▯▯▯) make it easy to monitor your context window usage. Green under 50%, yellow 50-80%, red above 80%.

**Simple Configuration** - Three display modes via a single environment variable. No complex config files to maintain.

**Hassle-Free Maintenance** - Built-in updater and uninstaller scripts. Keep your statusline current with one command.

## Install

```bash
curl -fsSL https://kevinmaes.github.io/claudebar/install.sh | bash
```

<details>
<summary>Or use the full GitHub URL</summary>

```bash
curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash
```
</details>

## Update

```bash
curl -fsSL https://kevinmaes.github.io/claudebar/update.sh | bash
```

Or use the built-in update command:

```bash
~/.claude/statusline.sh --update
```

### Update Notification

The statusline shows a yellow `↑` indicator when a newer version is available:

```
claudebar v0.2.1 ↑ | 🤖 Sonnet 4 | 🧠 42% ▮▮▯▯▯ (84k/200k)
```

Version checks are cached for 24 hours. To manually check:

```bash
~/.claude/statusline.sh --check-update
```

## Uninstall

```bash
curl -fsSL https://kevinmaes.github.io/claudebar/uninstall.sh | bash
```

## Requirements

- `jq` - JSON processor (installer will offer to install if missing)

<details>
<summary>Manual installation</summary>

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Fedora
sudo dnf install jq
```
</details>

## What it displays

<table>
  <tr>
    <th>Icon</th>
    <th>Files</th>
    <th>Meaning</th>
  </tr>
  <tr>
    <td>📂</td>
    <td></td>
    <td>Abbreviated path (last two segments)</td>
  </tr>
  <tr>
    <td>🌳</td>
    <td></td>
    <td>Git worktree indicator (only shown in worktrees)</td>
  </tr>
  <tr>
    <td>🌿</td>
    <td></td>
    <td>Current git branch (green)</td>
  </tr>
  <tr>
    <td rowspan="3" style="vertical-align: middle">📄</td>
    <td>S</td>
    <td>Staged file count</td>
  </tr>
  <tr>
    <td>U</td>
    <td>Unstaged file count</td>
  </tr>
  <tr>
    <td>A</td>
    <td>Untracked/added file count</td>
  </tr>
  <tr>
    <td>🧠</td>
    <td></td>
    <td>Context window usage (color-coded: green &lt;50%, yellow 50-80%, red &gt;80%)</td>
  </tr>
  <tr>
    <td>↑</td>
    <td></td>
    <td>Update available (yellow, shown after version when newer release exists)</td>
  </tr>
</table>

## Configuration

Set the display mode via environment variable:

```bash
export CLAUDEBAR_MODE=icon   # Default - emoji icons
export CLAUDEBAR_MODE=label  # Text labels
export CLAUDEBAR_MODE=none   # Minimal output
```

| Mode | Example |
|------|---------|
| `icon` | `📂 parent/current \| 🌿 main \| 📄 S: 0 \| U: 2 \| A: 1` |
| `label` | `DIR: parent/current \| BRANCH: main \| STAGED: 0 \| UNSTAGED: 2 \| ADDED: 1` |
| `none` | `parent/current \| main \| S: 0 \| U: 2 \| A: 1` |

Add the export to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.) to persist the setting.

## CLI Flags

| Flag | Description |
|------|-------------|
| `--version`, `-v` | Show version and exit |
| `--check-update` | Check for available updates |
| `--update` | Download and install latest version |

## Customization

After installation, edit `~/.claude/statusline.sh` to customize the statusline.

## How it works

The installer:
1. Downloads `statusline.sh` to `~/.claude/`
2. Updates `~/.claude/settings.json` with the statusline command
3. Claude Code reads JSON workspace data and pipes it to the script

## Development

### Requirements

- `bats` - Bash Automated Testing System
- `shellcheck` - Shell script linter
- `jq` - JSON processor

```bash
# macOS
brew install bats-core shellcheck jq

# Ubuntu/Debian
sudo apt install bats shellcheck jq
```

### Commands

| Command | Description |
|---------|-------------|
| `make lint` | Run shellcheck on all scripts |
| `make test` | Run full BATS test suite |
| `make preview` | Quick preview with sample JSON |
| `make install` | Run install.sh locally |
| `make update` | Run update.sh locally |
| `make uninstall` | Run uninstall.sh locally |

### Running tests

```bash
# Run all tests
make test

# Run specific test file
bats tests/statusline.bats

# Run with verbose output
bats --verbose-run tests/
```

### VS Code Extensions

Recommended extensions for working with this codebase:

| Extension | ID | Purpose |
|-----------|-----|---------|
| ShellCheck | `timonwong.shellcheck` | Linting for shell scripts |
| Bash IDE | `mads-hartmann.bash-ide-vscode` | Syntax highlighting, intellisense for `.sh` files |
| Bats | `jetmartin.bats` | Syntax highlighting for `.bats` test files |
| YAML | `redhat.vscode-yaml` | GitHub workflow files |

Install all at once:

```bash
code --install-extension timonwong.shellcheck \
     --install-extension mads-hartmann.bash-ide-vscode \
     --install-extension jetmartin.bats \
     --install-extension redhat.vscode-yaml
```

**Note:** The ShellCheck extension requires the `shellcheck` binary (see [Requirements](#requirements) above).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

[MIT](LICENSE)
