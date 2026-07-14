# Ollama + Claude Code Studio (Host, GPU) (ollama-host-studio)

A complete template with all Claude Code features (backend, hooks, privacy, rules, skills), Node.js, and GitHub CLI for local LLM development. Persists authentication and settings across rebuilds via a named volume.

## Includes

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Lifecycle hooks (`claude-code-hooks`)
- Skills library (`claude-code-skills`)
- Behavior rules (`claude-code-rules`)

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
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-host-studio:0
```
