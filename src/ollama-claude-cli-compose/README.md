# Ollama + Claude CLI (Compose) (ollama-claude-cli-compose)

![Version](https://img.shields.io/badge/version-0.1.0-blue?style=flat-square)

Devcontainer with a bundled Ollama service via Docker Compose. No host Ollama installation required — the Ollama container starts automatically alongside the devcontainer.

## Target Platforms

- Any machine with Docker Compose support
- CPU-only environments (default)
- NVIDIA GPU environments (with manual compose edit)
- GitHub Codespaces (when Compose is available)

## Includes

- Bundled Ollama service (`ollama/ollama:latest`) with health checks
- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Claude Code Plugins (`claude-code-plugins`) — opt-in via configuration
- Container firewall (`container-firewall`) — whitelist outbound traffic with `claude-code` preset

## Differences from `ollama-claude-cli`

- Ollama runs inside a Docker Compose service instead of on the host
- No `host.docker.internal` networking required
- Ollama models are persisted in a named Docker volume (`ollama-data`)
- Bootstrap script waits for Ollama healthcheck instead of probing the host
- `network_mode: service:ollama` shares the network namespace so `localhost:11434` inside the devcontainer refers to the Ollama service

## GPU Support

To enable NVIDIA GPU acceleration, uncomment the `deploy` block in `.devcontainer/docker-compose.yml` after applying the template:

```yaml
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

## Persistence

- Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume.
- Downloaded Ollama models are preserved in the `ollama-data` volume across container rebuilds.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version: | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. Override if you want different Ollama models. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-compose:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-compose ./my-project
```

After the container starts, pull your first model:

```bash
curl -X POST http://localhost:11434/api/pull -d '{"name":"llama3.2"}'
```
