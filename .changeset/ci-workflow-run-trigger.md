---
"claudebar": patch
---

Fix CI not running on Version Packages PRs from changeset-release branches

When the changesets bot creates or updates a Version Packages PR using GITHUB_TOKEN, GitHub's security feature prevents workflows from triggering. This fix adds a `workflow_run` trigger to the CI workflow that runs tests after the Release workflow completes, and reports status back to the PR.
