#!/bin/bash
set -euo pipefail

echo "Running hermes-agent tests..."

if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
echo "OK — node version: $(node --version)"

if ! command -v hermes > /dev/null 2>&1; then
    echo "ERROR: hermes CLI is not installed"
    exit 1
fi
echo "OK — hermes CLI is installed"

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

if [ ! -e "$HOME/.hermes" ]; then
    echo "ERROR: .hermes path is missing"
    exit 1
fi
echo "OK — .hermes path exists"

if command -v claude > /dev/null 2>&1; then
    echo "WARN — claude CLI is present (unexpected for a Hermes-only template)"
else
    echo "OK — no Claude CLI dependency"
fi

echo "All tests passed!"
