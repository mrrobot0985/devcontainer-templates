# Ollama + Claude CLI + Act Studio (ollama-claude-act-studio)

Prototype devcontainer that combines Claude CLI with [nektos/act](https://github.com/nektos/act) to run a local GitHub Actions workflow for autonomous project exploration and planning.

## What it does

When the container starts, the bootstrap script:

1. Configures the Ollama backend connection
2. **Probes the hardware tier** — GPU, CPU cores, memory, Docker-in-Docker, act
3. **Asks Claude to generate** `.act/workflows/bootstrap.yml` tailored to the detected resources
4. **Executes the generated workflow** via `act`

The workflow then runs `claude -p` commands to:

- Read and summarize `README.md`
- Plan the next iteration of the `/prototype`
- Optionally spawn containerized Claude sub-agents via `npx create-devcontainer` when GPU + Docker are available

## Hardware Awareness

The bootstrap script detects:

| Resource | Detection Method | Impact on Workflow |
|----------|------------------|-------------------|
| NVIDIA GPU | `nvidia-smi` | Workflow includes GPU-accelerated steps and sub-agent spawning |
| CPU cores | `nproc` | Informs task parallelism recommendations |
| Memory | `free` | Determines if sub-agents can be spawned |
| Docker-in-Docker | `docker version` | Enables `npx create-devcontainer` sub-agent instantiation |
| act | `act --version` | Determines if the generated workflow can be executed immediately |

If act is not available, the workflow is still generated to `.act/workflows/bootstrap.yml` for manual execution later.

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- nektos/act (`ghcr.io/dhoeric/features/act`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Docker-in-Docker (for act to spawn workflow containers)

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-act-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-act-studio ./my-project
```

## Prototype Notes

- This template is experimental. The act workflow is **generated at runtime** by Claude based on detected hardware.
- When running via `act --bind`, the workflow shares the host container's filesystem and can access the installed `claude` binary.
- Sub-agent spawning via `npx create-devcontainer` requires Docker-in-Docker and sufficient CPU/memory.
- Without `--bind`, the workflow runner image does not include Claude and will skip the AI steps gracefully.
