# Contributing to Claudebar

Thanks for your interest in contributing!

## Quick Start

1. Fork and clone the repo
2. Install dependencies: `pnpm install`
3. Make your changes
4. Run checks: `make lint && make test`
5. Submit a PR

## Development

### Requirements

- `bats-core` - Bash Automated Testing System
- `shellcheck` - Shell script linter
- `jq` - JSON processor

```bash
# macOS
brew install bats-core shellcheck jq

# Ubuntu/Debian
sudo apt install bats shellcheck jq
```

### Commands

| Command | Description |
|---------|-------------|
| `make lint` | Run shellcheck on all scripts |
| `make test` | Run full BATS test suite |
| `make preview` | Quick preview with sample JSON |

### Testing Changes

```bash
# Run all tests
make test

# Run specific test file
bats tests/statusline.bats

# Preview the statusline
make preview
```

## Code Style

- Follow [ShellCheck](https://www.shellcheck.net/) recommendations
- Use lowercase variable names for local variables
- Use UPPERCASE for constants and environment variables
- Add comments for non-obvious logic

## Pull Request Guidelines

1. Create a feature branch: `feature/description-kebab-case`
2. Keep changes focused and atomic
3. Include tests for new functionality
4. Update README if adding user-facing changes
5. Ensure `make lint` and `make test` pass

## Versioning

This project uses [changesets](https://github.com/changesets/changesets) for version management:

```bash
pnpm changeset        # Create a changeset
pnpm changeset version  # Apply changesets
```

## Questions?

Open an issue for questions or discussion.
