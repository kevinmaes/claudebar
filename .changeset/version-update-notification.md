---
"claudebar": minor
---

Add version update notification to statusline

- Display version in statusline with yellow ↑ indicator when updates available
- Add CLI flags: --version, --check-update, --update
- Cache version checks for 24 hours with graceful offline handling
