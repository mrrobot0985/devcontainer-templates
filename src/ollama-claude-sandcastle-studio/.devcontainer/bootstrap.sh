#!/bin/bash
set -euo pipefail

# Bootstrap — Lifecycle orchestrator for Matt Pocock's skills.
#
# Phase machine:
#   init  → Hardware detection, model selection, use claude -p to seed wayfinder
#           map + tickets from README.md skeleton, copy sandcastle scripts.
#   hitl  → BLOCKING. Forces the human to complete grilling before the
#           container can proceed. Loops, printing reminders, until
#           handoff.md is written.
#   afk   → CONTINUOUS. Daemon loop that processes AFK tickets in Docker
#           sandboxes, sleeps, and repeats until no self-improvement work
#           remains.
#   verify→ Branch-type validation via sandcastle scripts.
#
# Technological separation:
#   HITL (Human-In-The-Loop) → runs directly in the devcontainer, interactive.
#   AFK  (Away-From-Keyboard) → runs in Docker-isolated sandboxes.
#
# This script is designed as a long-running postCreateCommand. It never exits
# during normal operation — HITL blocks until the human is done, then AFK runs
# forever, processing tickets and sleeping.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(pwd)"
STATE_DIR="$HOME/.claude/bootstrap-state"
WAYFINDER_DIR="$STATE_DIR/wayfinder"
RALPH_DIR="$WORKSPACE_DIR/.ralph"

# Claude backend env (for claude -p invocations)
export ANTHROPIC_API_KEY=""
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_BASE_URL="$OLLAMA_BASE_URL"

# --- Global hardware / model state ---
GPU_NAME=""
VRAM_GB=0
CPU_CORES=""
MEM_GB=""
DOCKER_AVAILABLE="false"
OLLAMA_STATUS="unreachable"
HARDWARE_TIER="cpu-only"

MODEL_HAIKU=""
MODEL_SONNET=""
MODEL_OPUS=""
MODEL_SUBAGENT=""
CONTEXT_SIZE=2048

OLLAMA_MAX_LOADED_MODELS=1
OLLAMA_NUM_PARALLEL=1

# ============================================================================
# Helpers
# ============================================================================

persist_env_var() {
    local var_name="$1"
    local var_value="$2"
    for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rcfile" ]; then
            sed -i "/^export ${var_name}=/d" "$rcfile" 2>/dev/null || true
            echo "export ${var_name}=\"${var_value}\"" >> "$rcfile"
        fi
    done
    eval "export ${var_name}=\"${var_value}\""
}

persist_env_var "OLLAMA_HOST" "$OLLAMA_HOST"

probe_hardware() {
    CPU_CORES="$(nproc 2>/dev/null || echo "unknown")"

    if command -v free >/dev/null 2>&1; then
        local mem_kb=""
        mem_kb="$(free | awk '/^Mem:/{print $2}')"
        if [[ "$mem_kb" =~ ^[0-9]+$ ]]; then
            MEM_GB="$((mem_kb / 1024 / 1024))"
        else
            MEM_GB="unknown"
        fi
    else
        MEM_GB="unknown"
    fi

    GPU_NAME=""
    VRAM_GB=0

    if command -v nvidia-smi >/dev/null 2>&1; then
        local nvidia_out=""
        nvidia_out="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 || true)"
        if [ -n "$nvidia_out" ]; then
            GPU_NAME="$(echo "$nvidia_out" | cut -d',' -f1 | sed 's/^ *//;s/ *$//')"
            local vram_mb=""
            vram_mb="$(echo "$nvidia_out" | cut -d',' -f2 | sed 's/^ *//;s/ *$//')"
            if [[ "$vram_mb" =~ ^[0-9]+$ ]]; then
                VRAM_GB="$((vram_mb / 1024))"
            fi
        fi
    fi

    if [ "$VRAM_GB" -eq 0 ] && [ -f /proc/driver/nvidia/version ]; then
        GPU_NAME="${GPU_NAME:-NVIDIA GPU (driver present, nvidia-smi unavailable)}"
        local info_file=""
        info_file="$(find /proc/driver/nvidia/gpus -maxdepth 2 -type f -name information 2>/dev/null | head -1 || true)"
        if [ -n "$info_file" ] && [ -f "$info_file" ]; then
            local vram_line=""
            vram_line="$(grep -i 'Video Memory' "$info_file" 2>/dev/null | head -1 || true)"
            if [ -n "$vram_line" ]; then
                local vram_number=""
                vram_number="$(echo "$vram_line" | grep -oE '[0-9]+' | head -1 || true)"
                if [ -n "$vram_number" ] && [[ "$vram_number" =~ ^[0-9]+$ ]]; then
                    if [ "$vram_number" -gt 1048576 ]; then
                        VRAM_GB="$((vram_number / 1024 / 1024))"
                    elif [ "$vram_number" -gt 1024 ]; then
                        VRAM_GB="$((vram_number / 1024))"
                    else
                        VRAM_GB="$vram_number"
                    fi
                fi
            fi
        fi
    fi

    if [ "$VRAM_GB" -eq 0 ] && command -v lspci >/dev/null 2>&1; then
        local lspci_line=""
        lspci_line="$(lspci 2>/dev/null | grep -i 'nvidia' | head -1 || true)"
        if [ -n "$lspci_line" ]; then
            local pci_slot=""
            pci_slot="$(echo "$lspci_line" | awk '{print $1}')"
            GPU_NAME="$(echo "$lspci_line" | cut -d' ' -f3- | sed 's/ (rev.*)//')"
            local sysfs_pci="/sys/bus/pci/devices/0000:${pci_slot}"
            if [ -d "$sysfs_pci" ]; then
                local drm_path=""
                for drm_path in /sys/class/drm/card*/device; do
                    if [ "$(readlink -f "$drm_path" 2>/dev/null || true)" = "$(readlink -f "$sysfs_pci" 2>/dev/null || true)" ]; then
                        if [ -f "$drm_path/mem_info_vram_total" ]; then
                            local vram_bytes=""
                            vram_bytes="$(cat "$drm_path/mem_info_vram_total" 2>/dev/null || true)"
                            if [ -n "$vram_bytes" ] && [[ "$vram_bytes" =~ ^[0-9]+$ ]]; then
                                VRAM_GB="$((vram_bytes / 1024 / 1024 / 1024))"
                                break
                            fi
                        fi
                    fi
                done
            fi
        fi
    fi

    if [ "$VRAM_GB" -eq 0 ] && [ -z "$GPU_NAME" ]; then
        GPU_NAME="CPU-only"
    fi

    if docker version >/dev/null 2>&1; then
        DOCKER_AVAILABLE="true"
    fi

    if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
        OLLAMA_STATUS="reachable"
    fi

    if [ "$VRAM_GB" -eq 0 ]; then
        HARDWARE_TIER="cpu-only"
    elif [ "$VRAM_GB" -lt 12 ]; then
        HARDWARE_TIER="low"
    elif [ "$VRAM_GB" -lt 24 ]; then
        HARDWARE_TIER="mid"
    elif [ "$VRAM_GB" -lt 48 ]; then
        HARDWARE_TIER="high"
    else
        HARDWARE_TIER="ultra"
    fi
}

select_models() {
    local vram_gb="$1"
    if [ "$vram_gb" -eq 0 ]; then
        MODEL_HAIKU="phi3:3.8b"
        MODEL_SONNET="phi3:3.8b"
        MODEL_OPUS="phi3:3.8b"
        MODEL_SUBAGENT="phi3:3.8b"
        CONTEXT_SIZE=2048
    elif [ "$vram_gb" -lt 12 ]; then
        MODEL_HAIKU="qwen2.5:7b"
        MODEL_SONNET="llama3.1:8b"
        MODEL_OPUS="llama3.1:8b"
        MODEL_SUBAGENT="codellama:7b"
        CONTEXT_SIZE=4096
    elif [ "$vram_gb" -lt 24 ]; then
        MODEL_HAIKU="qwen2.5:7b"
        MODEL_SONNET="qwen2.5:14b"
        MODEL_OPUS="qwen2.5:14b"
        MODEL_SUBAGENT="codellama:13b"
        CONTEXT_SIZE=8192
    elif [ "$vram_gb" -lt 48 ]; then
        MODEL_HAIKU="qwen2.5:14b"
        MODEL_SONNET="qwen2.5:32b"
        MODEL_OPUS="qwen2.5:32b"
        MODEL_SUBAGENT="codellama:34b"
        CONTEXT_SIZE=16384
    else
        MODEL_HAIKU="qwen2.5:32b"
        MODEL_SONNET="qwen2.5:72b"
        MODEL_OPUS="qwen2.5:72b"
        MODEL_SUBAGENT="codellama:34b"
        CONTEXT_SIZE=32768
    fi
}

set_ollama_env() {
    case "$HARDWARE_TIER" in
        cpu-only|low|mid)
            OLLAMA_MAX_LOADED_MODELS=1
            OLLAMA_NUM_PARALLEL=1
            ;;
        high)
            OLLAMA_MAX_LOADED_MODELS=2
            OLLAMA_NUM_PARALLEL=1
            ;;
        ultra)
            OLLAMA_MAX_LOADED_MODELS=3
            OLLAMA_NUM_PARALLEL=1
            ;;
    esac
    export OLLAMA_MAX_LOADED_MODELS
    export OLLAMA_NUM_PARALLEL
    export OLLAMA_CONTEXT_SIZE="$CONTEXT_SIZE"
    persist_env_var "OLLAMA_MAX_LOADED_MODELS" "$OLLAMA_MAX_LOADED_MODELS"
    persist_env_var "OLLAMA_NUM_PARALLEL" "$OLLAMA_NUM_PARALLEL"
    persist_env_var "OLLAMA_CONTEXT_SIZE" "$CONTEXT_SIZE"
}

write_claude_settings() {
    persist_env_var "ANTHROPIC_DEFAULT_HAIKU_MODEL" "$MODEL_HAIKU"
    persist_env_var "ANTHROPIC_DEFAULT_SONNET_MODEL" "$MODEL_SONNET"
    persist_env_var "ANTHROPIC_DEFAULT_OPUS_MODEL" "$MODEL_OPUS"
    persist_env_var "CLAUDE_CODE_SUBAGENT_MODEL" "$MODEL_SUBAGENT"
}

pull_ollama_models() {
    if [ "$OLLAMA_STATUS" != "reachable" ]; then
        echo "Ollama host unreachable at $OLLAMA_BASE_URL — skipping model pull."
        return 0
    fi
    local models_to_pull=("$MODEL_HAIKU" "$MODEL_SONNET" "$MODEL_OPUS" "$MODEL_SUBAGENT")
    local unique_models=""
    unique_models="$(printf '%s\n' "${models_to_pull[@]}" | sort -u)"
    while IFS= read -r model; do
        [ -n "$model" ] || continue
        echo "Pulling Ollama model: $model ..."
        if curl -fsSL -X POST "$OLLAMA_BASE_URL/api/pull" \
            -H 'Content-Type: application/json' \
            -d "{\"model\":\"$model\"}" >/dev/null 2>&1; then
            echo "  ok: $model"
        else
            echo "  failed: $model (will retry at runtime if needed)"
        fi
    done <<< "$unique_models"
}

# ============================================================================
# Sandcastle Docker runner
# ============================================================================

run_sandcastle_container() {
    local ticket_id="$1"
    local task_desc="$2"
    local iteration="${3:-1}"
    local branch="${4:-main}"

    local state_file="$RALPH_DIR/state/${ticket_id}.json"
    local log_file="$RALPH_DIR/logs/${ticket_id}-iter${iteration}.log"
    local container_name="sandcastle-${ticket_id}-iter${iteration}"

    echo "Spinning up sandcastle container: $container_name"

    docker run --rm \
        --name "$container_name" \
        -v "$WORKSPACE_DIR:/workspace" \
        -w /workspace \
        -e TICKET_ID="$ticket_id" \
        -e TASK="$task_desc" \
        -e ITERATION="$iteration" \
        -e BRANCH="$branch" \
        -e OLLAMA_HOST="$OLLAMA_HOST" \
        -e CLAUDE_CONFIG_DIR="/home/vscode/.claude" \
        --add-host=host.docker.internal:host-gateway \
        mcr.microsoft.com/devcontainers/base:bookworm \
        bash -c "
            apt-get update -qq && apt-get install -y -qq nodejs git curl jq >/dev/null 2>&1
            cd /workspace
            node .devcontainer/sandcastle/runner.mjs \
                --ticket '$ticket_id' \
                --task '$task_desc' \
                --iteration '$iteration' \
                --workspace /workspace
        " > "$log_file" 2>&1

    local rc=$?
    echo "Sandcastle container exited with code $rc"
    return $rc
}

# ============================================================================
# Phase detection
# ============================================================================

detect_phase() {
    if [ ! -d "$WAYFINDER_DIR" ]; then
        echo "init"
        return
    fi
    if [ ! -f "$WAYFINDER_DIR/handoff.md" ]; then
        echo "hitl"
        return
    fi
    if [ -d "$RALPH_DIR/state" ]; then
        local pending
        pending="$(find "$RALPH_DIR/state" -maxdepth 1 -name '*.json' -print 2>/dev/null | wc -l)"
        if [ "$pending" -gt 0 ]; then
            echo "afk"
            return
        fi
    fi
    echo "verify"
}

# ============================================================================
# Phase: init — seed wayfinder via claude -p
# ============================================================================

phase_init() {
    echo "============================================"
    echo "  Phase: INIT — Seeding workspace"
    echo "============================================"
    echo ""

    probe_hardware
    select_models "$VRAM_GB"
    set_ollama_env
    write_claude_settings

    echo "Hardware: $GPU_NAME | VRAM: ${VRAM_GB}GB | Tier: $HARDWARE_TIER"
    echo "Models: haiku=$MODEL_HAIKU sonnet=$MODEL_SONNET opus=$MODEL_OPUS subagent=$MODEL_SUBAGENT"
    echo ""

    pull_ollama_models
    echo ""

    mkdir -p "$WAYFINDER_DIR" "$WAYFINDER_DIR/tickets"

    # Copy README.md as seed
    local readme_dest="$WAYFINDER_DIR/README.seed.md"
    if [ -f "$WORKSPACE_DIR/README.md" ]; then
        cp "$WORKSPACE_DIR/README.md" "$readme_dest"
    else
        echo "# Project" > "$readme_dest"
        echo "Purpose to be defined." >> "$readme_dest"
    fi

    # Use claude -p to generate the wayfinder map from the README skeleton
    echo "Using claude -p to generate wayfinder map from README.md ..."
    if command -v claude >/dev/null 2>&1; then
        local prompt_map
        prompt_map="Read the file at $readme_dest. It is a README skeleton — the project's purpose is not yet defined. Generate a wayfinder map markdown document with exactly these sections:

## Destination
A short paragraph noting that the project's purpose needs to be defined through human collaboration. Reference the README skeleton.

## Notes
- Hardware tier: $HARDWARE_TIER
- Models: haiku=$MODEL_HAIKU, sonnet=$MODEL_SONNET, opus=$MODEL_OPUS, subagent=$MODEL_SUBAGENT
- Skills to use: /wayfinder, /grilling, /domain-modeling

## Decisions so far
(none yet)

## Not yet specified
The project's core purpose and scope are fog — they will be clarified during the HITL grilling session.

## Out of scope
(none yet)

Output ONLY the raw markdown. No code fences, no extra commentary."

        if claude -p "$prompt_map" > "$WAYFINDER_DIR/map.md" 2>/dev/null; then
            echo "Generated wayfinder map at $WAYFINDER_DIR/map.md"
        else
            echo "WARNING: claude -p failed for map generation. Using fallback."
            cat > "$WAYFINDER_DIR/map.md" <<EOF
# Wayfinder Map

## Destination

Define the precise purpose of this project by collaborating with the human. The README.md is currently a skeleton.

## Notes

- Hardware tier: $HARDWARE_TIER
- Models: haiku=$MODEL_HAIKU, sonnet=$MODEL_SONNET, opus=$MODEL_OPUS, subagent=$MODEL_SUBAGENT
- Skills: /wayfinder, /grilling, /domain-modeling

## Decisions so far

(none yet)

## Not yet specified

The project's core purpose and scope are fog.

## Out of scope

(none yet)
EOF
        fi
    else
        echo "WARNING: claude CLI not found. Using fallback map."
        cat > "$WAYFINDER_DIR/map.md" <<EOF
# Wayfinder Map

## Destination

Define the precise purpose of this project by collaborating with the human. The README.md is currently a skeleton.

## Notes

- Hardware tier: $HARDWARE_TIER
- Models: haiku=$MODEL_HAIKU, sonnet=$MODEL_SONNET, opus=$MODEL_OPUS, subagent=$MODEL_SUBAGENT

## Decisions so far

(none yet)

## Not yet specified

The project's core purpose and scope are fog.

## Out of scope

(none yet)
EOF
    fi

    # Use claude -p to generate initial tickets
    echo "Using claude -p to generate initial tickets ..."
    local ticket_prompt
    ticket_prompt="Based on the README skeleton at $readme_dest and the wayfinder map, generate exactly 3 markdown ticket files.

Ticket 01 (HITL grilling): Ask the human to define the precise destination. What is this project for? Who is it for? What does success look like?

Ticket 02 (HITL grilling): Breadth-first frontier mapping. What are the open questions and first steps? What decisions must be made before implementation can begin?

Ticket 03 (AFK research): Read the codebase (if any files exist beyond README), identify the tech stack, and summarize current state and constraints.

Output each ticket as raw markdown, separated by '---TICKET_SEPARATOR---'. No code fences."

    local tickets_raw=""
    if command -v claude >/dev/null 2>&1; then
        tickets_raw="$(claude -p "$ticket_prompt" 2>/dev/null || true)"
    fi

    if [ -n "$tickets_raw" ] && echo "$tickets_raw" | grep -q "TICKET_SEPARATOR"; then
        echo "$tickets_raw" | awk '/TICKET_SEPARATOR/{n++;next} {print > "'$WAYFINDER_DIR'/tickets/0" n "-ticket.md"}'
        # Rename to expected names
        mv "$WAYFINDER_DIR/tickets/01-ticket.md" "$WAYFINDER_DIR/tickets/01-destination.md" 2>/dev/null || true
        mv "$WAYFINDER_DIR/tickets/02-ticket.md" "$WAYFINDER_DIR/tickets/02-map-frontier.md" 2>/dev/null || true
        mv "$WAYFINDER_DIR/tickets/03-ticket.md" "$WAYFINDER_DIR/tickets/03-research-context.md" 2>/dev/null || true
        echo "Generated tickets via claude -p"
    else
        # Fallback: write deterministic tickets
        cat > "$WAYFINDER_DIR/tickets/01-destination.md" <<EOF
# Ticket 01: Define destination via grilling

**Type:** wayfinder:grilling (HITL)
**Blocked by:** None
**Status:** open

## Question

What is the precise destination for this effort? Read the README seed and grill the human until the destination is sharp enough to create tickets. What problem does this solve? Who is it for? What does "done" look like?

## Answer

<!-- Filled in after grilling session -->
EOF
        cat > "$WAYFINDER_DIR/tickets/02-map-frontier.md" <<EOF
# Ticket 02: Map the frontier

**Type:** wayfinder:grilling (HITL)
**Blocked by:** 01-destination.md
**Status:** open

## Question

Breadth-first across the decision space: what are the open questions and first steps? Create tickets for anything sharp enough to specify now. Leave the rest in "Not yet specified".
EOF
        cat > "$WAYFINDER_DIR/tickets/03-research-context.md" <<EOF
# Ticket 03: Research project context

**Type:** wayfinder:research (AFK)
**Blocked by:** 02-map-frontier.md
**Status:** open

## Question

Read the codebase, docs, and any existing ADRs. Summarize the current state and surface constraints that affect the destination.
EOF
        echo "Generated fallback tickets"
    fi

    # Copy sandcastle scripts to workspace
    mkdir -p "$WORKSPACE_DIR/.devcontainer/sandcastle"
    cp "$SCRIPT_DIR/sandcastle/runner.mjs" "$WORKSPACE_DIR/.devcontainer/sandcastle/runner.mjs"
    cp "$SCRIPT_DIR/sandcastle/validate-branch.sh" "$WORKSPACE_DIR/.devcontainer/sandcastle/validate-branch.sh"
    cp "$SCRIPT_DIR/sandcastle/ralph-loop.sh" "$WORKSPACE_DIR/.devcontainer/sandcastle/ralph-loop.sh"
    chmod +x "$WORKSPACE_DIR/.devcontainer/sandcastle/"*.sh

    # Set up ralph state directory
    mkdir -p "$RALPH_DIR/state" "$RALPH_DIR/logs" "$RALPH_DIR/notes"

    # Install shell hook that forces HITL on every new shell
    local hitl_hook="$WORKSPACE_DIR/.devcontainer/hitl-hook.sh"
    cat > "$hitl_hook" <<'HOOK_EOF'
#!/bin/bash
# HITL reminder hook — sourced by .bashrc and .zshrc
HITL_FILE="$HOME/.claude/bootstrap-state/wayfinder/handoff.md"
if [ ! -f "$HITL_FILE" ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  HITL REQUIRED — Human-In-The-Loop                           ║"
    echo "║                                                                ║"
    echo "║  The wayfinder map needs a destination. Run:                 ║"
    echo "║                                                                ║"
    echo "║      claude                                                    ║"
    echo "║      /grilling                                                 ║"
    echo "║                                                                ║"
    echo "║  Grill until the project's purpose is sharp.                   ║"
    echo "║  Then run: echo '# Handoff' > $HITL_FILE                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
fi
HOOK_EOF
    chmod +x "$hitl_hook"

    for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
        if [ -f "$rcfile" ]; then
            if ! grep -q "hitl-hook.sh" "$rcfile" 2>/dev/null; then
                echo "source $hitl_hook" >> "$rcfile"
            fi
        fi
    done

    echo ""
    echo "============================================"
    echo "  INIT complete."
    echo "============================================"
}

# ============================================================================
# Phase: hitl — BLOCKING until handoff.md is written
# ============================================================================

phase_hitl() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Phase: HITL — Human-In-The-Loop                             ║"
    echo "║                                                                ║"
    echo "║  The wayfinder map has been seeded from README.md.             ║"
    echo "║  The README is a skeleton — you must define the purpose.       ║"
    echo "║                                                                ║"
    echo "║  REQUIRED ACTIONS:                                             ║"
    echo "║    1. Run:  claude                                             ║"
    echo "║    2. Use:  /grilling                                          ║"
    echo "║       Grill on the destination until sharp.                    ║"
    echo "║    3. Use:  /wayfinder                                         ║"
    echo "║       Chart the map and create frontier tickets.               ║"
    echo "║                                                                ║"
    echo "║  When the grilling session ends, write a handoff:              ║"
    echo "║    echo '# Handoff' > $WAYFINDER_DIR/handoff.md              ║"
    echo "║                                                                ║"
    echo "║  The container will then auto-transition to AFK mode.           ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    local waited=0
    while [ ! -f "$WAYFINDER_DIR/handoff.md" ]; do
        sleep 5
        waited=$((waited + 5))
        if [ "$((waited % 30))" -eq 0 ]; then
            echo ""
            echo "⏳  Still waiting for HITL handoff... ($waited seconds)"
            echo "    Run: claude"
            echo "    Then: /grilling"
            echo "    Write handoff when done: echo '# Handoff' > $WAYFINDER_DIR/handoff.md"
            echo ""
        fi
    done

    echo ""
    echo "Handoff detected. Transitioning to AFK mode..."
    echo ""
}

# ============================================================================
# Phase: afk — CONTINUOUS daemon loop
# ============================================================================

phase_afk() {
    echo "============================================"
    echo "  Phase: AFK — Processing AFK tickets"
    echo "============================================"
    echo ""

    if [ "$DOCKER_AVAILABLE" != "true" ]; then
        echo "ERROR: Docker is required for AFK sandcastle isolation."
        echo "Install Docker or run tickets manually."
        return 1
    fi

    set_ollama_env

    local afk_tickets=()
    if [ -d "$WAYFINDER_DIR/tickets" ]; then
        for ticket in "$WAYFINDER_DIR/tickets"/*.md; do
            [ -f "$ticket" ] || continue
            if grep -qE 'Type:.*wayfinder:(research|task)' "$ticket" 2>/dev/null; then
                local ticket_id
                ticket_id="$(basename "$ticket")"
                local status
                status="$(grep -E '^\*\*Status:\*\*' "$ticket" | sed 's/.*: *//' || echo "open")"
                if [ "$status" = "open" ]; then
                    afk_tickets+=("$ticket_id")
                fi
            fi
        done
    fi

    if [ ${#afk_tickets[@]} -eq 0 ]; then
        echo "No open AFK tickets found."
        return 0
    fi

    echo "Found ${#afk_tickets[@]} AFK ticket(s):"
    for t in "${afk_tickets[@]}"; do
        echo "  - $t"
    done
    echo ""

    local branch="ralph/afk-$(date +%s)"
    git checkout -b "$branch" 2>/dev/null || true

    for ticket_id in "${afk_tickets[@]}"; do
        local ticket_path="$WAYFINDER_DIR/tickets/$ticket_id"
        local task_desc
        task_desc="$(grep -A5 '## Question' "$ticket_path" | tail -n +2 | head -3 | tr '\n' ' ' | sed 's/  */ /g')"

        echo "---"
        echo "Ticket: $ticket_id"
        echo "Task:   $task_desc"
        echo ""

        mkdir -p "$RALPH_DIR/state"
        cat > "$RALPH_DIR/state/${ticket_id%.md}.json" <<EOF
{
  "ticket": "${ticket_id%.md}",
  "task": "$task_desc",
  "iteration": 1,
  "status": "open",
  "createdAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

        if run_sandcastle_container "${ticket_id%.md}" "$task_desc" 1 "$branch"; then
            echo "Sandcastle completed for $ticket_id"
            sed -i 's/^\*\*Status:\*\* open/**Status:** pending-review/' "$ticket_path"
        else
            echo "WARNING: Sandcastle failed for $ticket_id. Review logs in $RALPH_DIR/logs/"
            sed -i 's/^\*\*Status:\*\* open/**Status:** blocked/' "$ticket_path"
        fi
        echo ""
    done

    # After AFK batch, run verify
    phase_verify

    return 0
}

# ============================================================================
# Phase: afk daemon — never exits
# ============================================================================

phase_afk_daemon() {
    echo "============================================"
    echo "  AFK Daemon started"
    echo "  This loop never exits."
    echo "  Stop the container to halt."
    echo "============================================"
    echo ""

    local cycle=0
    while true; do
        cycle=$((cycle + 1))
        echo "=== AFK Cycle $cycle ==="

        if phase_afk; then
            local remaining=0
            if [ -d "$WAYFINDER_DIR/tickets" ]; then
                remaining="$(grep -lE '^\*\*Status:\*\* open' "$WAYFINDER_DIR/tickets"/*.md 2>/dev/null | wc -l)"
            fi

            if [ "$remaining" -eq 0 ]; then
                echo ""
                echo "No open tickets remaining. Checking for self-improvement opportunities..."
                # TODO: add self-improvement ticket creation here
                # (lint, docs, tests, dependencies, etc.)
                echo "None found. Sleeping before next cycle."
            fi
        fi

        echo ""
        echo "AFK daemon sleeping for 60 seconds..."
        echo ""
        sleep 60
    done
}

# ============================================================================
# Phase: verify (branch-type bound sandcastle scripts)
# ============================================================================

phase_verify() {
    if [ "$DOCKER_AVAILABLE" != "true" ]; then
        echo "WARNING: Docker not available. Skipping branch validation."
        return
    fi

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        echo "On $current_branch branch. No validation needed."
        return
    fi

    echo "Current branch: $current_branch"
    echo "Running validate-branch via sandcastle..."

    if bash "$WORKSPACE_DIR/.devcontainer/sandcastle/validate-branch.sh" "$current_branch" "$WORKSPACE_DIR"; then
        echo "Branch validation passed."
    else
        echo "WARNING: Branch validation found issues. Fix before merging."
    fi
}

# ============================================================================
# Phase: status
# ============================================================================

phase_status() {
    echo "============================================"
    echo "  Bootstrap Status"
    echo "============================================"
    echo ""
    echo "Hardware:"
    echo "  GPU:      ${GPU_NAME:-unknown}"
    echo "  VRAM:     ${VRAM_GB}GB"
    echo "  Tier:     $HARDWARE_TIER"
    echo "  Docker:   $DOCKER_AVAILABLE"
    echo "  Ollama:   $OLLAMA_STATUS"
    echo ""
    echo "Phase: $(detect_phase)"
    echo ""

    if [ -d "$WAYFINDER_DIR/tickets" ]; then
        echo "Tickets:"
        for ticket in "$WAYFINDER_DIR/tickets"/*.md; do
            [ -f "$ticket" ] || continue
            local name status type
            name="$(basename "$ticket")"
            status="$(grep -E '^\*\*Status:\*\*' "$ticket" | sed 's/.*: *//' || echo "?")"
            type="$(grep -E '^\*\*Type:\*\*' "$ticket" | sed 's/.*: *//' || echo "?")"
            printf "  %-30s  %-12s  %s\n" "$name" "$status" "$type"
        done
        echo ""
    fi

    if [ -d "$RALPH_DIR/state" ]; then
        echo "Ralph states:"
        for state in "$RALPH_DIR/state"/*.json; do
            [ -f "$state" ] || continue
            local ticket status iter
            ticket="$(jq -r '.ticket' "$state" 2>/dev/null || echo "?")"
            status="$(jq -r '.status' "$state" 2>/dev/null || echo "?")"
            iter="$(jq -r '.iteration' "$state" 2>/dev/null || echo "?")"
            printf "  %-30s  iter=%-3s  %s\n" "$ticket" "$iter" "$status"
        done
        echo ""
    fi
}

# ============================================================================
# Main entrypoint — long-running daemon
# ============================================================================

case "${1:-}" in
    init)
        phase_init
        ;;
    hitl)
        phase_hitl
        ;;
    afk)
        phase_afk_daemon
        ;;
    verify)
        phase_verify
        ;;
    status)
        phase_status
        ;;
    *)
        # Auto-detect phase and run the appropriate blocking/continuous phase
        while true; do
            PHASE="$(detect_phase)"
            case "$PHASE" in
                init)
                    phase_init
                    # After init, immediately check next phase (should be hitl)
                    ;;
                hitl)
                    phase_hitl
                    # After HITL completes, loop back to detect (should transition to afk)
                    ;;
                afk|verify)
                    # Once HITL is done, enter the never-ending AFK daemon
                    phase_afk_daemon
                    # This never returns under normal operation
                    ;;
            esac
        done
        ;;
esac
