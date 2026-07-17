# Ollama + Claude CLI + Python (ollama-claude-cli-python)

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Devcontainer for Claude CLI with Ollama backend, Python 3.12, the `uv` package manager, and common LLM/AI libraries pre-installed in a project virtual environment. Includes GPU acceleration support via `--gpus=all`.

## Target Platforms

- Apple Silicon (macOS with Apple M-series chips, CPU fallback)
- GitHub Codespaces and GitHub Actions runners
- Cloud VM instances with or without GPU support
- Any local development machine with Docker and NVIDIA Container Toolkit

## Security floor (Layer A)

- Official Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- Backend config (`claude-code-backend:1`)
- Privacy defaults (`claude-code-privacy:1`)
- Container firewall (`container-firewall:1`) — `claude-code` service whitelist
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root

## Includes

- Python 3.12 (configurable to 3.11 or 3.10)
- `uv` package manager
- Pre-configured virtual environment at `/workspaces/.venv`
- Common AI/LLM packages: openai, anthropic, ollama, langchain, chromadb, sentence-transformers, numpy, pandas, jupyter
- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Claude Code Plugins (`claude-code-plugins`)
- MCP servers (`claude-code-mcp-servers`) — GitHub and filesystem MCP servers pre-configured
- Container firewall (`container-firewall`)
- Non-root enforcer (`non-root-enforcer`)

## GPU

Outer container GPU passthrough is enabled via `runArgs: ["--gpus=all"]` so CUDA-capable Python packages can see host GPUs when available. On hosts without a GPU runtime (Apple Silicon, many Codespaces), remove or comment out `--gpus=all` if container create fails.

This template does **not** install the NVIDIA Container Toolkit feature. Host Ollama still runs on the host; for DinD GPU see `ollama-claude-cli-studio`.

## Persistence

- `~/.claude` state is preserved across rebuilds via a named Docker volume.
- The Python virtual environment at `/workspaces/.venv` is preserved via a named Docker volume so packages survive container rebuilds.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version: | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. Override if your host Ollama has different models. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |
| `pythonVersion` | Python version to install: | string | 3.12 |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-python:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-python ./my-project
```

After the container starts, activate the virtual environment:

```bash
source /workspaces/.venv/bin/activate
```

Or use `uv` directly without activating:

```bash
uv run python my-script.py
```
