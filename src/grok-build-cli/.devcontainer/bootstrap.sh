#!/bin/bash
set -euo pipefail

# Bootstrap — installs Grok Build CLI and configures the environment.
# Runs at container startup as the devcontainer user (vscode).

# --- Install Grok Build CLI if not present ---
if ! command -v grok >/dev/null 2>&1; then
    echo "Installing Grok Build CLI..."
    curl -fsSL https://x.ai/cli/install.sh | bash

    # Verify
    if command -v grok >/dev/null 2>&1; then
        echo "Grok Build installed: $(grok --version)"
    else
        echo "ERROR: Grok Build installation failed"
        exit 1
    fi
else
    echo "Grok Build already installed: $(grok --version)"
fi

# --- Verify GitHub CLI is available ---
if command -v gh >/dev/null 2>&1; then
    echo "GitHub CLI installed: $(gh --version | head -1)"
else
    echo "WARN: GitHub CLI not found"
fi

# --- Auth hint ---
echo ""
echo "Grok Build authentication:"
echo "  - Run: grok login"
echo "  - Or set GROK_DEPLOYMENT_KEY for non-interactive use"
echo "  - Requires SuperGrok or X Premium Plus (see https://x.ai/build)"
echo ""