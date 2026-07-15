#!/bin/bash
set -euo pipefail

# Bootstrap — hardware-aware environment detection and autonomous workflow generation.
# Probes the available hardware tier, selects local Ollama models, configures
# Claude Code backend defaults, then asks Claude to generate .github/workflows/bootstrap.yml
# tailored to the detected resources. The generated workflow can spawn containerized
# Claude instances via npx create-devcontainer when Docker-in-Docker is available.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

# --- Global hardware / model state ---
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

# --- Persist environment for interactive shells ---
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

# Persist OLLAMA_HOST immediately so interactive shells can reach the backend.
persist_env_var "OLLAMA_HOST" "$OLLAMA_HOST"

# --- Helper: probe hardware tier ---
probe_hardware() {
    local in_container="false"

    # Container detection
    if [ -f /.dockerenv ] || grep -q "docker" /proc/1/cgroup 2>/dev/null; then
        in_container="true"
    fi

    # CPU cores
    CPU_CORES="$(nproc 2>/dev/null || echo "unknown")"

    # Memory (approximate GB)
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

    # GPU / VRAM detection (multi-method, best-effort)
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
        # Best-effort VRAM read from /proc/driver/nvidia/gpus/*/information
        local info_file=""
        info_file="$(find /proc/driver/nvidia/gpus -maxdepth 2 -type f -name information 2>/dev/null | head -1 || true)"
        if [ -n "$info_file" ] && [ -f "$info_file" ]; then
            local vram_line=""
            vram_line="$(grep -i 'Video Memory' "$info_file" 2>/dev/null | head -1 || true)"
            if [ -n "$vram_line" ]; then
                local vram_number=""
                vram_number="$(echo "$vram_line" | grep -oE '[0-9]+' | head -1 || true)"
                # The information file reports memory in kB on some driver versions.
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
            # Try to read VRAM from the DRM sysfs node associated with this PCI slot
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

    # Final fallback: CPU-only
    if [ "$VRAM_GB" -eq 0 ] && [ -z "$GPU_NAME" ]; then
        GPU_NAME="CPU-only"
    fi

    # Docker detection
    if docker version >/dev/null 2>&1; then
        DOCKER_AVAILABLE="true"
    fi

    # Act detection
    if command -v act >/dev/null 2>&1; then
        ACT_AVAILABLE="true"
    fi

    # Ollama reachability
    if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
        OLLAMA_STATUS="reachable"
    fi

    # Determine hardware tier from VRAM
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

    cat <<EOF
Hardware Profile
================
In container: $in_container
CPU cores:    $CPU_CORES
Memory (GB):  $MEM_GB
GPU name:     $GPU_NAME
VRAM (GB):    $VRAM_GB
Hardware tier:$HARDWARE_TIER
Docker:       $DOCKER_AVAILABLE
Act (nektos): $ACT_AVAILABLE
Ollama:       $OLLAMA_STATUS
EOF
}

# --- Select local Ollama models based on detected VRAM ---
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

# --- Configure Ollama runtime environment based on tier ---
set_ollama_env() {
    local vram_gb="$1"

    case "$HARDWARE_TIER" in
        cpu-only)
            OLLAMA_MAX_LOADED_MODELS=1
            OLLAMA_NUM_PARALLEL=1
            ;;
        low)
            OLLAMA_MAX_LOADED_MODELS=1
            OLLAMA_NUM_PARALLEL=1
            ;;
        mid)
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

# --- Write Claude Code model overrides to shell rc files and current shell ---
write_claude_settings() {
    persist_env_var "ANTHROPIC_DEFAULT_HAIKU_MODEL" "$MODEL_HAIKU"
    persist_env_var "ANTHROPIC_DEFAULT_SONNET_MODEL" "$MODEL_SONNET"
    persist_env_var "ANTHROPIC_DEFAULT_OPUS_MODEL" "$MODEL_OPUS"
    persist_env_var "CLAUDE_CODE_SUBAGENT_MODEL" "$MODEL_SUBAGENT"
}

# --- Pull mapped models from the Ollama host if reachable ---
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

# --- Main bootstrap flow ---
HW_PROFILE="$(probe_hardware)"
echo "$HW_PROFILE"
echo ""

select_models "$VRAM_GB"
set_ollama_env "$VRAM_GB"
write_claude_settings

echo "Selected models for tier '$HARDWARE_TIER' (${VRAM_GB}GB VRAM):"
echo "  haiku:    $MODEL_HAIKU"
echo "  sonnet:   $MODEL_SONNET"
echo "  opus:     $MODEL_OPUS"
echo "  subagent: $MODEL_SUBAGENT"
echo "  context:  $CONTEXT_SIZE"
echo ""

pull_ollama_models
echo ""

# --- Verify Claude CLI is available ---
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI not found. This template requires Claude Code to be installed."
    exit 1
fi
echo "Bootstrap OK — Claude CLI available"
echo ""

# --- Generate bootstrap workflow via Claude ---
WORKFLOW_DIR=".github/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/bootstrap.yml"

mkdir -p "$WORKFLOW_DIR"

echo "=== Generating bootstrap workflow via Claude ==="
echo "Detected resources will be passed to Claude so the workflow is hardware-aware."
echo ""

# Build the prompt for Claude
PROMPT=$(cat <<PROMPT_EOF
You are generating a GitHub Actions workflow file at .github/workflows/bootstrap.yml for a local nektos/act runner.

Context:
- This workflow runs inside a devcontainer where Claude Code is pre-installed.
- The workflow is meant to bootstrap a /prototype project.
- The workflow should be self-contained and runnable via \`act --bind\`.
- It should gracefully degrade when resources are missing.

Detected hardware profile:
$HW_PROFILE

Hardware context: $GPU_NAME with ${VRAM_GB}GB VRAM. Tier: $HARDWARE_TIER, context size: $CONTEXT_SIZE tokens. Constraints: OLLAMA_MAX_LOADED_MODELS=$OLLAMA_MAX_LOADED_MODELS, OLLAMA_NUM_PARALLEL=$OLLAMA_NUM_PARALLEL. Selected local models: haiku=$MODEL_HAIKU, sonnet=$MODEL_SONNET, opus=$MODEL_OPUS, subagent=$MODEL_SUBAGENT.

Requirements for the generated workflow:
1. Name it 'Bootstrap Prototype' and trigger on workflow_dispatch.
2. It runs on ubuntu-latest.
3. Steps:
   a. Checkout repository.
   b. Run a step that checks if 'claude' is available; if not, print a warning and exit 0.
   c. If VRAM is greater than 0 and nvidia-smi works, print a message noting GPU acceleration is available.
   d. Read README.md with claude -p for a concise summary.
   e. Plan the next 2-3 concrete tasks for /prototype, ordered by priority.
   f. If Docker is available and VRAM is greater than 0, add a step that demonstrates spawning a containerized Claude instance using:
      npx @mrrobot0985/create-devcontainer ollama-claude-cli /tmp/prototype-subagent
      (This is optional/diagnostic — it shows the capability to instantiate sub-agents.)
   g. Otherwise skip the sub-agent step with an informative message.
4. All claude -p invocations should set ANTHROPIC_API_KEY="", ANTHROPIC_AUTH_TOKEN="ollama", and ANTHROPIC_BASE_URL="http://host.docker.internal:11434".
5. Output the complete YAML. No markdown fences, just raw YAML.
PROMPT_EOF
)

# Run claude -p and redirect to the workflow file
if claude -p "$PROMPT" > "$WORKFLOW_FILE"; then
    echo "Workflow generated at $WORKFLOW_FILE"
else
    echo "WARNING: Claude failed to generate workflow. Check claude connectivity."
    exit 0
fi

# Basic YAML sanity check
if ! grep -q "^name:" "$WORKFLOW_FILE"; then
    echo "WARNING: Generated file does not look like a valid workflow. Review $WORKFLOW_FILE"
    exit 0
fi

echo ""
echo "=== Running generated bootstrap workflow ==="

if [ "$ACT_AVAILABLE" = "true" ]; then
    if act --help | grep -q -- '--bind'; then
        act -W "$WORKFLOW_FILE" --bind \
            --env OLLAMA_HOST="$OLLAMA_HOST" \
            --env CLAUDE_CONFIG_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude" || true
    else
        act -W "$WORKFLOW_FILE" \
            --env OLLAMA_HOST="$OLLAMA_HOST" \
            --env CLAUDE_CONFIG_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude" || true
    fi
    echo ""
    echo "=== Bootstrap workflow complete ==="
else
    echo "act (nektos) not available — skipping workflow execution."
    echo "Install act to enable local GitHub Actions execution."
fi
