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

Install + security floor + home persistence. **No Claude suite** on non-Claude agents. Prefer community install features where they exist.

Shared floor (unless noted): `non-root-enforcer:1`, `ai-agent-sandbox:1` (moderate), `container-firewall:1` with agent-appropriate service tags, Node 20, GitHub CLI.

| Template                | Version | Agent                                  | Firewall services               | Persist         |
| ----------------------- | ------- | -------------------------------------- | ------------------------------- | --------------- |
| `grok-build-cli`        | `1.0.0` | Grok Build (community)                 | `grok-build`                    | `~/.grok`       |
| `grok-build-cli-studio` | `1.0.0` | Grok + DinD + MCP                      | `grok-build,docker`             | `~/.grok`       |
| `pi-coding-agent`       | `1.0.0` | Pi (`@earendil-works/pi-coding-agent`) | `multi-ai`                      | `~/.pi`         |
| `hermes-agent`          | `1.0.0` | Hermes (community)                     | `github,npm,openrouter`         | `~/.hermes`     |
| `codex-cli`             | `1.0.0` | OpenAI Codex (community)               | `codex`                         | `~/.codex`      |
| `gemini-cli`            | `1.0.0` | Google Gemini CLI                      | `gemini`                        | `~/.gemini`     |
| `opencode-cli`          | `1.0.0` | OpenCode (community)                   | `github,npm` + OpenCode domains | OpenCode config |

Aider, Goose, and Continue stay **multi-ai-only** for v1 (no dedicated Layer B templates unless demand proves otherwise).

## Layer C — Multi-agent evaluation

| Template       | Version | Notes                                                                              |
| -------------- | ------- | ---------------------------------------------------------------------------------- |
| `multi-ai-cli` | `1.1.0` | Layer C multi-agent evaluation (Claude, Grok, Pi, Hermes, Codex, Gemini, OpenCode) |

## Layer D — Domain stacks (owned security floor)

These templates are **domain stacks** outside the agent-first growth path (see [Template Portfolio — Layer D](../explanation/template-portfolio.md#layer-d--domain-stacks-owned-security-floor)). They now ship the **owned security floor** (re-feature path from issue #66): `container-firewall:1`, `non-root-enforcer:1`, and `ai-agent-sandbox:1` (preset `moderate`, non-blocking). **No Claude suite.** Prefer Layers A–C for AI coding agent work.

| Template                 | Version | Notes                                                                                           |
| ------------------------ | ------- | ----------------------------------------------------------------------------------------------- |
| `cloud-native-k8s`       | `1.1.0` | Layer D · kubectl, Helm, k3d, Tilt, DinD · floor with firewall services `github,docker,npm,apt` |
| `data-engineering-spark` | `1.1.0` | Layer D · Spark, Jupyter, Polars, MinIO · floor with firewall services `github,pypi,docker,apt` |

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
