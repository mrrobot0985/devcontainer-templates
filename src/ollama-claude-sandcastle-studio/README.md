# Ollama + Claude CLI + Sandcastle Studio (ollama-claude-sandcastle-studio)

Devcontainer for Claude CLI with Docker-based Sandcastle AFK task isolation. Hardware-aware model selection, HITL grilling sessions, and autonomous ralph loops in isolated containers.

## What it does

When the container starts, `bootstrap.sh` runs as a **long-lived daemon** through a lifecycle phase machine:

1. **Hardware detection** — probes GPU VRAM, CPU cores, memory, Docker
2. **Model selection** — maps detected VRAM to local Ollama models
3. **Init** — uses `claude -p` to generate a wayfinder map from `README.md` (which may be a skeleton), creates initial tickets, copies sandcastle scripts
4. **HITL** — **BLOCKING**. The script loops, printing reminders every 30 seconds, until the human completes grilling and writes `$HOME/.claude/bootstrap-state/wayfinder/handoff.md`
5. **AFK** — **CONTINUOUS**. A never-ending daemon loop processes AFK tickets in Docker sandboxes, sleeps 60 seconds, and repeats. The container only stops when self-improvement work is exhausted.
6. **Verify** — branch-type bound sandcastle scripts validate commits, specs, and quality gates

**Technological separation:**

- **HITL** runs directly in the devcontainer (interactive claude sessions). The bootstrap script blocks until the human is done.
- **AFK** runs in Docker-isolated sandboxes, one container per ticket, bind-mounting the workspace. The bootstrap script runs this in a continuous loop.

All sandcastle scripts are deterministic templates shipped with the template.

## Lifecycle Phases

### Init

Runs automatically on first container start. It:

- Detects hardware and selects Ollama models
- Uses `claude -p` with the Ollama backend to read `README.md` and generate a structured wayfinder map — if the README is a skeleton, the map notes that the purpose needs human definition
- Uses `claude -p` again to generate 3 initial tickets (destination, frontier, research)
- Falls back to deterministic templates if `claude -p` is unavailable
- Copies sandcastle scripts to `.devcontainer/sandcastle/`
- Installs a shell hook that reminds the user of HITL requirements on every new shell
- Creates initial tickets: destination definition, frontier mapping, research
- Copies sandcastle scripts to `.devcontainer/sandcastle/`
- Sets up `.ralph/` state directory for loop tracking

### HITL (Human-In-The-Loop)

After init, the bootstrap script **blocks** and prints a prominent banner every 30 seconds:

```
╔════════════════════════════════════════════════════════════════╗
║  HITL REQUIRED — Human-In-The-Loop                           ║
║                                                                ║
║  The wayfinder map has been seeded from README.md.             ║
║  The README is a skeleton — you must define the purpose.       ║
║                                                                ║
║  REQUIRED ACTIONS:                                             ║
║    1. Run:  claude                                             ║
║    2. Use:  /grilling                                          ║
║       Grill on the destination until sharp.                    ║
║    3. Use:  /wayfinder                                         ║
║       Chart the map and create frontier tickets.               ║
║                                                                ║
║  When the grilling session ends, write a handoff:              ║
║    echo '# Handoff' > $HOME/.claude/bootstrap-state/wayfinder/handoff.md
╚════════════════════════════════════════════════════════════════╝
```

The script **does not proceed** until `handoff.md` is written. Every new shell in the container also shows this reminder via a `.bashrc` hook.

When `handoff.md` appears, the script **auto-transitions** to AFK mode — no manual command needed.

### AFK (Away-From-Keyboard)

Runs as a **continuous daemon** after HITL completes. The script never exits — it loops forever, processing AFK tickets and sleeping:

- Each AFK cycle finds open tickets (`wayfinder:research`, `wayfinder:task`)
- Each ticket gets an isolated git branch (`ralph/<ticket>`)
- A Docker container spins up with the workspace bind-mounted, runs the sandcastle runner, verifies, commits, and exits
- The container uses `mcr.microsoft.com/devcontainers/base:bookworm` as the base image
- After each batch, branch validation runs via sandcastle
- If no tickets remain, the daemon sleeps 60 seconds and checks again
- State lives in `.ralph/state/*.json`; logs in `.ralph/logs/`

The container only stops when:

- You stop the container explicitly
- No open tickets exist AND no self-improvement opportunities are detected

Stop conditions per ticket:

| Signal | Meaning |
|--------|---------|
| `pending-review` | Task complete, needs human review |
| `blocked` | Needs human intervention |
| `open` | Ready for next iteration |

### Verify

Branch-type bound validation runs via sandcastle scripts on every non-main branch:

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
| Docker-in-Docker | `docker version` | Enables sandcastle container isolation |

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
bash .devcontainer/bootstrap.sh         # Auto-detect phase and run
bash .devcontainer/bootstrap.sh init    # Force init phase
bash .devcontainer/bootstrap.sh hitl    # Force HITL blocking
bash .devcontainer/bootstrap.sh afk     # Force AFK ralph loops (daemon)
bash .devcontainer/bootstrap.sh auto    # Self-driving lifecycle via headless Matt Pocock skills
bash .devcontainer/bootstrap.sh prototype "<question>"  # Headless prototype generation
bash .devcontainer/bootstrap.sh verify  # Force branch validation
bash .devcontainer/bootstrap.sh status  # Show current phase and tickets
```

### Auto Mode

The `auto` subcommand self-drives the full project lifecycle using [Matt Pocock's skills](https://github.com/mattpocock/skills) headlessly:

1. If no `SPEC.md` exists → runs `/to-spec` via `headless-to-spec.sh`
2. If no `WAYFINDER.md` exists → runs `/wayfinder` via `headless-wayfinder.sh`
3. If no tickets exist → runs `/to-tickets` via `headless-to-tickets.sh`
4. If open AFK tickets exist → runs `/implement` via `headless-implement.sh`
5. If pending-review tickets exist → runs `/code-review` via `headless-code-review.sh`

Safety limits (configurable via environment):

- `MAX_AUTO_ITERATIONS=10` — max cycles before halting
- `MAX_TICKETS_PER_CYCLE=3` — max tickets implemented per cycle
- `AUTO_SLEEP_SECONDS=30` — pause between cycles
- `AUTO_MERGE=false` — set to `true` to auto-merge approved branches

### Prototype Mode

The `prototype` subcommand invokes `/prototype` headlessly to answer a design question with throwaway code. Example:

```bash
bash .devcontainer/bootstrap.sh prototype "Does this state machine feel right?"
```

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- Claude Code Plugins (`claude-code-plugins`) with Ralph Loop and Workflows pre-enabled
- GitHub CLI (`github-cli`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Docker-in-Docker (for sandcastle container isolation)

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
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-sandcastle-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-sandcastle-studio ./my-project
```

## Notes

- This template is experimental. The lifecycle is **phase-driven**, not static.
- Sandcastle scripts are deterministic templates shipped with the template, not generated by LLM.
- Ralph loops use fresh agent context per iteration; state lives on disk in `.ralph/`.
- AFK tasks run in Docker containers with the workspace bind-mounted, providing isolation without act complexity.
- Sub-agent spawning via `npx create-devcontainer` requires Docker-in-Docker and sufficient CPU/memory.
