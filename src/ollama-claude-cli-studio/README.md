# Ollama + Claude CLI Studio (ollama-claude-cli-studio)

Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, NVIDIA Container Toolkit, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Lifecycle hooks (`claude-code-hooks`)
- Privacy defaults (`claude-code-privacy`)
- Behavior rules (`claude-code-rules`)
- Skills library (`claude-code-skills`)
- Claude Code Plugins (`claude-code-plugins`) with Ralph Loop pre-enabled
- Docker-in-Docker (`docker-in-docker:4.0.0`)
- NVIDIA Container Toolkit (`nvidia-container-toolkit:0`)

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

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```
