# Dev Container Templates

![CI](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A focused collection of custom [Dev Container Templates](https://containers.dev/implementors/templates/).

## Templates

Each template is a distinct environment for a specific scenario. Choose the one that matches your needs rather than stripping or adding features after the fact.

### Generic (Anthropic backend by default)

| Template | Version | Description |
| -------- | ------- | ----------- |
| `claude-code` | ![claude-code version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/claude-code/devcontainer-template.json&label=&query=$.version&color=blue) | Minimal — Claude Code CLI, privacy defaults, Node.js, GitHub CLI. |
| `claude-code-studio` | ![claude-code-studio version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/claude-code-studio/devcontainer-template.json&label=&query=$.version&color=blue) | Full workspace — Adds lifecycle hooks, behavior rules, and skills library. |

### Ollama backend (requires Ollama on the host)

| Template | Version | Description |
| -------- | ------- | ----------- |
| `ollama-claude-code` | ![ollama-claude-code version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/ollama-claude-code/devcontainer-template.json&label=&query=$.version&color=blue) | Minimal + Ollama backend — Claude Code pre-configured for a local Ollama instance. GPU passthrough enabled. |
| `ollama-claude-code-studio` | ![ollama-claude-code-studio version](https://img.shields.io/badge/dynamic/json?url=https://raw.githubusercontent.com/mrrobot0985/devcontainer-templates/main/src/ollama-claude-code-studio/devcontainer-template.json&label=&query=$.version&color=blue) | Full workspace + Ollama backend — Studio features with pre-configured Ollama. GPU passthrough enabled. |

Published to GitHub Container Registry:

```
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

### `claude-code`

A minimal development environment for Claude Code using the default Anthropic backend. Includes Node.js and the GitHub CLI.

**Features:**

- Claude Code CLI (via official Anthropic feature)
- Privacy defaults (`claude-code-privacy`) — telemetry, error reporting, feedback, and automatic updates disabled

**Options:**

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/claude-code:1
```

### `claude-code-studio`

The full studio environment with lifecycle hooks, behavior rules, and skills. Uses the default Anthropic backend.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/claude-code-studio:1
```

### `ollama-claude-code`

Same as minimal, but with the Claude Code backend pre-configured for a local Ollama instance (`http://host.docker.internal:11434`). Includes GPU passthrough for CUDA workloads. Requires Ollama to be running on the host machine.

**Features:**

- Claude Code CLI (via official Anthropic feature)
- Custom backend configuration (`claude-code-backend`) pointing to Ollama
- Privacy defaults (`claude-code-privacy`)
- GPU passthrough enabled (`--gpus=all`)
- Port forwarding for Ollama (`11434`)

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code:1
```

### `ollama-claude-code-studio`

The full studio environment with Ollama backend pre-configured. Requires Ollama to be running on the host machine.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-studio:1
```

## Adding Docker-in-Docker

All templates use a standard base image. If you need to build, run, or push container images from inside the devcontainer, add the official Docker-in-Docker feature to your `.devcontainer/devcontainer.json`:

```json
"features": {
  "ghcr.io/devcontainers/features/docker-in-docker:4.0.0": {
    "moby": "false",
    "dockerDashComposeVersion": "v2"
  }
}
```

## CI

Template changes are validated by [`.github/workflows/test-pr.yaml`](.github/workflows/test-pr.yaml):

- Detects changed templates via `dorny/paths-filter@v3`
- Builds the template via the smoke-test composite action
- Runs `test/<template>/test.sh` inside the built container

Run the local smoke test before pushing:

```bash
# Generic minimal
./.github/actions/smoke-test/build.sh claude-code
./.github/actions/smoke-test/test.sh claude-code

# Generic studio
./.github/actions/smoke-test/build.sh claude-code-studio
./.github/actions/smoke-test/test.sh claude-code-studio

# Ollama minimal
./.github/actions/smoke-test/build.sh ollama-claude-code
./.github/actions/smoke-test/test.sh ollama-claude-code

# Ollama studio
./.github/actions/smoke-test/build.sh ollama-claude-code-studio
./.github/actions/smoke-test/test.sh ollama-claude-code-studio
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
# Create a new project from the claude-code template
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/claude-code:latest
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
