# Testing a Template Locally

Run the same checks CI runs before you push. This repository provides three levels of local validation: the full local CI gate, per-template smoke tests, and Python unit tests.

## Run the full local CI gate

`scripts/local-ci.sh` runs every static check required by CI. If Docker and the Dev Container CLI are available, it also runs smoke tests for all templates.

```bash
./scripts/local-ci.sh
```

Prerequisites:

- bash >= 4
- python3, jq, shellcheck
- node >= 20
- Docker and the devcontainer CLI (optional, for smoke tests)

The script reports `[PASS]`, `[FAIL]`, and `[WARN]` lines for each check and exits with a non-zero status if anything fails.

## Run a smoke test for a single template

Smoke tests render a template, build the devcontainer, and execute the per-template test script inside the container. They are the fastest way to verify a specific change.

```bash
./.github/actions/smoke-test/build.sh ollama-claude-cli
./.github/actions/smoke-test/test.sh ollama-claude-cli
```

For the studio template:

```bash
./.github/actions/smoke-test/build.sh ollama-claude-cli-studio
./.github/actions/smoke-test/test.sh ollama-claude-cli-studio
```

`build.sh` renders the template into `/tmp/<template-id>` and starts the container. `test.sh` runs `test/<template-id>/test.sh` inside the container. Both scripts clean up the rendered directory and container on exit.

On CI runners, `build.sh` automatically strips `--gpus=all` from `runArgs` because GPUs are unavailable.

## Run Python unit tests

The Python unit tests live in `test/` and validate tooling such as the README generator.

```bash
pytest test/
```

You can also run them through `ruff`:

```bash
ruff check scripts/ test/
```

## What to do if a check fails

- JSON validation: run `jq empty src/<template>/devcontainer-template.json` to find the parse error.
- templateOption placeholders: ensure every `${templateOption:<key>}` placeholder has a matching entry in the `options` object.
- shellcheck: fix the reported issues in `src/*/.devcontainer/bootstrap.sh`.
- Generated READMEs: run `python3 scripts/generate-template-readmes.py`.
- Registry sync: run `npx tsx scripts/sync-template-registry.ts --write`.
- Smoke tests: check Docker availability and that the feature references in `devcontainer.json` are reachable.
