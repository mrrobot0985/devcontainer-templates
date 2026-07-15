#!/bin/bash
set -euo pipefail

# Bootstrap — ensures consistent configuration for ephemeral/disposable sessions.
# Does NOT install software. Expects Ollama to be available externally.

OLLAMA_BASE_URL="http://host.docker.internal:11434"
OLLAMA_HOST="${OLLAMA_BASE_URL#http://}"
OLLAMA_HOST="${OLLAMA_HOST#https://}"
export OLLAMA_HOST

# --- Persist environment for interactive shells ---
for rcfile in "$HOME/.bashrc" "$HOME/.zshrc"; do
    if [ -f "$rcfile" ]; then
        # Idempotent: remove old export, then append current value
        sed -i '/^export OLLAMA_HOST=/d' "$rcfile" 2>/dev/null || true
        echo "export OLLAMA_HOST=\"$OLLAMA_HOST\"" >> "$rcfile"
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

# --- Ensure Claude CLI config directory exists for the remote user ---
CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    echo "Bootstrap OK — Claude CLI config directory exists at $CLAUDE_DIR"
else
    echo "Bootstrap WARN — Claude CLI config directory missing at $CLAUDE_DIR"
fi
