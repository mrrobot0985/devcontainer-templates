# Grok Build CLI (grok-build-cli)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for xAI Grok Build CLI with container firewall (grok-build tags), non-root enforcer, AI agent sandbox, and persistent `~/.grok` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Grok Build install (our feature)
- Container firewall (`container-firewall:1`) — `grok-build` service whitelist (`xai` + `github` + `npm`)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- Grok Build CLI (`grok` / `agent`) via community feature
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`) — whitelist outbound traffic with `grok-build` preset
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

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
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/grok-build-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer grok-build-cli ./my-project
```
