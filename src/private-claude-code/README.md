# Private Claude Code (private-claude-code)

A template with Ollama and Claude Code CLI for local LLM development.

It consumes the public `ghcr.io/mrrobot0985/devcontainer-features/*` packages published in Phase 1.

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-code-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` suffix isolates state per project so that settings from one workspace do not leak into another.
