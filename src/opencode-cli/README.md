# OpenCode CLI (opencode-cli)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for OpenCode CLI with container firewall (github + npm + OpenCode domains), non-root enforcer, AI agent sandbox, and persistent OpenCode config/state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Community OpenCode install (`ghcr.io/sliekens/devcontainer-features/opencode:1`)
- Container firewall (`container-firewall:1`) — `github,npm` plus `extraDomains`: `opencode.ai,api.opencode.ai,models.dev`
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- OpenCode CLI (`opencode`) via community feature
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`)
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

## Persistence

The community `opencode` feature bind-mounts host:

- `~/.local/share/opencode` → shared data
- `~/.config/opencode` → shared config

Auth and configuration survive rebuilds and are shared across projects on the same host.

This template pre-creates the host directories:

```json
"initializeCommand": "mkdir -p \"${localEnv:HOME}/.local/share/opencode\" \"${localEnv:HOME}/.config/opencode\""
```

## Studio

`opencode-cli-studio` is **deferred** unless needed.

## Authentication

Configure provider keys per [OpenCode documentation](https://opencode.ai). No secrets are baked into the template.

If your providers need additional API hosts, extend the firewall with `extraDomains` or a broader `services` composite.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/opencode-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer opencode-cli ./my-project
```
