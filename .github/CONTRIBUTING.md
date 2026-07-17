# Contributing

Thanks for helping improve this template collection.

## Getting started

1. Fork the repository.
1. Clone your fork and run `git config core.hooksPath .githooks`.
1. Make your changes in a branch named `<type>/<description>` (e.g., `feat/add-template-option`).

## Repository layout

| Directory                       | Purpose                                                                                 |
| ------------------------------- | --------------------------------------------------------------------------------------- |
| `src/`                          | One directory per publishable dev container template.                                   |
| `packages/create-devcontainer/` | The `npx @mrrobot0985/create-devcontainer` helper and its hard-coded template registry. |
| `scripts/`                      | Local development and validation scripts.                                               |
| `test/`                         | Unit tests for scripts and per-template smoke tests.                                    |
| `.github/workflows/`            | CI/CD pipelines.                                                                        |
| `.github/actions/smoke-test/`   | Composite action used by CI to build and test a template.                               |

## Development scripts

| Script                                 | Purpose                                                                                                     |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `scripts/local-ci.sh`                  | Runs every static check required by CI. Run this before pushing.                                            |
| `scripts/generate-template-readmes.py` | Generates missing `src/<template>/README.md` files. Use `--check` to verify without writing.                |
| `scripts/sync-template-registry.ts`    | Validates that `packages/create-devcontainer/src/templates.ts` matches `src/`. Use `--write` to regenerate. |
| `scripts/render-template.sh`           | Renders a template with default options so it can be built or inspected locally.                            |

## Required checks

Every PR must pass the following checks before merge:

- **JSON validation** — every `src/<template>/devcontainer-template.json` must be valid JSON.
- **templateOption coverage** — every `${templateOption:<key>}` placeholder must have a matching option.
- **shellcheck** — every `src/*/.devcontainer/bootstrap.sh` must pass `shellcheck`.
- **ruff** — Python files in `scripts/` and `test/` must pass `ruff check`.
- **Generated README check** — `scripts/generate-template-readmes.py --check` must report no missing READMEs.
- **Registry sync check** — `scripts/sync-template-registry.ts` must confirm the create-devcontainer registry matches `src/`.
- **pytest** — unit tests in `test/` must pass.
- **Smoke tests** — CI builds and runs `test/<template>/test.sh` for every template whose source or test files changed.
- **create-devcontainer CI** — changes that touch `packages/create-devcontainer/`, `src/`, or the sync script must pass typecheck, sync check, tests, and build.

Run the full local gate with:

```bash
./scripts/local-ci.sh
```

Smoke-test a single template manually with:

```bash
./.github/actions/smoke-test/build.sh <template-id>
./.github/actions/smoke-test/test.sh <template-id>
```

## Submitting changes

1. Write clear, conventional commit messages (`feat:`, `fix:`, `docs:`, etc.).
1. Open a pull request using the provided template.
1. Ensure all CI checks pass. Do not bypass checks with `--no-verify`.

## Releasing

This is a monorepo containing multiple dev container templates and one npm package. To prevent git tag collisions, each artifact gets its own prefixed tag.

### Template release tags

Use `<template-name>-v<semver>` for every template release. For example:

- `ollama-claude-cli-v1.0.0`
- `ollama-claude-cli-studio-v1.0.0`

### Package release tags

Use `v<semver>` or `@<scope>/v<semver>` for the npm package. For example:

- `v1.0.0`

### Why prefixed tags?

A single git tag namespace is shared across all templates and the npm package. Without a prefix, `v1.0.0` is ambiguous — it could apply to any template or the package. Prefixed tags keep release histories independent and readable.

### Template release steps

1. Update the `version` field in `src/<template>/devcontainer-template.json`.
1. Commit the change with a conventional commit message:
   `feat(<template>): bump version to X.Y.Z`
1. Create and push a signed tag:
   `git tag -s <template-name>-vX.Y.Z -m "release <template> vX.Y.Z"`
1. Push the tag to trigger the release workflow:
   `git push origin <template-name>-vX.Y.Z`

The release workflow triggers on any `*-v*` tag and publishes the template whose JSON version changed.

### Package release steps

1. Update the version in `packages/create-devcontainer/package.json`.
1. Commit the change with a conventional commit message:
   `chore(create-devcontainer): bump version to X.Y.Z`
1. Create and push a signed tag such as `vX.Y.Z`.
1. Push the tag to trigger the create-devcontainer CI workflow, which publishes to npm.

### npm lag gate

CI fails closed when the published package is behind the monorepo:

```bash
# must hold: npm view version >= packages/create-devcontainer/package.json version
npm view @mrrobot0985/create-devcontainer version
```

The `npm-lag-gate` job in `create-devcontainer-ci.yaml` runs on push/PR/schedule.
If it is red, finish the package release steps above (tag `vX.Y.Z` and push) so registry catches up.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
