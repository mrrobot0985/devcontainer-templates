#!/bin/bash
set -euo pipefail

echo "Running gemini-cli tests..."

if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
echo "OK — node version: $(node --version)"

if ! command -v gemini > /dev/null 2>&1; then
    echo "ERROR: gemini CLI is not installed"
    exit 1
fi
echo "OK — gemini CLI is installed"

if ! command -v gh > /dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
echo "OK — gh CLI is installed ($(gh --version | head -1))"

if ! command -v non-root-enforcer > /dev/null 2>&1; then
    echo "ERROR: non-root-enforcer is not installed"
    exit 1
fi
echo "OK — non-root-enforcer installed"

if ! command -v ai-agent-sandbox-check > /dev/null 2>&1; then
    echo "ERROR: ai-agent-sandbox-check is not installed"
    exit 1
fi
echo "OK — ai-agent-sandbox installed"

if [ ! -x /usr/local/bin/container-firewall-init ]; then
    echo "ERROR: container-firewall-init is missing"
    exit 1
fi
echo "OK — container-firewall installed"

if [ ! -e "$HOME/.gemini" ]; then
    echo "ERROR: .gemini path is missing"
    exit 1
fi
echo "OK — .gemini path exists"

if command -v claude > /dev/null 2>&1; then
    echo "WARN — claude CLI is present (unexpected for a Gemini-only template)"
else
    echo "OK — no Claude CLI dependency"
fi

echo "All tests passed!"
