# claudebar

## 0.3.1

### Patch Changes

- 5d1ba26: Add open source governance files

  - Add MIT LICENSE
  - Add CONTRIBUTING.md with development guidelines
  - Add README badges (License, Release, CI, Contributing, Changelog)

## 0.3.0

### Minor Changes

- 7c7affd: Add version update notification to statusline

  - Display version in statusline with yellow ↑ indicator when updates available
  - Add CLI flags: --version, --check-update, --update
  - Cache version checks for 24 hours with graceful offline handling

## 0.2.1

### Patch Changes

- 5a90f76: Fix release workflow to automatically create git tags and GitHub releases after Version Packages PR merges

## 0.2.0

### Minor Changes

- 2309c0c: Add model display to statusline with two-line layout. Line 1 shows folder/branch/files, Line 2 shows model name and context usage. Also adds preview.sh for local developer testing.

### Patch Changes

- 136ba22: Add changesets release automation for GitHub releases
