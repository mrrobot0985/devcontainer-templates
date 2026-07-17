# Ollama + Claude CLI (ollama-claude-cli)

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, and persistent settings. Includes Node.js and GitHub CLI.

## Security floor (Layer A)

- Official Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- Backend config (`claude-code-backend:1`)
- Privacy defaults (`claude-code-privacy:1`)
- Container firewall (`container-firewall:1`) — `claude-code` service whitelist
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Claude Code Plugins (`claude-code-plugins`) — opt-in via configuration
- Container firewall (`container-firewall`) — whitelist outbound traffic with `claude-code` preset
- Non-root enforcer (`non-root-enforcer`)

## GPU

Outer container GPU passthrough is enabled via `runArgs: ["--gpus=all"]`. Host Ollama (and tools that need device nodes in this container) can use the GPU when the host has NVIDIA drivers and the NVIDIA Container Toolkit.

This template does **not** install the NVIDIA Container Toolkit inside the container. For Docker-in-Docker GPU workloads, use `ollama-claude-cli-studio` or see [Adding NVIDIA GPU Support](../../docs/how-to-guides/add-nvidia-support.md).

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` suffix isolates state per project so that settings from one workspace do not leak into another.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. Common Ollama defaults are preconfigured; override if your host has different models. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```
