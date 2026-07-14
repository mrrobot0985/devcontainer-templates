# Contributing

Thanks for helping improve this template collection.

## Getting started

1. Fork the repository.
1. Clone your fork and run `git config core.hooksPath .githooks`.
1. Make your changes in a branch named `<type>/<description>` (e.g. `feat/add-template-option`).

## Development

- Use `uv` for Python tooling where applicable.
- Keep changes focused on a single template or workflow at a time.
- Run the local smoke test before pushing:

  ```bash
  ./.github/actions/smoke-test/build.sh claude-code
  ./.github/actions/smoke-test/test.sh claude-code
  ```

- Validate template JSON and shell scripts with `./scripts/local-ci.sh`.

## Submitting changes

1. Write clear, conventional commit messages (`feat:`, `fix:`, `docs:`, etc.).
1. Open a pull request using the provided template.
1. Ensure all CI checks pass.

## Releasing

This is a monorepo containing multiple dev container templates. To prevent git tag collisions, each template gets its own prefixed tag.

### Tag Format

Use `<template-name>-v<semver>` for every release. For example:

- `claude-code-v1.0.0`
- `claude-code-studio-v1.0.0`

### Why Prefixed Tags?

A single git tag namespace is shared across all templates. Without a prefix, `v1.0.0` is ambiguous — it could apply to any template. Prefixed tags keep release histories independent and readable.

### Release Steps

1. Update the `version` field in `src/<template>/devcontainer-template.json`
2. Commit the change with a conventional commit message:  
   `feat(<template>): bump version to X.Y.Z`
3. Create and push a signed tag:  
   `git tag -s <template-name>-vX.Y.Z -m "release <template> vX.Y.Z"`
4. Push the tag to trigger the release workflow:  
   `git push origin <template-name>-vX.Y.Z`

The release workflow triggers on any `*-v*` tag and publishes the template whose JSON version changed.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
