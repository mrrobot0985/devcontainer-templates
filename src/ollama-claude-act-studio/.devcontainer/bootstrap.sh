#!/bin/bash
set -euo pipefail

# Bootstrap — hardware-aware environment detection and autonomous workflow generation.
# Instead of shipping a static workflow, this script probes the available hardware tier,
# then asks Claude to generate .act/workflows/bootstrap.yml tailored to the detected
# resources. The generated workflow can spawn containerized Claude instances via
# npx create-devcontainer when Docker-in-Docker is available.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

# --- Persist environment for interactive shells ---
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ]; then
        sed -i '/^export OLLAMA_HOST=/d' "$rcfile" 2>/dev/null || true
        echo "export OLLAMA_HOST=\"$OLLAMA_HOST\"" >> "$rcfile"
    fi
done

# --- Helper: probe hardware tier ---
probe_hardware() {
    local gpu_tier="none"
    local gpu_name=""
    local docker_available="false"
    local act_available="false"
    local cpu_cores=""
    local mem_gb=""
    local in_container="false"

    # Container detection
    if [ -f /.dockerenv ] || grep -q "docker" /proc/1/cgroup 2>/dev/null; then
        in_container="true"
    fi

    # CPU cores
    cpu_cores="$(nproc 2>/dev/null || echo "unknown")"

    # Memory (approximate GB)
    if command -v free >/dev/null 2>&1; then
        mem_kb="$(free | awk '/^Mem:/{print $2}')"
        mem_gb="$((mem_kb / 1024 / 1024))"
    else
        mem_gb="unknown"
    fi

    # GPU detection
    if command -v nvidia-smi >/dev/null 2>&1; then
        gpu_name="$(nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1 || echo "unknown")"
        if [ -n "$gpu_name" ] && [ "$gpu_name" != "unknown" ]; then
            gpu_tier="nvidia"
        fi
    elif [ -f /proc/driver/nvidia/version ]; then
        gpu_tier="nvidia"
        gpu_name="driver present (nvidia-smi unavailable)"
    fi

    # Docker detection
    if docker version >/dev/null 2>&1; then
        docker_available="true"
    fi

    # Act detection
    if command -v act >/dev/null 2>&1; then
        act_available="true"
    fi

    # Ollama reachability
    local ollama_status="unreachable"
    if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
        ollama_status="reachable"
    fi

    cat <<EOF
Hardware Profile
================
In container: $in_container
CPU cores:    $cpu_cores
Memory (GB):  $mem_gb
GPU tier:     $gpu_tier
GPU name:     $gpu_name
Docker:       $docker_available
Act (nektos): $act_available
Ollama:       $ollama_status
EOF
}

HW_PROFILE="$(probe_hardware)"
echo "$HW_PROFILE"
echo ""

# --- Verify Claude CLI is available ---
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI not found. This template requires Claude Code to be installed."
    exit 1
fi
echo "Bootstrap OK — Claude CLI available"

# --- Generate bootstrap workflow via Claude ---
WORKFLOW_DIR=".act/workflows"
WORKFLOW_FILE="$WORKFLOW_DIR/bootstrap.yml"

mkdir -p "$WORKFLOW_DIR"

echo "=== Generating bootstrap workflow via Claude ==="
echo "Detected resources will be passed to Claude so the workflow is hardware-aware."
echo ""

# Build the prompt for Claude
PROMPT=$(cat <<'PROMPT_EOF'
You are generating a GitHub Actions workflow file at .act/workflows/bootstrap.yml for a local nektos/act runner.

Context:
- This workflow runs inside a devcontainer where Claude Code is pre-installed.
- The workflow is meant to bootstrap a /prototype project.
- The workflow should be self-contained and runnable via `act --bind`.
- It should gracefully degrade when resources are missing.

Detected hardware profile:
PROMPT_EOF
)

PROMPT="$PROMPT
$HW_PROFILE

Requirements for the generated workflow:
1. Name it 'Bootstrap Prototype' and trigger on workflow_dispatch.
2. It runs on ubuntu-latest.
3. Steps:
   a. Checkout repository.
   b. Run a step that checks if 'claude' is available; if not, print a warning and exit 0.
   c. If a GPU is present (nvidia-smi works), print a message noting GPU acceleration is available.
   d. Read README.md with claude -p for a concise summary.
   e. Plan the next 2-3 concrete tasks for /prototype, ordered by priority.
   f. If Docker is available and GPU tier is 'nvidia', add a step that demonstrates spawning a containerized Claude instance using:
      npx @mrrobot0985/create-devcontainer ollama-claude-cli /tmp/prototype-subagent
      (This is optional/diagnostic — it shows the capability to instantiate sub-agents.)
   g. Otherwise skip the sub-agent step with an informative message.
4. All claude -p invocations should set ANTHROPIC_API_KEY="", ANTHROPIC_AUTH_TOKEN="ollama", and ANTHROPIC_BASE_URL="http://host.docker.internal:11434".
5. Output the complete YAML. No markdown fences, just raw YAML.
"

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

if [ "$(echo "$HW_PROFILE" | grep -c "Act (nektos): true")" -eq 1 ]; then
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
