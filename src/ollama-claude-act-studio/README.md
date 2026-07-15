# Ollama + Claude CLI + Act Studio (ollama-claude-act-studio)

Prototype devcontainer that combines Claude CLI with [nektos/act](https://github.com/nektos/act) to run local GitHub Actions workflows for autonomous project exploration, planning, and validation.

## What it does

When the container starts, the bootstrap script runs through a **lifecycle phase machine**:

1. **Hardware detection** — probes GPU VRAM, CPU cores, memory, Docker, act
2. **Model selection** — maps detected VRAM to local Ollama models
3. **Init** — seeds a wayfinder map from `README.md`, generates deterministic act workflows, prints HITL instructions
4. **HITL** — human runs `/grilling` and `/wayfinder` to define the destination and chart tickets
5. **AFK** — ralph-loop iterations via act process research and task tickets autonomously
6. **Verify** — branch-type bound act workflows validate commits, specs, and quality gates

The generated workflows are **deterministic templates**, not LLM-improvised YAML. They follow industry patterns (sandcastle-like sandboxing, branch-per-ticket isolation) and enforce conventional commits and branch naming.

## Lifecycle Phases

### Init

Runs automatically on first container start. It:

- Detects hardware and selects Ollama models
- Creates `$HOME/.claude/bootstrap-state/wayfinder/map.md` seeded from `README.md`
- Creates initial tickets: destination definition, frontier mapping, research
- Generates `.github/workflows/validate-branch.yml` and `.github/workflows/ralph-loop.yml`
- Sets up `.ralph/` state directory for loop tracking

### HITL (Human-In-The-Loop)

After init, the script pauses and instructs the human to:

```bash
claude
# Inside Claude:
/grilling    # Define the destination
/wayfinder   # Chart the map and tickets
```

When grilling ends, write a handoff:

```bash
echo '# Handoff' > $HOME/.claude/bootstrap-state/wayfinder/handoff.md
```

Then trigger AFK:

```bash
bash .devcontainer/bootstrap.sh afk
```

### AFK (Away-From-Keyboard)

Runs ralph-loop iterations for open AFK tickets (`wayfinder:research`, `wayfinder:task`):

- Each ticket gets an isolated git branch (`ralph/<ticket>`)
- Act runs the `ralph-loop.yml` workflow, which delegates to `.devcontainer/sandcastle/runner.mjs`
- The runner reads state from disk, executes the task type (research, spec, implement, quality), verifies, commits, and exits
- State lives in `.ralph/state/*.json`; logs in `.ralph/logs/`

Stop conditions:

| Signal | Meaning |
|--------|---------|
| `pending-review` | Task complete, needs human review |
| `blocked` | Needs human intervention |
| `open` | Ready for next iteration |

### Verify

Branch-type bound validation runs via act on every non-main branch:

| Branch type | Required validation |
|-------------|---------------------|
| `feat/*` | Conventional commits + SPEC.md/PROTOTYPE.md/ADR |
| `fix/*` | Conventional commits + regression test coverage |
| `docs/*` | Markdown file changes + link checks |
| `chore/*` | Basic lint/format checks |
| `ci/*` | Workflow validation |
| `refactor/*` | Same as `feat/*` |
| `test/*` | Test suite must pass |

## Hardware Awareness

The bootstrap script detects:

| Resource | Detection Method | Impact |
|----------|------------------|--------|
| NVIDIA GPU VRAM | `nvidia-smi` → `/proc/driver/nvidia/version` → `sysfs`/`lspci` → CPU fallback | Maps host to local model tier and context size |
| CPU cores | `nproc` | Task parallelism recommendations |
| Memory | `free` | Sub-agent spawn feasibility |
| Docker-in-Docker | `docker version` | Enables act and sub-agent instantiation |
| act | `act --version` | Ralph loop and validation execution |

### Model Selection

| Tier | VRAM | Haiku | Sonnet/Opus | Sub-agent | Context | Ollama tuning |
|------|------|-------|-------------|-----------|---------|---------------|
| CPU-only | 0GB | `phi3:3.8b` | `phi3:3.8b` | `phi3:3.8b` | 2K | defaults |
| Low | 8GB | `qwen2.5:7b` | `llama3.1:8b` | `codellama:7b` | 4K | `OLLAMA_MAX_LOADED_MODELS=1` |
| Mid | 12GB | `qwen2.5:7b` | `qwen2.5:14b` | `codellama:13b` | 8K | defaults |
| High | 24GB | `qwen2.5:14b` | `qwen2.5:32b` | `codellama:34b` | 16K | `OLLAMA_MAX_LOADED_MODELS=2` |
| Ultra | 48GB+ | `qwen2.5:32b` | `qwen2.5:72b` | `codellama:34b` | 32K+ | `OLLAMA_MAX_LOADED_MODELS=3` |

The selected models are written into Claude Code settings as environment overrides for `ANTHROPIC_DEFAULT_HAIKU_MODEL`, `ANTHROPIC_DEFAULT_SONNET_MODEL`, `ANTHROPIC_DEFAULT_OPUS_MODEL`, and `CLAUDE_CODE_SUBAGENT_MODEL`. If Ollama is reachable at `host.docker.internal:11434`, the chosen models are pulled automatically via the Ollama API during bootstrap.

## Subcommands

```bash
bash .devcontainer/bootstrap.sh        # Auto-detect phase and run
bash .devcontainer/bootstrap.sh init    # Force init phase
bash .devcontainer/bootstrap.sh afk     # Force AFK ralph loops
bash .devcontainer/bootstrap.sh verify  # Force branch validation
bash .devcontainer/bootstrap.sh status  # Show current phase and tickets
```

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

- This template is experimental. The lifecycle is **phase-driven**, not static.
- Workflows are deterministic templates shipped with the template, not generated by LLM.
- Ralph loops use fresh agent context per iteration; state lives on disk in `.ralph/`.
- Sandcastle-like sandboxing is simulated via isolated git branches and act containers.
- Sub-agent spawning via `npx create-devcontainer` requires Docker-in-Docker and sufficient CPU/memory.
- Without `--bind`, the workflow runner image does not include Claude and will skip the AI steps gracefully.
