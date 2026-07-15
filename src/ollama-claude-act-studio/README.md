# Ollama + Claude CLI + Act Studio (ollama-claude-act-studio)

Prototype devcontainer that combines Claude CLI with [nektos/act](https://github.com/nektos/act) to run a local GitHub Actions workflow for autonomous project exploration and planning.

## What it does

When the container starts, the bootstrap script:

1. Configures the Ollama backend connection
2. **Probes the hardware tier** — GPU VRAM, CPU cores, memory, Docker-in-Docker, act
3. **Selects local Ollama models** matched to the detected VRAM tier
4. **Asks Claude to generate** `.github/workflows/bootstrap.yml` tailored to the detected resources
5. **Executes the generated workflow** via `act`

The workflow then runs `claude -p` commands to:

- Read and summarize `README.md`
- Plan the next iteration of the `/prototype`
- Optionally spawn containerized sub-agents via `npx create-devcontainer` when GPU + Docker are available

## Hardware Awareness

The bootstrap script detects:

| Resource | Detection Method | Impact on Workflow |
|----------|------------------|-------------------|
| NVIDIA GPU VRAM | `nvidia-smi` → `/proc/driver/nvidia/version` → `sysfs`/`lspci` → CPU fallback | Maps the running host to a local model tier and context size |
| CPU cores | `nproc` | Informs task parallelism recommendations |
| Memory | `free` | Determines if sub-agents can be spawned |
| Docker-in-Docker | `docker version` | Enables `npx create-devcontainer` sub-agent instantiation |
| act | `act --version` | Determines if the generated workflow can be executed immediately |

If act is not available, the workflow is still generated to `.github/workflows/bootstrap.yml` for manual execution later.

### Model Selection

The bootstrap script measures available NVIDIA GPU VRAM and selects Ollama models that fit the host. Cloud-only model tags are remapped to local-capable equivalents.

| Tier | VRAM | Haiku | Sonnet/Opus | Sub-agent | Context | Ollama tuning |
|------|------|-------|-------------|-----------|---------|---------------|
| CPU-only | 0GB | `phi3:3.8b` | `phi3:3.8b` | `phi3:3.8b` | 2K | defaults |
| Low | 8GB | `qwen2.5:7b` | `llama3.1:8b` | `codellama:7b` | 4K | `OLLAMA_MAX_LOADED_MODELS=1`, `OLLAMA_NUM_PARALLEL=1` |
| Mid | 12GB | `qwen2.5:7b` | `qwen2.5:14b` | `codellama:13b` | 8K | defaults |
| High | 24GB | `qwen2.5:14b` | `qwen2.5:32b` | `codellama:34b` | 16K | `OLLAMA_MAX_LOADED_MODELS=2`, `OLLAMA_NUM_PARALLEL=1` |
| Ultra | 48GB+ | `qwen2.5:32b` | `qwen2.5:72b` | `codellama:34b` | 32K+ | `OLLAMA_MAX_LOADED_MODELS=3`, `OLLAMA_NUM_PARALLEL=1` |

The selected models are written into Claude Code settings as environment overrides for `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, and `CLAUDE_CODE_SUBAGENT_MODEL`. If Ollama is reachable at `host.docker.internal:11434`, the chosen models are pulled automatically via the Ollama API during bootstrap. The prompt sent to the model also includes the detected hardware context (for example, GPU name and VRAM) so the generated workflow respects the host's limits.

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

- This template is experimental. The act workflow is **generated at runtime** based on detected hardware.
- When running via `act --bind`, the workflow shares the host container's filesystem and can access the installed `claude` binary.
- Sub-agent spawning via `npx create-devcontainer` requires Docker-in-Docker and sufficient CPU/memory.
- Without `--bind`, the workflow runner image does not include Claude and will skip the AI steps gracefully.
