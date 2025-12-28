---
"claudebar": minor
---

Add retroactive CLI options during update

- Update script now offers interactive prompts for features introduced since your last installed version
- Added options-manifest.json to track which options were introduced in which version
- Version file persists at ~/.claude/.claudebar-installed-version for version tracking
- Added --no-prompts flag to skip prompts (with warning about potentially missed features)
- Existing user preferences (MODE, PATH_MODE) are preserved during updates
