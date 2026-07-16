# Ollama + Claude CLI (CPU) (ollama-claude-cli-cpu)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings. No GPU required.

## Target Platforms

- Apple Silicon (macOS with Apple M-series chips)
- GitHub Codespaces and GitHub Actions runners
- Cloud VM instances without GPU support
- Any CPU-only local development machine

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Claude Code Plugins (`claude-code-plugins`) — opt-in via configuration
- Container firewall (`container-firewall`) — whitelist outbound traffic with `claude-code` preset

## Differences from `ollama-claude-cli`

This template omits the `--gpus=all` Docker run argument and any NVIDIA-specific configuration, making it safe to use on machines without a GPU runtime. All other behavior is identical.

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
| `imageVariant` | Ubuntu version: | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. Override if your host Ollama has different models. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-cpu:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-cpu ./my-project
```
