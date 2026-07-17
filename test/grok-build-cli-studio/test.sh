#!/bin/bash
set -euo pipefail

# Test — verify the devcontainer was built with expected features.
# Runs inside the built container.

echo "Running grok-build-cli-studio tests..."

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
node_version=$(node --version)
echo "OK — node version: $node_version"

# Check Grok Build CLI is installed
if ! command -v grok > /dev/null 2>&1; then
    echo "ERROR: grok CLI is not installed"
    exit 1
fi
echo "OK — grok CLI is installed"

# Check GitHub CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
gh_version=$(gh --version | head -1)
echo "OK — gh CLI is installed ($gh_version)"

# Check non-root-enforcer is installed
if ! command -v non-root-enforcer > /dev/null 2>&1; then
    echo "ERROR: non-root-enforcer is not installed"
    exit 1
fi
echo "OK — non-root-enforcer installed"

# Check ai-agent-sandbox is installed
if ! command -v ai-agent-sandbox-check > /dev/null 2>&1; then
    echo "ERROR: ai-agent-sandbox-check is not installed"
    exit 1
fi
echo "OK — ai-agent-sandbox installed"

# Check host-isolation is installed
if ! command -v host-isolation-check > /dev/null 2>&1; then
    echo "ERROR: host-isolation-check is not installed"
    exit 1
fi
echo "OK — host-isolation installed"

# Check container-firewall init script exists
if [ ! -x /usr/local/bin/container-firewall-init ]; then
    echo "ERROR: container-firewall-init is missing"
    exit 1
fi
echo "OK — container-firewall installed"

# Check mcp-server-manager artifacts
if [ ! -f /usr/local/share/mcp-server-manager/mcp.json.example ]; then
    echo "ERROR: mcp-server-manager example config is missing"
    exit 1
fi
echo "OK — mcp-server-manager installed"

# Check Docker-in-Docker is available (may need a short wait after start)
if docker version > /dev/null 2>&1; then
    echo "OK — Docker-in-Docker is available"
else
    echo "WARN — Docker-in-Docker not yet available (feature may still be starting)"
fi

# Check Grok config path exists (symlink or directory from community feature)
if [ ! -e "$HOME/.grok" ]; then
    echo "ERROR: .grok path is missing"
    exit 1
fi
echo "OK — .grok path exists"

# Ensure no Claude-only binaries are required
if command -v claude > /dev/null 2>&1; then
    echo "WARN — claude CLI is present (unexpected for a Grok-only template)"
else
    echo "OK — no Claude CLI dependency"
fi

echo "All tests passed!"
