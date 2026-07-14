# Ollama + Claude Code Studio (Host, GPU, DinD) (ollama-host-studio-docker)

A Dockerfile-based template with all Claude Code features (backend, hooks, privacy, rules, skills), Docker-in-Docker, Node.js, and GitHub CLI for local LLM development. Persists authentication and settings across rebuilds via a named volume.

## Includes

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Lifecycle hooks (`claude-code-hooks`)
- Skills library (`claude-code-skills`)
- Behavior rules (`claude-code-rules`)
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

## Build Method

This template uses the `build.dockerfile` property in `devcontainer.json` combined with Docker-in-Docker.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-studio-docker:0
```
