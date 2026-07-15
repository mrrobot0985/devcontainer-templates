# Ollama + Claude CLI (ollama-claude-cli)

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, and persistent settings. Includes Node.js and GitHub CLI.

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Claude Code Plugins (`claude-code-plugins`) — opt-in via configuration
- Container firewall (`container-firewall`) — whitelist outbound traffic with `claude-code` preset

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
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```
