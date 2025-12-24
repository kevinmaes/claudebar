---
"claudebar": minor
---

Add dev branch workflow for pre-release testing

- CI now runs on both main and dev branches
- release.yml creates Version Packages PRs on push to dev
- deploy.yml promotes dev to main and creates GitHub Release when Version Packages PR is merged
- Added install-dev.sh and update-dev.sh scripts for testing pre-release features
- Updated README with dev branch installation documentation
