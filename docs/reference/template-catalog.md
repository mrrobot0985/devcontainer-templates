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

## Other templates

| Template                 | Version | Notes                                                                              |
| ------------------------ | ------- | ---------------------------------------------------------------------------------- |
| `multi-ai-cli`           | `1.1.0` | Layer C multi-agent evaluation (Claude, Grok, Pi, Hermes, Codex, Gemini, OpenCode) |
| `cloud-native-k8s`       | `1.0.0` | kubectl, Helm, k3d, Tilt, DinD                                                     |
| `data-engineering-spark` | `1.0.0` | Spark, Jupyter, Polars, MinIO                                                      |

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
