#!/usr/bin/env bash
set -euo pipefail

# Bootstrap — ensures consistent configuration for ephemeral/disposable sessions.
# Does NOT install software. Expects the community codex feature to install the CLI.

# --- Verify Codex CLI is available ---
if command -v codex >/dev/null 2>&1; then
    echo "Bootstrap OK — Codex CLI installed: $(codex --version 2>/dev/null || echo 'version unknown')"
else
    echo "Bootstrap WARN — codex CLI not found on PATH"
    echo "  Ensure ghcr.io/sliekens/devcontainer-features/codex is installed."
fi

# --- Verify GitHub CLI is available ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Ensure Codex config directory exists for the remote user ---
CODEX_DIR="${_REMOTE_USER_HOME:-$HOME}/.codex"
if [ -e "$CODEX_DIR" ]; then
    echo "Bootstrap OK — Codex config path exists at $CODEX_DIR"
else
    echo "Bootstrap WARN — Codex config path missing at $CODEX_DIR"
    echo "  The community codex feature should create it via host ~/.codex bind + onCreate."
fi

# --- Auth hint ---
echo ""
echo "Codex authentication:"
echo "  - Run: codex login"
echo "  - Or set OPENAI_API_KEY for non-interactive use"
echo "  - No secrets are stored in this template"
echo ""
