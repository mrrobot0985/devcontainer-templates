#!/usr/bin/env bash
set -euo pipefail

# Bootstrap — installs Pi coding agent when not already on PATH.
# Floor features (firewall, non-root, sandbox) are expected from the template features block.

REMOTE_USER="${_REMOTE_USER:-vscode}"
HOME_DIR="$(getent passwd "${REMOTE_USER}" 2>/dev/null | cut -d: -f6 || true)"
HOME_DIR="${HOME_DIR:-${_REMOTE_USER_HOME:-$HOME}}"

run_as_user() {
    if [ "$(id -u)" -eq 0 ] && id "${REMOTE_USER}" >/dev/null 2>&1; then
        su -s /bin/bash "${REMOTE_USER}" -c "$*"
    else
        bash -c "$*"
    fi
}

# --- Ensure Pi home exists ---
PI_DIR="${HOME_DIR}/.pi"
mkdir -p "${PI_DIR}"
if command -v chown >/dev/null 2>&1 && id "${REMOTE_USER}" >/dev/null 2>&1; then
    chown -R "${REMOTE_USER}:${REMOTE_USER}" "${PI_DIR}" 2>/dev/null || true
fi
echo "Bootstrap OK — Pi home at ${PI_DIR}"

# --- Install Pi via official npm package when missing ---
if command -v pi >/dev/null 2>&1; then
    echo "Bootstrap OK — pi already on PATH: $(command -v pi)"
else
    echo "Installing @earendil-works/pi-coding-agent..."
    if run_as_user "npm install -g --ignore-scripts @earendil-works/pi-coding-agent"; then
        if command -v pi >/dev/null 2>&1; then
            echo "Bootstrap OK — pi installed: $(command -v pi)"
        else
            echo "Bootstrap WARN — package installed but pi not on PATH yet"
        fi
    else
        echo "Bootstrap ERROR — failed to install @earendil-works/pi-coding-agent"
        exit 1
    fi
fi

# --- Verify GitHub CLI ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Auth hint ---
echo ""
echo "Pi coding agent authentication:"
echo "  - Run: pi /login  (or follow provider setup in pi docs)"
echo "  - Configure provider API keys as required by your Pi model routing"
echo "  - See https://pi.dev for current auth and provider docs"
echo ""
