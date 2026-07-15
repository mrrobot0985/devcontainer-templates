# Getting Started with Devcontainer Templates

This tutorial walks you through applying a devcontainer template to a new project, opening it in VS Code:, and verifying that the Claude CLI can reach the Ollama backend.

## Prerequisites

- [Ollama](https://ollama.com) running on your host and accessible at `http://localhost:11434`.
- [Docker](https://docs.docker.com/get-docker/) installed and running.
- [Node.js](https://nodejs.org/) 20 or newer (for the `npx` helper or the Dev Container CLI).
- [VS Code:](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) installed.

## Step 1: Install a template into a new workspace

The fastest way is the `create-devcontainer` helper. It copies a bundled template into your target folder:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```

Alternatively, use the Dev Container CLI to apply the published template directly from GHCR:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Both commands create a `.devcontainer/devcontainer.json` file inside `./my-project`.

## Step 2: Open the workspace in a devcontainer

Open the folder in VS Code: and select the command palette action:

1. `File` > `Open Folder...` and choose `./my-project`.
2. Run `Dev Containers: Rebuild and Reopen in Container` from the command palette.
3. Wait while VS Code: builds the image and starts the container.

If you prefer the terminal, run:

```bash
cd ./my-project
devcontainer up --workspace-folder .
```

Then attach VS Code: with `Dev Containers: Attach to Running Container`.

## Step 3: Verify the Ollama backend

Inside the container, open a terminal and run the bootstrap diagnostics or check the backend directly:

```bash
curl -fsSL http://host.docker.internal:11434/api/tags | head -c 200
```

You should see a JSON list of locally available Ollama models. If you see connection errors:

- Confirm Ollama is running on the host.
- Confirm the container has the host gateway alias: `host.docker.internal` is mapped to `host-gateway` by the template's `runArgs`.
- Confirm port `11434` is exposed on the host.

## Step 4: Run Claude CLI

Inside the container, run:

```bash
claude --version
```

The template pre-configures Claude CLI to use the local Ollama backend, with telemetry, error reporting, feedback, and automatic updates disabled by default.

## Next steps

- For the full workspace with Docker-in-Docker, NVIDIA Container Toolkit, lifecycle hooks, rules, and skills, switch to the `ollama-claude-cli-studio` template.
- To customize the base image, see the `imageVariant` option documented in the [Template Catalog](../reference/template-catalog.md).
