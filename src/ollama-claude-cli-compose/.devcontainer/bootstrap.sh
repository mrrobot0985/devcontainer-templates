#!/bin/bash
set -euo pipefail

# Bootstrap for compose-based devcontainer.
# Ollama shares the network namespace via network_mode: service:ollama,
# so it is reachable at localhost:11434.

OLLAMA_BASE_URL="http://localhost:11434"
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

# --- Wait for Ollama to be ready ---
echo "Waiting for Ollama to be ready at $OLLAMA_BASE_URL ..."
_attempts=0
_max_attempts=30
while [ "$_attempts" -lt "$_max_attempts" ]; do
    if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
        echo "Bootstrap OK — Ollama backend reachable at $OLLAMA_BASE_URL"
        break
    fi
    _attempts=$((_attempts + 1))
    if [ "$_attempts" -lt "$_max_attempts" ]; then
        sleep 2
    fi
done

if [ "$_attempts" -eq "$_max_attempts" ]; then
    echo "Bootstrap WARN — Ollama backend not reachable at $OLLAMA_BASE_URL after $_max_attempts attempts"
    echo "  The Ollama service may still be starting. Try pulling a model manually with:"
    echo "    curl -X POST $OLLAMA_BASE_URL/api/pull -d '{\"name\":\"llama3.2\"}'"
fi

# --- Verify GitHub CLI is available ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Ensure Claude CLI config directory exists for the remote user ---
CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    echo "Bootstrap OK — Claude CLI config directory exists at $CLAUDE_DIR"
else
    echo "Bootstrap WARN — Claude CLI config directory missing at $CLAUDE_DIR"
fi
