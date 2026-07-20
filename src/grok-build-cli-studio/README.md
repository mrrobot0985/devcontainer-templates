# Grok Build CLI Studio (grok-build-cli-studio)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Full-featured devcontainer for xAI Grok Build CLI with Docker-in-Docker, host isolation audit, container firewall (`grok-build` + `docker`), AI agent sandbox, MCP server manager, non-root enforcer, and persistent `~/.grok` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Grok Build install (our feature)
- Container firewall (`container-firewall:1`) — `grok-build` + `docker` service tags (DinD image pulls)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`) — runtime posture audit (DinD will warn about docker.sock; non-blocking)

## Studio extras

- Docker-in-Docker (`docker-in-docker:4.0.0`)
- Host isolation (`host-isolation:1`, `failOnWarning: false`) — optional audit of unsafe `runArgs` / mounts / capabilities (DinD needs privileges; non-blocking)
- MCP server manager (`mcp-server-manager:1`) — agent-agnostic shared MCP config (GitHub server by default)

## Includes

- Node.js 20
- Grok Build CLI (`grok` / `agent`) via community feature
- GitHub CLI (`github-cli`)
- Docker-in-Docker (`docker-in-docker:4.0.0`)
- Container firewall (`container-firewall`) — whitelist with `grok-build` + `docker` presets
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)
- Host isolation audit (`host-isolation`)
- MCP server manager (`mcp-server-manager`)

## Persistence

The community `grok-build` feature bind-mounts host `~/.grok` to `/var/lib/grok-build` and symlinks `~/.grok` inside the container. Auth, configuration, and session state survive rebuilds and are shared across projects on the same host.

This template pre-creates the host directory:

```json
"initializeCommand": "mkdir -p \"${localEnv:HOME}/.grok\""
```

## Authentication

```bash
grok login
```

Or set `GROK_DEPLOYMENT_KEY` for non-interactive use. Grok Build requires **SuperGrok** or **X Premium Plus**.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/grok-build-cli-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer grok-build-cli-studio ./my-project
```
