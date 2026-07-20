#!/bin/bash
set -euo pipefail

# Bootstrap — ensures consistent configuration for ephemeral/disposable sessions.
# Does NOT install software. Expects our grok-build feature to install the CLI.

# --- Verify Grok Build CLI is available ---
if command -v grok >/dev/null 2>&1; then
    echo "Bootstrap OK — Grok Build CLI installed: $(grok --version 2>/dev/null || grok version 2>/dev/null || echo 'version unknown')"
else
    echo "Bootstrap WARN — grok CLI not found on PATH"
    echo "  Ensure ghcr.io/mrrobot0985/devcontainer-features/grok-build is installed."
fi

if command -v agent >/dev/null 2>&1; then
    echo "Bootstrap OK — Grok agent binary is available"
else
    echo "Bootstrap INFO — agent binary not found (optional; grok is the primary entry point)"
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

# --- Ensure Grok config directory exists for the remote user ---
GROK_DIR="${_REMOTE_USER_HOME:-$HOME}/.grok"
if [ -e "$GROK_DIR" ]; then
    echo "Bootstrap OK — Grok config path exists at $GROK_DIR"
else
    echo "Bootstrap WARN — Grok config path missing at $GROK_DIR"
    echo "  Add mount to devcontainer.json: source=\${localEnv:HOME}/.grok,target=/var/lib/grok-build,type=bind"
fi

# --- MCP server manager (optional studio tooling) ---
if command -v devcontainer-mcp-status >/dev/null 2>&1; then
    echo "Bootstrap OK — mcp-server-manager is available"
    devcontainer-mcp-status 2>/dev/null || true
else
    echo "Bootstrap INFO — mcp-server-manager status helper not found"
fi

# --- Auth hint ---
echo ""
echo "Grok Build authentication:"
echo "  - Run: grok login"
echo "  - Or set GROK_DEPLOYMENT_KEY for non-interactive use"
echo "  - Requires SuperGrok or X Premium Plus (see https://x.ai/news/grok-build-cli)"
echo ""