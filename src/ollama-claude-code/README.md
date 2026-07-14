# Claude Code (claude-code)

Minimal devcontainer for Claude Code with a configurable LLM backend, privacy defaults, and persistent settings. Includes Node.js and GitHub CLI.

## Includes

- Node.js 20
- Claude Code CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)

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
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-code ./my-project
```
