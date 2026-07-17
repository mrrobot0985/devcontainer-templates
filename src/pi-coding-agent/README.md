# Pi Coding Agent (pi-coding-agent)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for the Pi coding agent (pi.dev) with container firewall, non-root enforcer, AI agent sandbox, and persistent `~/.pi` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Official npm install (`@earendil-works/pi-coding-agent` → `pi`)
- Container firewall (`container-firewall:1`) — `multi-ai` service whitelist (provider APIs + github + npm)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- Pi coding agent (`pi`) via npm bootstrap
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`) — `multi-ai` preset
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

## Persistence

`~/.pi` is a named volume so auth, configuration, and session state survive rebuilds:

```json
"mounts": [
  "source=pi-coding-agent-home-${devcontainerId},target=/home/vscode/.pi,type=volume"
]
```

Host `~/.pi` is also pre-created via `initializeCommand` for local tooling convenience.

## Studio

`pi-coding-agent-studio` is **deferred** unless dogfood shows a real DinD/MCP need.

## Authentication

```bash
pi /login
```

Or configure provider API keys per Pi documentation. No secrets are baked into the template.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/pi-coding-agent:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer pi-coding-agent ./my-project
```
