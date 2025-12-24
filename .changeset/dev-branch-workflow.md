---
"claudebar": minor
---

Add dev branch workflow for pre-release testing

- CI now runs on both main and dev branches
- Updated release.yml to use changesets/action for Version Packages PRs on dev
- When Version Packages PR is merged, automatically promotes dev to main and creates release
- Added install-dev.sh and update-dev.sh scripts for testing pre-release features
- Updated README with dev branch installation documentation
