# Google Gemini CLI (gemini-cli)

![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square)

Minimal devcontainer for Google Gemini CLI with container firewall (gemini tags), non-root enforcer, AI agent sandbox, and persistent `~/.gemini` state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.

## Security floor (Layer B)

- Official npm install (`@google/gemini-cli` → `gemini`)
- Container firewall (`container-firewall:1`) — `gemini` service whitelist (`google` + `github` + `npm`)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`)

## Includes

- Node.js 20
- Google Gemini CLI (`gemini`) via npm bootstrap
- GitHub CLI (`github-cli`)
- Container firewall (`container-firewall`) — `gemini` preset
- Non-root enforcer (`non-root-enforcer`)
- Agent sandbox audit (`ai-agent-sandbox`)

## Persistence

`~/.gemini` is a named volume so auth and configuration survive rebuilds:

```json
"mounts": [
  "source=gemini-cli-home-${devcontainerId},target=/home/vscode/.gemini,type=volume"
]
```

## Studio

`gemini-cli-studio` is **deferred** unless DinD need is proven.

## Authentication

```bash
export GEMINI_API_KEY=...
# or follow the Gemini CLI Google login flow
```

Do **not** use obsolete/broken PyPI package names; this template installs `@google/gemini-cli` only.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/gemini-cli:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer gemini-cli ./my-project
```
