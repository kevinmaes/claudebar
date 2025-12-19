# claudebar

A bash statusline for Claude Code.

```
📂 parent/current | 🌳 🌿 main | 📄 S: 0 | U: 2 | A: 1
```

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/install.sh | bash
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/kevinmaes/claudebar/main/uninstall.sh | bash
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

| Icon | Meaning |
|------|---------|
| 📂 | Abbreviated path (last two segments) |
| 🌳 | Git worktree indicator (only shown in worktrees) |
| 🌿 | Current git branch (green) |
| 📄 S: | Staged file count |
| U: | Unstaged file count |
| A: | Untracked/added file count |

## Customization

After installation, edit `~/.claude/statusline.sh` to customize the statusline.

## How it works

The installer:
1. Downloads `statusline.sh` to `~/.claude/`
2. Updates `~/.claude/settings.json` with the statusline command
3. Claude Code reads JSON workspace data and pipes it to the script
