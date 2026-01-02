---
"claudebar": minor
---

Remove misleading context window percentage and progress bar display

Claude Code's statusline API only provides cumulative session tokens, not current context window usage. This caused the percentage to show impossible values (e.g., 299%) after context auto-compaction.

Changes:
- Removed percentage display and progress bar from context section
- Changed icon from 🧠 to 💾 to reflect "Cache" instead of "Context"
- Now displays only cache tokens when available: `💾 C: 40k | R: 44k`
- Added note in README explaining the limitation

The feature will be restored when Claude Code provides accurate context data.
See: https://github.com/anthropics/claude-code/issues/13783
