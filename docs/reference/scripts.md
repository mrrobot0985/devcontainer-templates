# Scripts and Automation

The repository provides local scripts for validation, documentation generation, registry maintenance, and manual template rendering.

| Script | Path | Purpose |
| ------ | ---- | ------- |
| Local CI gate | `scripts/local-ci.sh` | Run the same static checks as CI locally, with optional smoke tests |
| README generator | `scripts/generate-template-readmes.py` | Create missing `src/<template>/README.md` files from metadata |
| Registry sync | `scripts/sync-template-registry.ts` | Validate or regenerate the create-devcontainer template registry |
| Template renderer | `scripts/render-template.sh` | Copy a template and substitute options with their defaults |

## `scripts/local-ci.sh`

Runs the same checks as the `lint` job in `test-pr.yaml`. If Docker and the Dev Container CLI are available, it also runs smoke tests for `ollama-claude-cli` and `ollama-claude-cli-studio`.

### Prerequisites

- bash >= 4
- python3, jq, shellcheck
- node >= 20
- Docker and `devcontainer` CLI (optional)

### Usage

```bash
./scripts/local-ci.sh
```

### Checks performed

1. Validates `devcontainer-template.json` files are valid JSON.
2. Verifies every `${templateOption:<key>}` placeholder has a matching option.
3. Runs `shellcheck` on `src/*/.devcontainer/bootstrap.sh`.
4. Runs `ruff check scripts/ test/`.
5. Checks generated template READMEs with `python3 scripts/generate-template-readmes.py --check`.
6. Checks template registry sync with `npx tsx scripts/sync-template-registry.ts`.
7. Runs `pytest test/`.
8. Runs smoke tests if Docker and the devcontainer CLI are available.

## `scripts/generate-template-readmes.py`

Generates missing `src/<template>/README.md` files from the metadata in `devcontainer-template.json`. Existing READMEs are left untouched to preserve manual enhancements.

### Usage

Generate missing READMEs:

```bash
python3 scripts/generate-template-readmes.py
```

Verify that all READMEs are present without writing files:

```bash
python3 scripts/generate-template-readmes.py --check
```

The pre-commit hook runs this script automatically.

## `scripts/sync-template-registry.ts`

Compares the template directories under `src/` with the hard-coded registry in `packages/create-devcontainer/src/templates.ts`. CI and the pre-commit hook validate this automatically and fail if they drift.

### Usage

Validate sync:

```bash
npx tsx scripts/sync-template-registry.ts
```

Regenerate the registry after adding, removing, or renaming a template:

```bash
npx tsx scripts/sync-template-registry.ts --write
```

## `scripts/render-template.sh`

Renders a template by copying it to a destination directory and substituting `${templateOption:<key>}` placeholders with their default values. It also copies the matching smoke test into `test-project/` inside the destination.

### Usage

```bash
./scripts/render-template.sh <template-id> <destination-dir>
```

Example:

```bash
./scripts/render-template.sh ollama-claude-cli /tmp/rendered-template
```

### Steps

1. Copy `src/<template-id>` to `<destination-dir>`.
2. Replace `${templateOption:<key>}` placeholders with defaults from `devcontainer-template.json`.
3. Copy `test/<template-id>/*` into `<destination-dir>/test-project`.

This script is used by the smoke-test action and for local testing.
