---
"claudebar": minor
---

feat: show worktree name separately from branch name

When in a git worktree, the statusline now displays the worktree directory name separately from the tracked branch name:
- Before: 🌳 🌿 feature-branch
- After: 🌳 worktree-dir | 🌿 feature-branch

This provides clearer semantic meaning:
- Worktree = WHERE you are (the directory/workspace)
- Branch = WHAT branch that worktree is tracking
