#!/bin/bash
set -euo pipefail

# Bootstrap — ensures consistent configuration for ephemeral/disposable sessions.
# Also triggers the local act workflow to explore the project and plan the next iteration.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

# --- Persist environment for interactive shells ---
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ]; then
        # Idempotent: remove old export, then append current value
        sed -i '/^export OLLAMA_HOST=/d' "$rcfile" 2>/dev/null || true
        echo "export OLLAMA_HOST="$OLLAMA_HOST"" >> "$rcfile"
    fi
done

# --- Verify backend reachability (diagnostic only) ---
if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
    echo "Bootstrap OK — Ollama backend reachable at $OLLAMA_BASE_URL"
else
    echo "Bootstrap WARN — Ollama backend not reachable at $OLLAMA_BASE_URL"
    echo "  Ensure Ollama is running on the host and accessible via host.docker.internal:11434"
fi

# --- Verify GitHub CLI is available ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Verify Docker-in-Docker is available ---
if docker version >/dev/null 2>&1; then
    echo "Bootstrap OK — Docker-in-Docker is available"
else
    echo "Bootstrap WARN — Docker-in-Docker is not yet available"
    echo "  The docker-in-docker feature may still be starting. Wait a few seconds and retry."
fi

# --- Verify act is available ---
if command -v act >/dev/null 2>&1; then
    echo "Bootstrap OK — act installed: $(act --version | head -1)"
else
    echo "Bootstrap WARN — act not found"
fi

# --- Ensure Claude CLI config directory exists for the remote user ---
CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    echo "Bootstrap OK — Claude CLI config directory exists at $CLAUDE_DIR"
else
    echo "Bootstrap WARN — Claude CLI config directory missing at $CLAUDE_DIR"
fi

# --- Run the act-as-claude workflow ---
# This uses nektos/act to execute .github/workflows/act-as-claude.yaml locally.
# The workflow runs claude -p commands to explore README.md and plan the next iteration.
WORKFLOW_FILE=".github/workflows/act-as-claude.yaml"
if [ -f "$WORKFLOW_FILE" ]; then
    echo ""
    echo "=== Running act-as-claude workflow ==="
    echo "This executes the local GitHub Actions workflow that drives Claude planning."
    echo ""

    # Attempt to run the workflow with act.
    # --bind binds the workflow to the current working directory so claude binary
    # and project files are accessible. If --bind is not supported, fall back to
    # a standard run (the workflow itself may need to install claude in that case).
    if act --help | grep -q -- '--bind'; then
        act -W "$WORKFLOW_FILE" --bind --env OLLAMA_HOST="$OLLAMA_HOST" --env CLAUDE_CONFIG_DIR="$CLAUDE_DIR" || true
    else
        act -W "$WORKFLOW_FILE" --env OLLAMA_HOST="$OLLAMA_HOST" --env CLAUDE_CONFIG_DIR="$CLAUDE_DIR" || true
    fi

    echo ""
    echo "=== act-as-claude workflow complete ==="
else
    echo "Bootstrap INFO — Workflow file not found: $WORKFLOW_FILE"
    echo "  Skipping act execution. Create the workflow to enable autonomous planning."
fi
