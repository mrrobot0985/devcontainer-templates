# Template Catalog

This collection publishes **purpose-driven** devcontainer templates for AI coding agents and related workflows. The inventory is larger than a single Claude pair: a Claude + Ollama family (Layer A), a multi-agent evaluation workspace (Layer C), and provisional domain stacks (Layer D). Additional first-class agent entry points (Layer B) are planned.

**Portfolio intent** (layers, sense rules, deferred Layer D decision) lives in [Template Portfolio](../explanation/template-portfolio.md). Design rules for families vs options live in [Template Design Philosophy](../explanation/template-design.md).

> **Catalog completeness:** This page documents templates present in the repository today. A full cross-layer catalog refresh, choosing-guide overhaul, and `create-devcontainer` registry sync are tracked as later portfolio phases (stabilize Layer A / Phase 6 docs). Until then, treat Layer D rows as provisional and prefer the portfolio doc for “what belongs.”

| Template                    | Version | Layer | Description                                                                                                                                                               |
| --------------------------- | ------- | ----- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `ollama-claude-cli`         | `1.0.0` | A     | Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings. Includes Node.js and GitHub CLI. |
| `ollama-claude-cli-cpu`     | `1.0.0` | A     | CPU-only Claude + Ollama entry point (no GPU required). Suitable for Apple Silicon, Codespaces, and cloud CPU hosts.                                                      |
| `ollama-claude-cli-compose` | `1.0.0` | A     | Claude CLI with bundled Ollama via Docker Compose. No host Ollama required.                                                                                               |
| `ollama-claude-cli-python`  | `1.0.0` | A     | Claude + Ollama with Python 3.12, `uv`, and common LLM/AI libraries.                                                                                                      |
| `ollama-claude-cli-studio`  | `1.0.0` | A     | Full studio: Docker-in-Docker, NVIDIA Container Toolkit (optional), lifecycle hooks, rules, skills, plugins, firewall, persistence.                                       |
| `multi-ai-cli`              | `1.0.0` | C     | Multi-agent evaluation workspace bundling several AI CLIs with shared MCP-oriented setup. Prefer dedicated Layer B templates for daily single-agent work once they ship.  |
| `cloud-native-k8s`          | `1.0.0` | D     | Kubernetes / cloud-native tooling (kubectl, Helm, k3d, Tilt, DinD). **Provisional** — Layer D decision deferred.                                                          |
| `data-engineering-spark`    | `1.0.0` | D     | Spark / lakehouse-style local data engineering stack. **Provisional** — Layer D decision deferred.                                                                        |

Claude + host-Ollama templates expect Ollama on the host at `http://host.docker.internal:11434` unless you use `ollama-claude-cli-compose`.

For hardware and workflow selection among Claude variants, see [Choosing a Template](../tutorials/choosing-a-template.md).

## `ollama-claude-cli`

A minimal environment for Claude CLI with a pre-configured Ollama backend. Privacy-hardened by default. GPU passthrough enabled.

### Included features

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- Custom backend configuration (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0`)
- Privacy defaults (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0`)
- Claude Code Plugins (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0`)
- Container firewall (`ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0`) — `claude-code` preset
- Host gateway alias and `--gpus=all` passthrough
- Port forwarding for Ollama (`11434`)
- Persistent `~/.claude` volume

### Options

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

### Usage

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Or with the helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```

## `ollama-claude-cli-studio`

The full studio environment with Ollama backend pre-configured. Combines backend configuration, observability hooks, privacy defaults, governance rules, skills, plugins, Docker-in-Docker, and optional NVIDIA Container Toolkit.

### Included features

- Node.js 20 (`ghcr.io/devcontainers/features/node:2.1.0`)
- Claude CLI (`ghcr.io/anthropics/devcontainer-features/claude-code:1`)
- GitHub CLI (`ghcr.io/devcontainers/features/github-cli:1`)
- Custom backend configuration (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-backend:0`)
- Lifecycle hooks (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-hooks:0`)
- Privacy defaults (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-privacy:0`)
- Behavior rules (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-rules:0`)
- Skills library (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-skills:0`)
- Claude Code Plugins (`ghcr.io/mrrobot0985/devcontainer-features/claude-code-plugins:0`) with Ralph Loop pre-enabled
- Docker-in-Docker (`ghcr.io/devcontainers/features/docker-in-docker:4.0.0`)
- NVIDIA Container Toolkit (`ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0`, disabled by default)
- Container firewall (`ghcr.io/mrrobot0985/devcontainer-features/container-firewall:0`) — `claude-code` preset
- Host gateway alias and `--gpus=all` passthrough
- Port forwarding for Ollama (`11434`)
- Persistent `~/.claude` volume

### Options

| Option         | Type   | Default | Description                         |
| -------------- | ------ | ------- | ----------------------------------- |
| `imageVariant` | string | `jammy` | Ubuntu version (`jammy` or `focal`) |

### Usage

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest
```

Or with the helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```

## Other templates in the tree

Detailed feature breakdowns for the remaining Layer A variants, Layer C, and Layer D templates live primarily in each template’s `src/<id>/README.md`. Summary:

| Template                    | Where to read more                                                                       |
| --------------------------- | ---------------------------------------------------------------------------------------- |
| `ollama-claude-cli-cpu`     | [src/ollama-claude-cli-cpu/README.md](../../src/ollama-claude-cli-cpu/README.md)         |
| `ollama-claude-cli-compose` | [src/ollama-claude-cli-compose/README.md](../../src/ollama-claude-cli-compose/README.md) |
| `ollama-claude-cli-python`  | [src/ollama-claude-cli-python/README.md](../../src/ollama-claude-cli-python/README.md)   |
| `multi-ai-cli`              | [src/multi-ai-cli/README.md](../../src/multi-ai-cli/README.md)                           |
| `cloud-native-k8s`          | [src/cloud-native-k8s/README.md](../../src/cloud-native-k8s/README.md)                   |
| `data-engineering-spark`    | [src/data-engineering-spark/README.md](../../src/data-engineering-spark/README.md)       |

Apply any of them the same way:

```bash
npx @mrrobot0985/create-devcontainer <template-id> ./my-project
# or
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/<template-id>:latest
```

## Publishing location

Templates are published to GitHub Container Registry:

```text
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```
