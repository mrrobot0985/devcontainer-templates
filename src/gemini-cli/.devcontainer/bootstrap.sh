#!/usr/bin/env bash
set -euo pipefail

# Bootstrap — installs Google Gemini CLI when not already on PATH.
# Uses the official npm package (@google/gemini-cli). Avoid broken PyPI names.

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

# --- Ensure Gemini home exists ---
GEMINI_DIR="${HOME_DIR}/.gemini"
mkdir -p "${GEMINI_DIR}"
if command -v chown >/dev/null 2>&1 && id "${REMOTE_USER}" >/dev/null 2>&1; then
    chown -R "${REMOTE_USER}:${REMOTE_USER}" "${GEMINI_DIR}" 2>/dev/null || true
fi
echo "Bootstrap OK — Gemini home at ${GEMINI_DIR}"

# --- Install Gemini CLI via official npm package when missing ---
if command -v gemini >/dev/null 2>&1; then
    echo "Bootstrap OK — gemini already on PATH: $(command -v gemini)"
else
    echo "Installing @google/gemini-cli..."
    if run_as_user "npm install -g --ignore-scripts @google/gemini-cli"; then
        if command -v gemini >/dev/null 2>&1; then
            echo "Bootstrap OK — gemini installed: $(command -v gemini)"
        else
            echo "Bootstrap WARN — package installed but gemini not on PATH yet"
        fi
    else
        echo "Bootstrap ERROR — failed to install @google/gemini-cli"
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
echo "Gemini CLI authentication:"
echo "  - Set GEMINI_API_KEY, or use Google login flow from the CLI"
echo "  - gcloud auth is optional depending on your setup"
echo "  - No secrets are stored in this template"
echo ""
