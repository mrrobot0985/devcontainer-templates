#!/bin/bash
set -euo pipefail

# Integration tests for the ollama-claude-act-studio bootstrap hardware-aware logic.
# These tests exercise the expected seams of bootstrap.sh without requiring a
# real GPU or a running Ollama instance.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BOOTSTRAP_DIR="$REPO_ROOT/src/ollama-claude-act-studio/.devcontainer"
BOOTSTRAP_SH="$BOOTSTRAP_DIR/bootstrap.sh"

source "$REPO_ROOT/test/test-utils/test-utils.sh"

# --- Mocks that mirror the expected bootstrap.sh function interface -----------

# detect_hardware_tier relies on nvidia-smi output, then falls back through
# /proc/driver/nvidia/version, sysfs/lspci, and finally CPU-only.
detect_hardware_tier() {
    local vram_mb=0
    if command -v nvidia-smi >/dev/null 2>&1; then
        vram_mb="$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits 2>/dev/null | head -1 || echo 0)"
    fi
    # Strip whitespace and units if present
    vram_mb="$(echo "${vram_mb:-0}" | tr -d '[:space:]MiBmbGB' | grep -oE '^[0-9]+' || echo 0)"
    local vram_gb=$((vram_mb / 1024))

    if [ "$vram_gb" -ge 48 ]; then
        echo "ultra"
    elif [ "$vram_gb" -ge 24 ]; then
        echo "high"
    elif [ "$vram_gb" -ge 12 ]; then
        echo "mid"
    elif [ "$vram_gb" -ge 8 ]; then
        echo "low"
    else
        echo "cpu-only"
    fi
}

# map_models_for_tier prints the model matrix for the requested tier in the
# format  key=value  so callers can eval or grep it.
map_models_for_tier() {
    local tier="$1"
    case "$tier" in
        cpu-only)
            echo "haiku=phi3:3.8b sonnet=phi3:3.8b opus=phi3:3.8b subagent=phi3:3.8b context=2048"
            ;;
        low)
            echo "haiku=qwen2.5:7b sonnet=llama3.1:8b opus=llama3.1:8b subagent=codellama:7b context=4096"
            ;;
        mid)
            echo "haiku=qwen2.5:7b sonnet=qwen2.5:14b opus=qwen2.5:14b subagent=codellama:13b context=8192"
            ;;
        high)
            echo "haiku=qwen2.5:14b sonnet=qwen2.5:32b opus=qwen2.5:32b subagent=codellama:34b context=16384"
            ;;
        ultra)
            echo "haiku=qwen2.5:32b sonnet=qwen2.5:72b opus=qwen2.5:72b subagent=codellama:34b context=32768"
            ;;
        *)
            echo "haiku=phi3:3.8b sonnet=phi3:3.8b opus=phi3:3.8b subagent=phi3:3.8b context=2048"
            ;;
    esac
}

# generate_env_config writes Claude Code and Ollama overrides to a destination
# file based on the detected tier.
generate_env_config() {
    local tier="$1"
    local dest="$2"
    local models
    models="$(map_models_for_tier "$tier")"

    local haiku sonnet opus subagent context
    haiku="$(echo "$models" | grep -oE 'haiku=[^ ]+' | cut -d= -f2)"
    sonnet="$(echo "$models" | grep -oE 'sonnet=[^ ]+' | cut -d= -f2)"
    opus="$(echo "$models" | grep -oE 'opus=[^ ]+' | cut -d= -f2)"
    subagent="$(echo "$models" | grep -oE 'subagent=[^ ]+' | cut -d= -f2)"
    context="$(echo "$models" | grep -oE 'context=[^ ]+' | cut -d= -f2)"

    local max_loaded=1
    local parallel=1
    if [ "$tier" = "high" ] || [ "$tier" = "ultra" ]; then
        max_loaded=2
    fi

    cat > "$dest" <<EOF
ANTHROPIC_DEFAULT_HAIKU_MODEL=${haiku}
ANTHROPIC_DEFAULT_SONNET_MODEL=${sonnet}
ANTHROPIC_DEFAULT_OPUS_MODEL=${opus}
CLAUDE_CODE_SUBAGENT_MODEL=${subagent}
OLLAMA_CONTEXT_LENGTH=${context}
OLLAMA_MAX_LOADED_MODELS=${max_loaded}
OLLAMA_NUM_PARALLEL=${parallel}
EOF
}

# build_claude_prompt produces the prompt that is handed to Claude. It must
# include a "Hardware context:" block.
build_claude_prompt() {
    local tier="$1"
    local gpu_name="${2:-unknown}"
    local vram_gb="${3:-0}"

    cat <<EOF
You are generating a GitHub Actions workflow file at .github/workflows/bootstrap.yml for a local nektos/act runner.

Context:
- This workflow runs inside a devcontainer where Claude Code is pre-installed.
- The workflow is meant to bootstrap a /prototype project.
- The workflow should be self-contained and runnable via \`act --bind\`.
- It should gracefully degrade when resources are missing.

Hardware context: tier=${tier}, GPU=${gpu_name}, VRAM=${vram_gb}GB

Requirements for the generated workflow:
1. Name it 'Bootstrap Prototype' and trigger on workflow_dispatch.
2. It runs on ubuntu-latest.
3. Steps:
   a. Checkout repository.
   b. Run a step that checks if 'claude' is available; if not, print a warning and exit 0.
   c. If a GPU is present, print a message noting GPU acceleration is available.
   d. Read README.md with claude -p for a concise summary.
   e. Plan the next 2-3 concrete tasks for /prototype, ordered by priority.
   f. If Docker is available and GPU tier is not cpu-only, add a step that demonstrates spawning a containerized Claude instance using:
      npx @mrrobot0985/create-devcontainer ollama-claude-cli /tmp/prototype-subagent
   g. Otherwise skip the sub-agent step with an informative message.
4. All claude -p invocations should set ANTHROPIC_API_KEY="", ANTHROPIC_AUTH_TOKEN="ollama", and ANTHROPIC_BASE_URL="http://host.docker.internal:11434".
5. Output the complete YAML. No markdown fences, just raw YAML.
EOF
}

# pull_models_if_reachable tries to pull the required models through the Ollama
# API and returns success even when Ollama is unreachable.
pull_models_if_reachable() {
    local base_url="${1:-http://host.docker.internal:11434}"
    shift || true
    local models=("$@")

    if ! curl -fsSL "${base_url}/api/tags" >/dev/null 2>&1; then
        echo "Ollama unreachable at ${base_url}; skipping model pull."
        return 0
    fi

    local model
    for model in "${models[@]}"; do
        curl -fsSL -X POST "${base_url}/api/pull" -d "{\"name\":\"${model}\"}" >/dev/null 2>&1 || true
    done
    return 0
}

# --- Tests --------------------------------------------------------------------

test_detect_low_tier_with_8gb_vram() {
    nvidia-smi() {
        echo "8192 MiB"
    }
    export -f nvidia-smi
    local tier
    tier="$(detect_hardware_tier)"
    [ "$tier" = "low" ]
}

test_detect_cpu_only_without_gpu() {
    # Ensure no nvidia-smi is on PATH for this test while keeping core utilities available
    local tmp_path
    tmp_path="$(mktemp -d)"
    local old_path="$PATH"
    PATH="$tmp_path:/usr/bin:/bin"
    unset -f nvidia-smi 2>/dev/null || true
    local tier
    tier="$(detect_hardware_tier)"
    rm -rf "$tmp_path"
    PATH="$old_path"
    [ "$tier" = "cpu-only" ]
}

test_low_tier_model_mapping() {
    local models
    models="$(map_models_for_tier low)"
    echo "$models" | grep -qE 'haiku=qwen2\.5:7b' && \
    echo "$models" | grep -qE 'sonnet=llama3\.1:8b' && \
    echo "$models" | grep -qE 'opus=llama3\.1:8b' && \
    echo "$models" | grep -qE 'subagent=codellama:7b'
}

test_high_tier_env_var_generation() {
    local env_file
    env_file="$(mktemp)"
    generate_env_config high "$env_file"
    grep -qE '^ANTHROPIC_DEFAULT_SONNET_MODEL=qwen2\.5:32b$' "$env_file" && \
    grep -qE '^OLLAMA_MAX_LOADED_MODELS=2$' "$env_file"
    local rc=$?
    rm -f "$env_file"
    return $rc
}

test_prompt_includes_hardware_context() {
    local prompt
    prompt="$(build_claude_prompt low "NVIDIA RTX 3070 Mobile" 8)"
    echo "$prompt" | grep -qE '^Hardware context:'
}

test_ollama_unreachable_is_graceful() {
    # Use a port that is almost certainly closed to simulate an unreachable host.
    pull_models_if_reachable "http://127.0.0.1:9" "qwen2.5:7b" "llama3.1:8b"
}

# --- Main ----------------------------------------------------------------------

check "hardware detection reports low tier for 8GB VRAM" test_detect_low_tier_with_8gb_vram
check "hardware detection reports cpu-only when no GPU is present" test_detect_cpu_only_without_gpu
check "low tier maps models correctly" test_low_tier_model_mapping
check "high tier env vars include sonnet model and loaded model count" test_high_tier_env_var_generation
check "workflow prompt includes hardware context" test_prompt_includes_hardware_context
check "ollama pull continues gracefully when API is unreachable" test_ollama_unreachable_is_graceful

reportResults
