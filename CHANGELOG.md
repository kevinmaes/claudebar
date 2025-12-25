# claudebar

## 0.5.1

### Patch Changes

- 759c515: Fix release workflow to use `pnpm run version` instead of `pnpm version`
- cc1335b: fix: sync CLAUDEBAR_VERSION in statusline.sh during release process
- 97947a6: Add example status lines for each display mode option during installation. Changed "(default)" to "(recommended)" for the icon mode. The selected example is echoed back after choosing.

## 0.5.0

### Minor Changes

- a6ef3ae: Add dev branch workflow for pre-release testing

  - CI now runs on both main and dev branches
  - release.yml creates Version Packages PRs on push to dev
  - deploy.yml promotes dev to main and creates GitHub Release when Version Packages PR is merged
  - Added install-dev.sh and update-dev.sh scripts for testing pre-release features
  - Updated README with dev branch installation documentation

- 18c6c28: Add optional global `claudebar` command during installation

  - New `--help`/`-h` flag shows version and available commands
  - Install script now prompts to add `claudebar` shell function
  - Uninstall script cleans up shell function from `.zshrc` and `.bashrc`
  - Users can run `claudebar --version`, `claudebar --help`, etc. from anywhere

### Patch Changes

- d6007c7: Preserve existing statusLine settings like padding in preview.sh
- 533b6aa: Only remove statusLine config during uninstall if it belongs to claudebar
- d2b81f9: Sync install-dev.sh with install.sh to include optional shell command installation
- 7fdc8b3: Move version display to end of status line and only show when update available. Version info now displays as `↑ vX.X.X` only when a newer version is detected, reducing visual clutter.
- f9117da: Warn before overwriting existing statusLine configuration during install

## 0.4.0

### Minor Changes

- 590f066: feat: show worktree name separately from branch name

  When in a git worktree, the statusline now displays the worktree directory name separately from the tracked branch name:

  - Before: 🌳 🌿 feature-branch
  - After: 🌳 worktree-dir | 🌿 feature-branch

  This provides clearer semantic meaning:

  - Worktree = WHERE you are (the directory/workspace)
  - Branch = WHAT branch that worktree is tracking

### Patch Changes

- bc687b0: Add web fetch permission for npm registry and ignore analysis documents
- 2b1fb03: Rename test.yml workflow to ci.yml (runs both linting and tests)

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
