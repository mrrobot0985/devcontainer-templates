# Ollama + Claude Code (Host, GPU, DinD) (ollama-host-claude-docker)

A minimal template with Ollama, Claude Code CLI, and Docker-in-Docker for local LLM development. Persists authentication and settings across rebuilds via a named volume.

## Includes

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Docker-in-Docker (`ghcr.io/devcontainers/features/docker-in-docker:4.0.0`)
- NVIDIA Container Toolkit (`ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:latest`) — enables GPU passthrough for containers launched inside the inner Docker daemon

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` suffix isolates state per project so that settings from one workspace do not leak into another.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-claude-docker:0
```
