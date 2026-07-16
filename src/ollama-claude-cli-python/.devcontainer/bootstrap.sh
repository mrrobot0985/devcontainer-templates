#!/bin/bash
set -euo pipefail

# Bootstrap for Python + Claude CLI devcontainer.
# Expects Ollama to be available externally.

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

# --- Verify backend reachability ---
if curl -fsSL "$OLLAMA_BASE_URL/api/tags" >/dev/null 2>&1; then
    echo "Bootstrap OK — Ollama backend reachable at $OLLAMA_BASE_URL"
else
    echo "Bootstrap WARN — Ollama backend not reachable at $OLLAMA_BASE_URL"
fi

# --- Verify Python environment ---
if [ -d "/workspaces/.venv" ] && [ -f "/workspaces/.venv/bin/python" ]; then
    echo "Bootstrap OK — Python virtual environment exists at /workspaces/.venv"
    if command -v uv >/dev/null 2>&1; then
        uv pip list --python /workspaces/.venv/bin/python 2>/dev/null | head -5 || true
    fi
else
    echo "Bootstrap WARN — Python virtual environment not found at /workspaces/.venv"
fi

# --- Verify tool installations ---
for tool in node gh python uv; do
    if command -v "$tool" >/dev/null 2>&1; then
        echo "Bootstrap OK — $tool is available"
    else
        echo "Bootstrap WARN — $tool not found"
    fi
done

# --- Ensure Claude CLI config directory exists ---
CLAUDE_DIR="${_REMOTE_USER_HOME:-$HOME}/.claude"
if [ -d "$CLAUDE_DIR" ]; then
    echo "Bootstrap OK — Claude CLI config directory exists at $CLAUDE_DIR"
else
    echo "Bootstrap WARN — Claude CLI config directory missing at $CLAUDE_DIR"
fi
