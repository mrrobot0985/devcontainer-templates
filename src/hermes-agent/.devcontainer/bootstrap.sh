#!/usr/bin/env bash
set -euo pipefail

# Bootstrap — verifies Hermes install from the community feature and prepares home.

REMOTE_USER="${_REMOTE_USER:-vscode}"
HOME_DIR="$(getent passwd "${REMOTE_USER}" 2>/dev/null | cut -d: -f6 || true)"
HOME_DIR="${HOME_DIR:-${_REMOTE_USER_HOME:-$HOME}}"

# --- Ensure Hermes home exists ---
HERMES_DIR="${HOME_DIR}/.hermes"
mkdir -p "${HERMES_DIR}"
if command -v chown >/dev/null 2>&1 && id "${REMOTE_USER}" >/dev/null 2>&1; then
    chown -R "${REMOTE_USER}:${REMOTE_USER}" "${HERMES_DIR}" 2>/dev/null || true
fi
echo "Bootstrap OK — Hermes home at ${HERMES_DIR}"

# --- Verify Hermes CLI ---
if command -v hermes >/dev/null 2>&1; then
    echo "Bootstrap OK — hermes CLI installed: $(command -v hermes)"
    hermes --version 2>/dev/null || hermes version 2>/dev/null || true
else
    echo "Bootstrap WARN — hermes CLI not found on PATH"
    echo "  Ensure ghcr.io/devcontainer-community/devcontainer-features/hermes-agent.nousresearch.com is installed."
fi

# --- Verify GitHub CLI ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Auth hint ---
echo ""
echo "Hermes authentication / providers:"
echo "  - Run: hermes model  (or follow Hermes provider setup)"
echo "  - Common providers: OpenRouter, Nous portal, and others documented upstream"
echo "  - Firewall whitelist includes openrouter + github + npm; add extraDomains for other APIs"
echo "  - See https://github.com/NousResearch/hermes-agent for current docs"
echo ""
