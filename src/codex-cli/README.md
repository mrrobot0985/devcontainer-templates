# OpenAI Codex CLI (codex-cli)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for OpenAI Codex CLI with container firewall (codex tags), non-root enforcer, AI agent sandbox, and persistent `~/.codex` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Community Codex install (`ghcr.io/sliekens/devcontainer-features/codex:1`)
- Container firewall (`container-firewall:1`) — `codex` service whitelist (`openai` + `github` + `npm`)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- OpenAI Codex CLI (`codex`) via community feature
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`) — `codex` preset
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

## Persistence

The community `codex` feature bind-mounts host `~/.codex` to `/var/lib/codex` and wires `~/.codex` inside the container. Auth, configuration, and session state survive rebuilds and are shared across projects on the same host.

This template pre-creates the host directory:

```json
"initializeCommand": "mkdir -p \"${localEnv:HOME}/.codex\""
```

## Studio

`codex-cli-studio` is **deferred** unless DinD / MCP depth proves a real capability split (same ladder as Grok).

## Authentication

```bash
codex login
```

Or set `OPENAI_API_KEY` for non-interactive use. No secrets are baked into the template.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/codex-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer codex-cli ./my-project
```
