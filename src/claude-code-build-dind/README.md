# Ollama + Claude Code + Docker (build) (claude-code-build-dind)

A Dockerfile-based template with Ollama, Claude Code CLI, and Docker-in-Docker for local LLM development. Persists authentication and settings across rebuilds via a named volume.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/claude-code-build-dind:0
```
