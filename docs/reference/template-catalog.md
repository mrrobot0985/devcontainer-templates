# Template Catalog

Purpose-driven templates. Prefer choosing the right template over adding or removing features after apply.

## Layer A — Claude + Ollama family

Consistent **security floor** across all five:

- Official Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- `claude-code-backend:1`
- `claude-code-privacy:1`
- `container-firewall:1`
- `non-root-enforcer:1`

| Template                    | Version | GPU                                     | Host Ollama | Extra                                                |
| --------------------------- | ------- | --------------------------------------- | ----------- | ---------------------------------------------------- |
| `ollama-claude-cli`         | `1.1.0` | `--gpus=all`                            | Required    | Minimal                                              |
| `ollama-claude-cli-cpu`     | `1.1.0` | None                                    | Required    | Apple Silicon / Codespaces safe                      |
| `ollama-claude-cli-compose` | `1.1.0` | Optional (compose edit)                 | Bundled     | No host Ollama                                       |
| `ollama-claude-cli-python`  | `1.1.0` | `--gpus=all`                            | Required    | Python 3.12 + uv + AI libs                           |
| `ollama-claude-cli-studio`  | `1.1.0` | `--gpus=all` + community nvidia toolkit | Required    | DinD, hooks, rules, skills, audit-log, agent-sandbox |

### `ollama-claude-cli`

Minimal environment for Claude CLI with Ollama on the host. Privacy-hardened by default. Outer GPU passthrough via `--gpus=all`.

**Included features**

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- `claude-code-backend:1`, `claude-code-privacy:1`, `claude-code-plugins:1`
- `container-firewall:1` — `claude-code` preset
- `non-root-enforcer:1`
- Host gateway alias, `--gpus=all`, port `11434`, persistent `~/.claude` volume

### `ollama-claude-cli-cpu`

Same floor as minimal, without `--gpus=all`. Prefer on Apple Silicon, Codespaces, and CPU-only hosts.

### `ollama-claude-cli-compose`

Bundled Ollama via Docker Compose. Floor plus `claude-code-mcp-servers:1` (GitHub + filesystem). GPU optional via compose `deploy` block.

### `ollama-claude-cli-python`

Floor plus official `python:1`, `claude-code-mcp-servers:1`, `uv`, project venv at `/workspaces/.venv`, and common AI libraries. Outer GPU via `--gpus=all`.

### `ollama-claude-cli-studio`

Full agentic studio on top of the floor:

- `claude-code-hooks:1`, `claude-code-rules:1`, `claude-code-skills:1`, `claude-code-plugins:1` (Ralph Loop on)
- `claude-code-mcp-servers:1`
- Docker-in-Docker (`docker-in-docker:4.0.0`)
- Community NVIDIA toolkit (`ghcr.io/srzstephen/devcontainer-features/nvidia-container-toolkit:1`) for **inner** DinD GPU — distinct from outer `--gpus=all`
- `claude-code-audit-log:1`
- `ai-agent-sandbox:1` (preset `moderate`, non-blocking)
- Firewall services: `claude-code,docker`

**GPU layers**

| Layer        | Config                                 | Purpose                                |
| ------------ | -------------------------------------- | -------------------------------------- |
| Outer        | `runArgs: ["--gpus=all"]`              | GPU devices in the studio container    |
| Inner (DinD) | community `nvidia-container-toolkit:1` | Toolkit packages for nested containers |

There is no `enable: false` on the community toolkit feature (that option was part of a removed in-house feature). The community feature installs toolkit packages when present.

## Layer B — Agent entry points

Agent-agnostic security floor (install + firewall tags + non-root + sandbox where listed). No Claude suite features. API-first agents do not require host Ollama.

### Grok Build

| Template                | Version | Extra                                                                  |
| ----------------------- | ------- | ---------------------------------------------------------------------- |
| `grok-build-cli`        | `1.0.0` | Minimal: community Grok Build, firewall `grok-build`, sandbox          |
| `grok-build-cli-studio` | `1.0.0` | DinD, host-isolation (optional/non-blocking), firewall + `docker`, MCP |

#### `grok-build-cli`

Minimal environment for xAI Grok Build CLI. API-first (no Ollama).

**Included features**

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Grok Build (`ghcr.io/sliekens/devcontainer-features/grok-build:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- `container-firewall:1` — `grok-build` preset (`xai` + `github` + `npm`)
- `non-root-enforcer:1`
- `ai-agent-sandbox:1` (preset `moderate`, non-blocking)
- Host `~/.grok` persistence via community feature + `initializeCommand`

#### `grok-build-cli-studio`

Studio on top of the Grok floor:

- Docker-in-Docker (`docker-in-docker:4.0.0`)
- `host-isolation:1` (`failOnWarning: false` — DinD needs privileges)
- Firewall services: `grok-build,docker`
- `mcp-server-manager:1` (GitHub MCP server by default)

Requires SuperGrok or X Premium Plus. Auth: `grok login` or `GROK_DEPLOYMENT_KEY`.

### Other Layer B agents

Shared floor: `non-root-enforcer:1`, `ai-agent-sandbox:1` (moderate, non-blocking), `container-firewall:1` with agent-appropriate tags, Node 20 + GitHub CLI. **No** Claude suite features. Studios deferred unless noted.

| Template          | Version | Install                                                  | Firewall services / extras                              | Persist                         |
| ----------------- | ------- | -------------------------------------------------------- | ------------------------------------------------------- | ------------------------------- |
| `pi-coding-agent` | `1.0.0` | npm `@earendil-works/pi-coding-agent` (bootstrap)        | `multi-ai`                                              | `~/.pi` volume                  |
| `hermes-agent`    | `1.0.0` | `devcontainer-community/hermes-agent.nousresearch.com:1` | `github,npm,openrouter`                                 | `~/.hermes` volume              |
| `codex-cli`       | `1.0.0` | `sliekens/codex:1`                                       | `codex` (`openai` + `github` + `npm`)                   | host `~/.codex` (feature bind)  |
| `gemini-cli`      | `1.0.0` | npm `@google/gemini-cli` (bootstrap)                     | `gemini` (`google` + `github` + `npm`)                  | `~/.gemini` volume              |
| `opencode-cli`    | `1.0.0` | `sliekens/opencode:1`                                    | `github,npm` + `opencode.ai,api.opencode.ai,models.dev` | host OpenCode data/config binds |

#### Studio decisions (v1)

| Agent    | Studio              | Decision                                         |
| -------- | ------------------- | ------------------------------------------------ |
| Pi       | deferred            | no DinD/MCP need proven                          |
| Hermes   | deferred / collapse | single `hermes-agent` until gateway/DinD dogfood |
| Codex    | deferred            | same ladder as Grok only if DinD split is real   |
| Gemini   | deferred            | API-first                                        |
| OpenCode | deferred            | API-first                                        |

#### Multi-ai-only agents (no dedicated Layer B template)

**Aider**, **Goose** (Block), and **Continue** (and similar) remain **multi-ai-only for v1**. Promote to a dedicated template only if demand, unique runtime requirements, or owned feature surface justify it. See [Template Portfolio](../explanation/template-portfolio.md).

## Other templates

| Template                 | Version | Notes                                                    |
| ------------------------ | ------- | -------------------------------------------------------- |
| `multi-ai-cli`           | `1.0.0` | Multi-agent workspace (Layer C; separate redesign track) |
| `cloud-native-k8s`       | `1.0.0` | kubectl, Helm, k3d, Tilt, DinD                           |
| `data-engineering-spark` | `1.0.0` | Spark, Jupyter, Polars, MinIO                            |

## Publishing location

```text
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

## Usage

```bash
npx @mrrobot0985/create-devcontainer <template-id> ./my-project
```

Or:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/<id>:latest
```
