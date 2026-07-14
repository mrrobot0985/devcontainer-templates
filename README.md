# Dev Container Templates

![CI](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

A focused collection of custom [Dev Container Templates](https://containers.dev/implementors/templates/).

## Templates

| Template                           | Description                                                                                           |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------- |
| `ollama-claude-code`               | Ollama + Claude Code CLI with privacy-hardened defaults and custom backend support.                 |
| `ollama-claude-code-dind`          | Same as above, plus Docker-in-Docker for building and running containers inside the devcontainer.   |
| `ollama-claude-code-build`         | Same as `ollama-claude-code`, but uses a custom `Dockerfile` via the `build` property.               |
| `ollama-claude-code-build-dind`    | Same as `ollama-claude-code-dind`, but uses a custom `Dockerfile` via the `build` property.         |

Published to GitHub Container Registry:

```
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

### `ollama-claude-code`

A complete development environment for running Claude Code against a local or self-hosted LLM backend (e.g., Ollama).

**Includes:**

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Lifecycle hooks (`claude-code-hooks`)

**Options:**

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code:0
```

### `ollama-claude-code-dind`

Same environment as `ollama-claude-code`, but with Docker-in-Docker so you can build, run, and push container images from inside the devcontainer.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-dind:0
```

### `ollama-claude-code-build`

Same environment as `ollama-claude-code`, but uses a custom `Dockerfile` via the `build` property in `devcontainer.json`. This demonstrates the Dockerfile-based method for building the devcontainer image.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-build:0
```

### `ollama-claude-code-build-dind`

Same environment as `ollama-claude-code-dind`, but uses a custom `Dockerfile` via the `build` property in `devcontainer.json`. This demonstrates the Dockerfile-based method combined with Docker-in-Docker.

**Usage:**

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-build-dind:0
```

## CI

Template changes are validated by [`.github/workflows/test-pr.yaml`](.github/workflows/test-pr.yaml):

- Detects changed templates via `dorny/paths-filter@v3`
- Builds the template via the smoke-test composite action
- Runs `test/<template>/test.sh` inside the built container

Run the local smoke test before pushing:

```bash
# For the base template
./.github/actions/smoke-test/build.sh ollama-claude-code
./.github/actions/smoke-test/test.sh ollama-claude-code

# For the Docker-in-Docker variant
./.github/actions/smoke-test/build.sh ollama-claude-code-dind
./.github/actions/smoke-test/test.sh ollama-claude-code-dind

# For the Dockerfile-based variants
./.github/actions/smoke-test/build.sh ollama-claude-code-build
./.github/actions/smoke-test/test.sh ollama-claude-code-build

./.github/actions/smoke-test/build.sh ollama-claude-code-build-dind
./.github/actions/smoke-test/test.sh ollama-claude-code-build-dind
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
# Create a new project from the ollama-claude-code template
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code:latest
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
