# claudebar

A bash statusline for Claude Code.

```
📂 parent/current | 🌳 🌿 main | 📄 S: 0 | U: 2 | A: 1
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
</table>

## Customization

After installation, edit `~/.claude/statusline.sh` to customize the statusline.

## How it works

The installer:
1. Downloads `statusline.sh` to `~/.claude/`
2. Updates `~/.claude/settings.json` with the statusline command
3. Claude Code reads JSON workspace data and pipes it to the script
