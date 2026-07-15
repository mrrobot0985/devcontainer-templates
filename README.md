# Dev Container Templates

![CI - Test Templates](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A focused collection of custom [Dev Container Templates](https://containers.dev/implementors/templates/) for Ollama-backed Claude environments.

## Repository structure

This is a monorepo. Each directory has a single responsibility:

| Directory | Purpose |
| --------- | ------- |
| `src/` | Dev container template definitions. Each subdirectory is one publishable template. |
| `packages/create-devcontainer/` | The `npx @mrrobot0985/create-devcontainer` helper that copies templates into any workspace. |
| `scripts/` | Local automation: README generation, template rendering, registry sync, and the local CI gate. |
| `test/` | Unit tests for scripts and per-template smoke tests. |
| `.github/workflows/` | CI/CD pipelines that run on every push/PR and release. |
| `.github/actions/smoke-test/` | Composite action used by CI to build a template and run its smoke test. |
| `.githooks/` | Pre-commit hook that keeps generated template READMEs and the create-devcontainer registry in sync. |

## What runs when you push or open a PR

1. **CI - Test Templates** (`test-pr.yaml`) runs on every push to `main` and every pull request.
   - Validates every `src/<template>/devcontainer-template.json` file.
   - Checks that all `${templateOption:<key>}` placeholders have matching options.
   - Lints shell scripts with `shellcheck`.
   - Lints Python with `ruff`.
   - Verifies generated template READMEs are up to date.
   - Verifies the create-devcontainer template registry is in sync with `src/`.
   - Runs Python unit tests with `pytest`.
   - Detects which templates changed and runs a smoke test (build + `test/<template>/test.sh`) for each.

2. **create-devcontainer CI** (`create-devcontainer-ci.yaml`) runs when `packages/create-devcontainer/`, `src/`, `scripts/sync-template-registry.ts`, or its own workflow file changes.
   - Type-checks the package.
   - Verifies registry sync.
   - Runs package unit tests.
   - Builds the package.
   - Publishes to npm when the workflow was triggered by a version tag (`v*` or `@*`).

3. **Release** (`release.yaml`) runs on every `*-v*` git tag and publishes the matching template to GHCR.

## Local scripts

| Script | Purpose |
| ------ | ------- |
| `scripts/local-ci.sh` | Run the same static checks as CI locally. Optionally runs smoke tests if Docker and the devcontainer CLI are available. This is the fastest way to verify a change before pushing. |
| `scripts/generate-template-readmes.py` | Create missing `src/<template>/README.md` files from `devcontainer-template.json` metadata. The pre-commit hook runs this automatically. |
| `scripts/sync-template-registry.ts` | Compare `src/` templates with `packages/create-devcontainer/src/templates.ts`. Use `--write` to regenerate the registry. |
| `scripts/render-template.sh` | Copy a template to a destination directory and substitute `${templateOption:<key>}` placeholders with their defaults. Used by the smoke-test action and for local testing. |

## Quick Start with `create-devcontainer`

Install templates into any workspace using the npm package:

![npm version](https://img.shields.io/npm/v/@mrrobot0985/create-devcontainer)
![create-devcontainer CI](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/create-devcontainer-ci.yaml/badge.svg)

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```

The CLI copies the bundled template by default. To pull from the GHCR registry instead, pass `--registry`. See [`packages/create-devcontainer/README.md`](packages/create-devcontainer/README.md) for full usage.

## Templates

Each template is a distinct environment for a specific scenario. Choose the one that matches your needs rather than stripping or adding features after the fact.

| Template | Version | Description |
| -------- | ------- | ----------- |
| `ollama-claude-cli` | ![ollama-claude-cli version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/ollama-claude-cli/devcontainer-template.json&label=&query=$.version&color=blue) | Minimal — Claude CLI with pre-configured Ollama backend. Privacy-hardened by default. GPU passthrough enabled. |
| `ollama-claude-cli-studio` | ![ollama-claude-cli-studio version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/ollama-claude-cli-studio/devcontainer-template.json&label=&query=$.version&color=blue) | Full workspace — backend, hooks, privacy, rules, and skills. GPU passthrough enabled. |

Published to GitHub Container Registry:

```
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

### `ollama-claude-cli`

A minimal development environment for Claude CLI with a pre-configured Ollama backend (`http://host.docker.internal:11434`). Includes Node.js and the GitHub CLI.

**Features:**

- Claude CLI (via official Anthropic feature)
- Custom backend configuration (`claude-code-backend`) pointing to Ollama
- Privacy defaults (`claude-code-privacy`) — telemetry, error reporting, feedback, and automatic updates disabled
- GPU passthrough enabled for CUDA workloads
- Port forwarding for Ollama (`11434`)

**Options:**

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:1
```

### `ollama-claude-cli-studio`

The full studio environment with Ollama backend pre-configured. Combines backend configuration, observability hooks, privacy defaults, governance rules, and skills.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:1
```

## Development

### Git hooks

Install the pre-commit hook after cloning:

```bash
git config core.hooksPath .githooks
```

The hook:

- Generates missing `src/<template>/README.md` files from their JSON metadata.
- Verifies the create-devcontainer template registry is in sync.
- Warns when a staged `devcontainer-template.json` is not accompanied by its `README.md` update.

### Run the local CI gate

```bash
./scripts/local-ci.sh
```

This runs every static check required by CI. Smoke tests run automatically when Docker and the devcontainer CLI are available.

### Smoke-test a single template locally

```bash
# Minimal
./.github/actions/smoke-test/build.sh ollama-claude-cli
./.github/actions/smoke-test/test.sh ollama-claude-cli

# Studio
./.github/actions/smoke-test/build.sh ollama-claude-cli-studio
./.github/actions/smoke-test/test.sh ollama-claude-cli-studio
```

## Adding NVIDIA Container Toolkit

If you need GPU passthrough for containers launched inside the inner Docker daemon (e.g., running CUDA workloads inside containers built from within the devcontainer), add the NVIDIA Container Toolkit feature to your `.devcontainer/devcontainer.json`:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0": {
    "enable": true
  }
}
```

## Publishing

- Template releases: push a signed tag `<template-name>-v<semver>` to trigger `release.yaml`, which publishes to GHCR.
- Package releases: push a tag matching `v*` or `@*` to trigger `create-devcontainer-ci.yaml`, which publishes `@mrrobot0985/create-devcontainer` to npm.

See [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md) for the exact tagging and release steps.

## Using the Dev Container CLI

Install the CLI globally via npm or use the VS Code extension's bundled binary:

```bash
npm install -g @devcontainers/cli
# or use the VS Code extension binary:
# ~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer
```

### Apply a template to a new workspace

```bash
# Create a new project from the ollama-claude-cli template
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

### Build the devcontainer after applying the template

```bash
cd ./my-project
devcontainer up --workspace-folder . --build-no-cache
```

### Force a fresh build (bypass Docker cache)

```bash
devcontainer up --workspace-folder . --build-no-cache
```

### Remove stale caches

If the template or features are not updating after a new release:

```bash
# Remove old containers, images, and caches
docker ps -aq --filter label=devcontainer.local_folder | xargs -r docker rm -f
docker images --format "{{.Repository}}:{{.Tag}}" | grep "vsc-" | xargs -r docker rmi -f
rm -rf /tmp/devcontainercli-*/container-features/*
rm -f .devcontainer/devcontainer-lock.json
```

### Important: Lockfiles pin feature versions

If `.devcontainer/devcontainer-lock.json` exists, it overrides `:latest` and pins each feature to a specific digest. Delete the lockfile to force resolution of the newest published version.

## License

MIT
