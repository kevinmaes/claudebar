# Changesets

This folder stores changeset files that describe upcoming releases.

## Creating a Changeset

```bash
pnpm changeset
```

Follow the prompts to select a version bump type and describe your change.

## Version Types

- **patch** (0.0.x): Bug fixes, docs updates, minor improvements
- **minor** (0.x.0): New features, backward-compatible changes
- **major** (x.0.0): Breaking changes

## Workflow

1. Make changes in a PR
2. Run `pnpm changeset` and commit the generated file
3. When merged, a "Version Packages" PR is auto-created
4. Merging the Version PR creates a GitHub release

See [changesets docs](https://github.com/changesets/changesets) for more info.
