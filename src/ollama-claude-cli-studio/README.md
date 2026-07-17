# Ollama + Claude CLI Studio (ollama-claude-cli-studio)

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, community NVIDIA Container Toolkit, lifecycle hooks, behavior rules, skills library, audit log, agent sandbox, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.

## Security floor (Layer A)

- Official Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- Backend config (`claude-code-backend:1`)
- Privacy defaults (`claude-code-privacy:1`)
- Container firewall (`container-firewall:1`) — `claude-code` + `docker` service tags (DinD image pulls)
- Non-root enforcer (`non-root-enforcer:1`) — audits `remoteUser` is non-root

## Studio extras (preferred)

- Claude Code audit log (`claude-code-audit-log:1`) — structured JSON events for compliance review
- AI agent sandbox (`ai-agent-sandbox:1`, preset `moderate`, `failOnWarning: false`) — runtime posture audit (DinD will warn about docker.sock; non-blocking)

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Lifecycle hooks (`claude-code-hooks`)
- Privacy defaults (`claude-code-privacy`)
- Behavior rules (`claude-code-rules`)
- Skills library (`claude-code-skills`)
- Claude Code Plugins (`claude-code-plugins`) with Ralph Loop pre-enabled
- Docker-in-Docker (`docker-in-docker:4.0.0`)
- NVIDIA Container Toolkit (`ghcr.io/srzstephen/devcontainer-features/nvidia-container-toolkit:1`) — community feature; installs toolkit packages for DinD GPU
- MCP servers (`claude-code-mcp-servers`) — GitHub and filesystem MCP servers pre-configured
- Container firewall (`container-firewall`) — whitelist with `claude-code` + `docker` presets so Docker-in-Docker image pulls work
- Non-root enforcer (`non-root-enforcer`)
- Audit log (`claude-code-audit-log`)
- Agent sandbox audit (`ai-agent-sandbox`)

## GPU: `--gpus=all` vs NVIDIA Container Toolkit

These are **different layers**:

| Mechanism | What it does | Where configured |
| --------- | ------------ | ---------------- |
| `runArgs: ["--gpus=all"]` | Passes host GPU devices into the **outer** devcontainer | `devcontainer.json` `runArgs` |
| Community `nvidia-container-toolkit:1` | Installs NVIDIA Container Toolkit packages **inside** the container so **inner** DinD containers can use the `nvidia` runtime | `features` entry |

- Outer GPU for processes in the studio container (and host Ollama access patterns) uses `--gpus=all`.
- Nested `docker run --gpus all ...` from DinD needs the toolkit packages (and a properly configured host). The community feature always installs the packages (there is no `enable: false` option — that belonged to a deleted in-house feature).
- Host requirements: NVIDIA driver + host NVIDIA Container Toolkit + Docker configured for the NVIDIA runtime.

Verify outer GPU:

```bash
nvidia-smi
```

Verify DinD GPU (after host is configured):

```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` suffix isolates state per project so that settings from one workspace do not leak into another.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |
| `modelMap` | Comma-separated model overrides in role:model format. Common Ollama defaults are preconfigured; override if your host has different models. | string | haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```
