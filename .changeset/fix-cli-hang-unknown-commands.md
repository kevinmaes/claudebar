---
"claudebar": patch
---

Fix CLI hang when using commands like 'update' without dashes

Previously, running `claudebar update` (without dashes) would cause the command to hang indefinitely because it fell through to the stdin-reading code path. Now:

- `claudebar update` works as an alias for `claudebar --update`
- `claudebar check-update` works as an alias for `claudebar --check-update`
- Unknown commands show helpful error messages (e.g., "Did you mean '--version'?")
- Unknown flags show clear error messages

Added comprehensive tests to prevent regression.
