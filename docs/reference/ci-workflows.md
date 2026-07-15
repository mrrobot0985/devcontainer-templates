# CI Workflows

Three GitHub Actions workflows enforce quality and publish artifacts. All PRs must pass the relevant checks before merge.

| Workflow               | File                          | Triggers                                                                                                                        | Checks                                                                                                                                                           |
| ---------------------- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| CI - Test Templates    | `test-pr.yaml`                | Push to `main`, any pull request                                                                                                | JSON validation, templateOption placeholder coverage, shellcheck, ruff, generated README freshness, registry sync, pytest, and smoke tests for changed templates |
| create-devcontainer CI | `create-devcontainer-ci.yaml` | Push to `main`/`feat/**`/`fix/**`, tags `v*` or `@*`, PRs to `main` when package, `src/`, sync script, or workflow file changes | Type check, registry sync, package unit tests, build, and npm publish on tag                                                                                     |
| Release                | `release.yaml`                | Any `*-v*` tag                                                                                                                  | Publishes the matching template to GHCR                                                                                                                          |

## CI - Test Templates (`test-pr.yaml`)

Runs on every push to `main` and every pull request. It is the primary gate.

### Jobs

1. **`lint`** — static validation:

   - Validates every `src/<template>/devcontainer-template.json` file is valid JSON.
   - Checks that all `${templateOption:<key>}` placeholders have matching options.
   - Runs `shellcheck` on `src/*/.devcontainer/bootstrap.sh`.
   - Runs `ruff` on `scripts/` and `test/`.
   - Verifies generated template READMEs are up to date.
   - Verifies the create-devcontainer template registry is in sync with `src/`.
   - Runs Python unit tests with `pytest`.

1. **`detect-changes`** — determines which templates changed using `dorny/paths-filter`.

1. **`test`** — builds and runs `test/<template>/test.sh` for every changed template.

1. **`smoke-tests`** — evaluates the matrix results and fails the workflow if any smoke test failed.

## create-devcontainer CI (`create-devcontainer-ci.yaml`)

Runs when files under `packages/create-devcontainer/`, `src/`, `scripts/sync-template-registry.ts`, or the workflow itself change.

### Jobs

1. **`typecheck-test-build`**:

   - Installs dependencies with `npm ci`.
   - Type-checks the package.
   - Validates registry sync.
   - Runs package unit tests.
   - Builds the package.

1. **`publish`** (tag triggers only):

   - Publishes the built package to npm with public access.

## Release (`release.yaml`)

Runs on every tag matching `*-v*`.

### Job

- **`deploy`** — uses `devcontainers/action@v1` to publish every template under `src/` to GHCR. The action selects the template whose version changed in `devcontainer-template.json`.

### Package visibility

Templates are private by default in GHCR. Set each package to public in its GHCR package settings page after the first publish.
