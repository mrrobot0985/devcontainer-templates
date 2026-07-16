# Ollama + Claude CLI + Python (ollama-claude-cli-python)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Devcontainer for Claude CLI with Ollama backend, Python 3.12, the `uv` package manager, and common LLM/AI libraries pre-installed in a project virtual environment. Includes GPU acceleration support via `--gpus=all`.

## Target Platforms

- Apple Silicon (macOS with Apple M-series chips, CPU fallback)
- GitHub Codespaces and GitHub Actions runners
- Cloud VM instances with or without GPU support
- Any local development machine with Docker and NVIDIA Container Toolkit

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
- Container firewall (`container-firewall`)
- MCP servers (`claude-code-mcp-servers:0`) — GitHub and filesystem MCP servers pre-configured for external tool access

## Persistence

- `~/.claude` state is preserved across rebuilds via a named Docker volume.
- The Python virtual environment at `/workspaces/.venv` is preserved via a named Docker volume so packages survive container rebuilds.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version: | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |
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
