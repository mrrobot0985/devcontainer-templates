# Template Catalog

This collection provides two purpose-driven templates for Ollama-backed Claude environments. Choose the one that matches the scope of your project rather than adding or removing features after applying it.

| Template                   | Version | Description                                                                                                                                                                                                                            |
| -------------------------- | ------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ollama-claude-cli`        | `0.1.0` | Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, and persistent settings. Includes Node.js and GitHub CLI.                                                                                  |
| `ollama-claude-cli-studio` | `0.1.0` | Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, NVIDIA Container Toolkit, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. |

Both templates require Ollama to be running on the host and accessible at `http://host.docker.internal:11434`.

## `ollama-claude-cli`

A minimal environment for Claude CLI with a pre-configured Ollama backend. Privacy-hardened by default. GPU passthrough enabled.

### Included features

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- Custom backend configuration (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0`)
- Privacy defaults (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0`)
- Claude Code Plugins (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0`)
- Host gateway alias and `--gpus=all` passthrough
- Port forwarding for Ollama (`11434`)
- Persistent `~/.claude` volume

### Options

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

### Usage

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Or with the helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```

## `ollama-claude-cli-studio`

The full studio environment with Ollama backend pre-configured. Combines backend configuration, observability hooks, privacy defaults, governance rules, skills, plugins, Docker-in-Docker, and optional NVIDIA Container Toolkit.

### Included features

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- Custom backend configuration (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0`)
- Lifecycle hooks (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0`)
- Privacy defaults (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0`)
- Behavior rules (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:0`)
- Skills library (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-skills:0`)
- Claude Code Plugins (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0`) with Ralph Loop pre-enabled
- Docker-in-Docker (`ghcr.io/devcontainers/features/docker-in-docker:4.0.0`)
- NVIDIA Container Toolkit (`ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0`, disabled by default)
- Host gateway alias and `--gpus=all` passthrough
- Port forwarding for Ollama (`11434`)
- Persistent `~/.claude` volume

### Options

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

### Usage

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest
```

Or with the helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```

## Publishing location

Both templates are published to GitHub Container Registry:

```text
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```
