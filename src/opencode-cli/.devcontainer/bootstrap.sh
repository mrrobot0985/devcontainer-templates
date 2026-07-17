#!/usr/bin/env bash
set -euo pipefail

# Bootstrap — verifies OpenCode install from the community feature and home paths.

# --- Verify OpenCode CLI is available ---
if command -v opencode >/dev/null 2>&1; then
    echo "Bootstrap OK — OpenCode CLI installed: $(opencode --version 2>/dev/null || echo 'version unknown')"
else
    echo "Bootstrap WARN — opencode CLI not found on PATH"
    echo "  Ensure ghcr.io/sliekens/devcontainer-features/opencode is installed."
fi

# --- Verify GitHub CLI ---
if command -v gh >/dev/null 2>&1; then
    echo "Bootstrap OK — GitHub CLI installed: $(gh --version | head -1)"
else
    echo "Bootstrap WARN — GitHub CLI not found"
fi

# --- Ensure OpenCode config/data paths exist ---
HOME_DIR="${_REMOTE_USER_HOME:-$HOME}"
for path in \
    "${HOME_DIR}/.local/share/opencode" \
    "${HOME_DIR}/.config/opencode"
do
    if [ -e "${path}" ]; then
        echo "Bootstrap OK — OpenCode path exists at ${path}"
    else
        echo "Bootstrap WARN — OpenCode path missing at ${path}"
        echo "  The community opencode feature should create these via host binds + onCreate."
    fi
done

# --- Auth hint ---
echo ""
echo "OpenCode authentication:"
echo "  - Configure provider keys per OpenCode docs"
echo "  - No secrets are stored in this template"
echo ""
