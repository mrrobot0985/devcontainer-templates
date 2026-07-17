# Hermes Agent (hermes-agent)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for the Hermes agent (Nous Research) with container firewall (openrouter + github + npm), non-root enforcer, AI agent sandbox, and persistent `~/.hermes` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Community install (`ghcr.io/devcontainer-community/devcontainer-features/hermes-agent.nousresearch.com:1`)
- Container firewall (`container-firewall:1`) — `github,npm,openrouter`
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- Hermes agent (`hermes`) via community feature
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`)
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

## Persistence

`~/.hermes` is a named volume so configuration and session state survive rebuilds.

## Studio decision

`hermes-agent-studio` is **not** shipped in v1. Collapse to this single template unless dogfood shows container backends / gateway work that needs DinD. Revisit if Hermes workflows regularly require Docker-in-Docker.

## Authentication

```bash
hermes model
```

Configure OpenRouter, Nous portal, or other provider keys as documented upstream. No secrets are baked into the template.

If you use providers beyond OpenRouter, extend the firewall with `extraDomains` or switch `services` to a broader composite (for example `multi-ai`).

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/hermes-agent:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer hermes-agent ./my-project
```
