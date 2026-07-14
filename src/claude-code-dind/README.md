# Ollama + Claude Code + Docker (claude-code-dind)

A template with Ollama, Claude Code CLI, and Docker-in-Docker for local LLM development. This extends the base `claude-code` template with Docker-in-Docker support, allowing you to build, run, and push container images from inside the devcontainer.

## Includes

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Lifecycle hooks (`claude-code-hooks`)
- Skills library (`claude-code-skills-matt-pocock`)
- Behavior rules (`claude-code-rules`)
- **Docker-in-Docker** (`ghcr.io/devcontainers/features/docker-in-docker:2`)

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` suffix isolates state per project so that settings from one workspace do not leak into another.
