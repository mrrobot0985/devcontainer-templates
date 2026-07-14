# Ollama + Claude Code (build) (ollama-claude-code-build)

A Dockerfile-based template with Ollama and Claude Code CLI for local LLM development. Persists authentication and settings across rebuilds via a named volume.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-build:0
```
