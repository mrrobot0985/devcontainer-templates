# Dev Container CLI Reference

The [Dev Container CLI](https://github.com/devcontainers/cli) is the reference implementation for working with devcontainer templates and configurations. Install it globally or use the binary bundled with the VS Code: Dev Containers extension.

## Installation

```bash
npm install -g @devcontainers/cli
```

The VS Code: extension also ships a binary at a path similar to:

```text
~/.config/Code/User/globalStorage/ms-vscode-remote.remote-containers/cli-bin/devcontainer
```

## Apply a template to a new workspace

Create a new project from a published template:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Use a specific major version instead of `latest`:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:1
```

The CLI downloads the template and writes a `.devcontainer/devcontainer.json` into the workspace folder.

## Build the devcontainer after applying

From inside the project folder, build and start the container:

```bash
cd ./my-project
devcontainer up --workspace-folder . --build-no-cache
```

## Force a fresh build

Bypass the Docker cache when the template or features have changed:

```bash
devcontainer up --workspace-folder . --build-no-cache
```

## Remove stale caches

If the template or features are not updating after a new release, clean up stale containers, images, and caches:

```bash
# Remove old containers
docker ps -aq --filter label=devcontainer.local_folder | xargs -r docker rm -f

# Remove old devcontainer images
docker images --format "{{.Repository}}:{{.Tag}}" | grep "vsc-" | xargs -r docker rmi -f

# Remove feature caches
rm -rf /tmp/devcontainercli-*/container-features/*

# Remove the lockfile
rm -f .devcontainer/devcontainer-lock.json
```

## Lockfile behavior

If `.devcontainer/devcontainer-lock.json` exists, it overrides `:latest` and pins each feature to a specific digest. This prevents feature versions from changing unexpectedly.

To force resolution of the newest published version, delete the lockfile before building:

```bash
rm -f .devcontainer/devcontainer-lock.json
devcontainer up --workspace-folder . --build-no-cache
```

## Common commands reference

| Command | Purpose |
| ------- | ------- |
| `devcontainer templates apply` | Apply a template to a workspace folder |
| `devcontainer up` | Build and start the devcontainer |
| `devcontainer build` | Build the devcontainer image without starting it |
| `devcontainer exec` | Run a command inside the running container |
| `devcontainer --version` | Show the installed CLI version |

## Useful flags

| Flag | Effect |
| ---- | ------ |
| `--workspace-folder <path>` | Target directory containing `.devcontainer` |
| `--build-no-cache` | Force a fresh image build |
| `--id-label <label>` | Tag the container with a custom label |
| `--remove-existing-container` | Replace an existing container on `up` |
