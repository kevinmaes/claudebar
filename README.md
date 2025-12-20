# claudebar

A bash statusline for Claude Code.

```
📂 parent/current | 🌿 main | 📄 S: 0 | U: 2 | A: 1 | 🧠 42% (84k/200k)
```

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

## Uninstall

```bash
curl -fsSL https://kevinmaes.github.io/claudebar/uninstall.sh | bash
```

## Requirements

- `jq` - JSON processor

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Fedora
sudo dnf install jq
```

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
