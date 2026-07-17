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

1. **`test`** — builds and runs `test/<template>/test.sh` for every changed template (via the smoke-test composite action).

1. **`smoke-tests`** — evaluates the matrix results and fails the workflow if any smoke test **job** failed (or was not an intentional skip).

### Smoke-test known limitation (fix-skip)

`.github/actions/smoke-test/build.sh` currently treats **any** reference to
`ghcr.io/mrrobot0985/devcontainer-features/*` as “unpublished,” writes a skip
marker, and exits **0**. Those features are published on public GHCR; the skip
is therefore a **false green** for most agent and domain templates that use the
owned security floor.

Until [templates#88](https://github.com/mrrobot0985/devcontainer-templates/issues/88)
lands:

- A green smoke job does **not** prove `devcontainer up` worked for owned-feature templates.
- Local smoke via `build.sh` will skip the same way.
- Prefer feature monorepo tests and static template validation for confidence, or run `devcontainer up` manually after removing the skip guard.

Do not document “all templates smoke-tested in CI” as true while this guard remains.

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
