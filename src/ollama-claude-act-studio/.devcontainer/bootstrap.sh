#!/bin/bash
set -euo pipefail

# Bootstrap — Lifecycle orchestrator for Matt Pocock's skills.
#
# Phase machine:
#   init  → Create wayfinder map from README.md, generate act workflows, print HITL instructions.
#   afk   → Read wayfinder map + handoff, run ralph-loop iterations via act for AFK tickets.
#   verify→ Run branch-type validation workflows via act.
#   status→ Show current phase and pending work.
#
# This script does NOT use LLM improvisation for workflow generation.
# All act workflows are deterministic templates shipped with the template.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(pwd)"
STATE_DIR="$HOME/.claude/bootstrap-state"
WAYFINDER_DIR="$STATE_DIR/wayfinder"
RALPH_DIR="$WORKSPACE_DIR/.ralph"

# --- Global hardware / model state (from prior hardware-aware rewrite) ---
GPU_NAME=""
VRAM_GB=0
CPU_CORES=""
MEM_GB=""
DOCKER_AVAILABLE="false"
ACT_AVAILABLE="false"
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
    local in_container="false"
    if [ -f /.dockerenv ] || grep -q "docker" /proc/1/cgroup 2>/dev/null; then
        in_container="true"
    fi

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

    # Primary: nvidia-smi
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

    # Fallback 1: driver present but nvidia-smi unavailable
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

    # Fallback 2: lspci + sysfs
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

    if command -v act >/dev/null 2>&1; then
        ACT_AVAILABLE="true"
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
    # If handoff exists but not all AFK tickets are resolved
    if [ -d "$RALPH_DIR/state" ]; then
        local pending
        pending="$(find "$RALPH_DIR/state" -maxdepth 1 -name '*.json' -exec sh -c 'jq -r ".status" < "$1" | grep -qE "open|blocked|pending-review"' _ {} \; -print 2>/dev/null | wc -l)"
        if [ "$pending" -gt 0 ]; then
            echo "afk"
            return
        fi
    fi
    echo "verify"
}

# ============================================================================
# Phase: init
# ============================================================================

phase_init() {
    echo "============================================"
    echo "  Phase: INIT — Setting up workspace"
    echo "============================================"
    echo ""

    # Hardware + models
    probe_hardware
    select_models "$VRAM_GB"
    set_ollama_env
    write_claude_settings

    echo "Hardware: $GPU_NAME | VRAM: ${VRAM_GB}GB | Tier: $HARDWARE_TIER"
    echo "Models: haiku=$MODEL_HAIKU sonnet=$MODEL_SONNET opus=$MODEL_OPUS subagent=$MODEL_SUBAGENT"
    echo ""

    pull_ollama_models
    echo ""

    # Create wayfinder map from README.md
    mkdir -p "$WAYFINDER_DIR"
    local readme_dest="$WAYFINDER_DIR/README.seed.md"
    if [ -f "$WORKSPACE_DIR/README.md" ]; then
        cp "$WORKSPACE_DIR/README.md" "$readme_dest"
        echo "Seeded wayfinder destination from README.md"
    else
        echo "No README.md found. Using placeholder destination."
        echo "# Destination" > "$readme_dest"
    fi

    # Derive destination from first paragraph of README
    local destination=""
    destination="$(grep -v '^#' "$readme_dest" | head -5 | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//' || true)"
    if [ -z "$destination" ]; then
        destination="Define the destination for this effort."
    fi

    cat > "$WAYFINDER_DIR/map.md" <<EOF
# Wayfinder Map

## Destination

$destination

## Notes

- Skills: /wayfinder, /grilling, /domain-modeling
- Hardware tier: $HARDWARE_TIER
- Models: haiku=$MODEL_HAIKU, sonnet=$MODEL_SONNET, opus=$MODEL_OPUS, subagent=$MODEL_SUBAGENT

## Decisions so far

<!-- Closed tickets get appended here -->

## Not yet specified

<!-- Fog of war — suspected questions that aren't sharp enough to ticket yet -->

## Out of scope

<!-- Consciously ruled out of this effort -->
EOF

    echo "Created wayfinder map at $WAYFINDER_DIR/map.md"
    echo ""

    # Create initial tickets (local markdown tracker)
    mkdir -p "$WAYFINDER_DIR/tickets"

    cat > "$WAYFINDER_DIR/tickets/01-destination.md" <<EOF
# Ticket 01: Define destination via grilling

**Type:** wayfinder:grilling (HITL)
**Blocked by:** None
**Status:** open

## Question

What is the precise destination for this effort? Read the README seed and grill the human until the destination is sharp enough to create tickets.

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

    echo "Created initial tickets in $WAYFINDER_DIR/tickets/"
    echo ""

    # Generate deterministic act workflows
    mkdir -p "$WORKSPACE_DIR/.github/workflows"
    cp "$SCRIPT_DIR/templates/validate-branch.yml" "$WORKSPACE_DIR/.github/workflows/validate-branch.yml"
    cp "$SCRIPT_DIR/templates/ralph-loop.yml" "$WORKSPACE_DIR/.github/workflows/ralph-loop.yml"
    echo "Generated deterministic act workflows:"
    echo "  - .github/workflows/validate-branch.yml"
    echo "  - .github/workflows/ralph-loop.yml"
    echo ""

    # Set up ralph state directory
    mkdir -p "$RALPH_DIR/state" "$RALPH_DIR/logs" "$RALPH_DIR/notes"
    echo "Set up ralph state directory: $RALPH_DIR"
    echo ""

    # Verify claude CLI
    if ! command -v claude >/dev/null 2>&1; then
        echo "WARNING: claude CLI not found. HITL phases require Claude Code."
    fi

    echo "============================================"
    echo "  INIT complete. Next: HITL phase"
    echo "============================================"
    echo ""
    echo "The wayfinder map has been seeded from README.md."
    echo ""
    echo "NEXT STEPS (Human-In-The-Loop):"
    echo "  1. Run: claude"
    echo "  2. Use: /grilling"
    echo "     Grill on the destination until sharp."
    echo "  3. Use: /wayfinder"
    echo "     Chart the map, create frontier tickets."
    echo "  4. When grilling ends, a handoff will be written to:"
    echo "     $WAYFINDER_DIR/handoff.md"
    echo ""
    echo "After HITL, run: bash .devcontainer/bootstrap.sh afk"
    echo ""
}

# ============================================================================
# Phase: afk (ralph loops via act)
# ============================================================================

phase_afk() {
    echo "============================================"
    echo "  Phase: AFK — Ralph loops via act"
    echo "============================================"
    echo ""

    if [ "$ACT_AVAILABLE" != "true" ]; then
        echo "ERROR: act (nektos) is required for AFK ralph loops."
        echo "Install act or run tickets manually."
        exit 1
    fi

    # Ensure Ollama env is set
    set_ollama_env

    # Find open AFK tickets
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
        echo "If HITL tickets remain, complete them first."
        echo "Otherwise, run: bash .devcontainer/bootstrap.sh verify"
        return
    fi

    echo "Found ${#afk_tickets[@]} AFK ticket(s):"
    for t in "${afk_tickets[@]}"; do
        echo "  - $t"
    done
    echo ""

    # Run each AFK ticket as a ralph-loop iteration via act
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

        # Initialize ralph state for this ticket
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

        # Run ralph-loop workflow via act
        if act -W "$WORKSPACE_DIR/.github/workflows/ralph-loop.yml" \
            --env TICKET_ID="${ticket_id%.md}" \
            --env BRANCH="$branch" \
            --env ITERATION=1 \
            --env OLLAMA_HOST="$OLLAMA_HOST" \
            --env CLAUDE_CONFIG_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"; then
            echo "Ralph loop completed for $ticket_id"
            # Mark ticket as pending-review
            sed -i 's/^\*\*Status:\*\* open/**Status:** pending-review/' "$ticket_path"
        else
            echo "WARNING: Ralph loop failed for $ticket_id. Review logs in $RALPH_DIR/logs/"
            sed -i 's/^\*\*Status:\*\* open/**Status:** blocked/' "$ticket_path"
        fi
        echo ""
    done

    echo "============================================"
    echo "  AFK phase complete"
    echo "============================================"
    echo ""
    echo "Review completed tickets in $WAYFINDER_DIR/tickets/"
    echo "Run 'bash .devcontainer/bootstrap.sh verify' to validate branch integrity."
    echo ""
}

# ============================================================================
# Phase: verify (branch-type bound act workflows)
# ============================================================================

phase_verify() {
    echo "============================================"
    echo "  Phase: VERIFY — Branch validation via act"
    echo "============================================"
    echo ""

    if [ "$ACT_AVAILABLE" != "true" ]; then
        echo "WARNING: act (nektos) not available. Skipping branch validation."
        return
    fi

    local current_branch
    current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")"
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
        echo "On $current_branch branch. No validation needed."
        return
    fi

    echo "Current branch: $current_branch"
    echo "Running validate-branch workflow via act..."
    echo ""

    if act -W "$WORKSPACE_DIR/.github/workflows/validate-branch.yml" \
        --env BRANCH="$current_branch" \
        --env OLLAMA_HOST="$OLLAMA_HOST"; then
        echo ""
        echo "Branch validation passed."
    else
        echo ""
        echo "WARNING: Branch validation found issues. Fix before merging."
    fi
    echo ""
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
    echo "  Act:      $ACT_AVAILABLE"
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
# Main entrypoint
# ============================================================================

case "${1:-}" in
    init)
        phase_init
        ;;
    afk)
        phase_afk
        ;;
    verify)
        phase_verify
        ;;
    status)
        phase_status
        ;;
    *)
        # Auto-detect phase and run
        PHASE="$(detect_phase)"
        case "$PHASE" in
            init)
                phase_init
                ;;
            hitl)
                echo "============================================"
                echo "  Phase: HITL — Human-In-The-Loop"
                echo "============================================"
                echo ""
                echo "The wayfinder map exists but no handoff has been written yet."
                echo ""
                echo "NEXT STEPS:"
                echo "  1. Run: claude"
                echo "  2. Use: /grilling"
                echo "     Grill on the destination until sharp."
                echo "  3. Use: /wayfinder"
                echo "     Chart the map, create frontier tickets."
                echo ""
                echo "When the grilling session ends, write a handoff:"
                echo "  echo '# Handoff' > $WAYFINDER_DIR/handoff.md"
                echo ""
                echo "Then run: bash .devcontainer/bootstrap.sh afk"
                echo ""
                ;;
            afk)
                phase_afk
                ;;
            verify)
                phase_verify
                ;;
        esac
        ;;
esac
