# Dev Container Templates

![CI](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A focused collection of custom [Dev Container Templates](https://containers.dev/implementors/templates/).

## Templates

Each template is a distinct environment for a specific scenario. Choose the one that matches your needs rather than stripping or adding features after the fact.

| Template | Scenario |
|----------|----------|
| `ollama-host-claude` | **Minimal** — Claude Code with Ollama backend. Privacy-hardened by default. GPU passthrough enabled. |
| `ollama-host-claude-docker` | **Minimal + Docker** — Build and run containers from inside the devcontainer. GPU passthrough enabled for outer container and inner Docker daemon. |
| `ollama-host-studio` | **Full workspace** — All features: backend, hooks, privacy, rules, and skills. GPU passthrough enabled. |
| `ollama-host-studio-docker` | **Full workspace + Docker** — Studio environment with Docker-in-Docker. GPU passthrough enabled for outer container and inner Docker daemon. |

Published to GitHub Container Registry:

```
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

### `ollama-host-claude`

A minimal development environment for running Claude Code against a local or self-hosted LLM backend (e.g., Ollama). Includes Node.js and the GitHub CLI.

**Features:**

- Claude Code CLI (via official Anthropic feature)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`) — telemetry, error reporting, feedback, and automatic updates disabled
- GPU passthrough enabled for CUDA workloads

**Options:**

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-claude:0
```

### `ollama-host-claude-docker`

Same as minimal, with Docker-in-Docker so you can build, run, and push container images from inside the devcontainer. Includes the NVIDIA Container Toolkit (v1.1.0) for GPU-accelerated containers launched from the inner Docker daemon. Disabled by default — opt-in by setting `"enable": true` in your `devcontainer.json`.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-claude-docker:0
```

### `ollama-host-studio`

The full studio environment. Combines backend configuration, observability hooks, privacy defaults, governance rules, and skills.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-studio:0
```

### `ollama-host-studio-docker`

The full studio environment plus Docker-in-Docker. Use this when you need governance, observability, and container builds in one workspace. Includes the NVIDIA Container Toolkit (v1.1.0) for GPU-accelerated containers launched from the inner Docker daemon. Disabled by default — opt-in by setting `"enable": true` in your `devcontainer.json`.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-studio-docker:0
```

## CI

Template changes are validated by [`.github/workflows/test-pr.yaml`](.github/workflows/test-pr.yaml):

- Detects changed templates via `dorny/paths-filter@v3`
- Builds the template via the smoke-test composite action
- Runs `test/<template>/test.sh` inside the built container

Run the local smoke test before pushing:

```bash
# Minimal
./.github/actions/smoke-test/build.sh ollama-host-claude
./.github/actions/smoke-test/test.sh ollama-host-claude

# Studio
./.github/actions/smoke-test/build.sh ollama-host-studio
./.github/actions/smoke-test/test.sh ollama-host-studio

# Docker variants
./.github/actions/smoke-test/build.sh ollama-host-claude-docker
./.github/actions/smoke-test/test.sh ollama-host-claude-docker

./.github/actions/smoke-test/build.sh ollama-host-studio-docker
./.github/actions/smoke-test/test.sh ollama-host-studio-docker
```

## Development

### Git Hooks

This repository uses a pre-commit hook to keep template READMEs in sync with `devcontainer-template.json` metadata. Install it once after cloning:

```bash
git config core.hooksPath .githooks
```

The hook:

- Auto-generates any missing `src/<template>/README.md` files from their JSON metadata.
- Warns when a staged `devcontainer-template.json` is not accompanied by its `README.md` update.

You can also run the generator manually:

```bash
uv run python scripts/generate-template-readmes.py
```

## Publishing

On release, `.github/workflows/release.yaml` publishes each template to GHCR using the `devcontainers/action@v1` GitHub Action. Templates are private by default; set each package to public in its GHCR package settings page.

## Using the Dev Container CLI

Install the CLI globally via npm or use the VS Code extension's bundled binary:

```bash
npm install -g @devcontainers/cli
# or use the VS Code extension binary:
# ~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer
```

### Apply a template to a new workspace

```bash
# Create a new project from the ollama-host-claude template
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-claude:latest
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

### Important: Lockfiles Pin Feature Versions

If `.devcontainer/devcontainer-lock.json` exists, it overrides `:latest` and pins each feature to a specific digest. Delete the lockfile to force resolution of the newest published version.

## License

MIT
