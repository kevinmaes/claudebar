---
"claudebar": minor
---

Add option to display project name instead of path

- New `CLAUDEBAR_DISPLAY_PATH` environment variable with three modes:
  - `path` (default): shows abbreviated path (parent/current)
  - `project` (recommended): shows only the folder name
  - `both`: shows project name with path in parentheses
- New `--path-mode=MODE` CLI flag to override the environment variable
- Project name is derived from the folder name (last path segment)
- Recommended for working with multiple projects where parent/current format is confusing
