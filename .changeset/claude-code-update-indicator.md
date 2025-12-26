---
"claudebar": minor
---

Add Claude Code update availability indicator

- Show `↑ CC v2.1.0` when a newer version of Claude Code is available in the VS Code marketplace
- Detect installed version from VS Code/Cursor extension directories or claude CLI
- Cache marketplace checks for 24 hours
- Configurable via `CLAUDEBAR_SHOW_CLAUDE_UPDATE` environment variable (default: true)
