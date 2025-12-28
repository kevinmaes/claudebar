---
"claudebar": patch
---

Add manual CI triggers for Version Packages PRs

Adds two ways to trigger CI on PRs that don't automatically run checks:
- Manual trigger from GitHub Actions tab (workflow_dispatch)
- Comment "/run-ci" on a PR to trigger tests (issue_comment)
