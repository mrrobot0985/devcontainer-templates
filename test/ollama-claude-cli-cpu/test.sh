#!/bin/bash
set -euo pipefail

# Test — verify the CPU-only devcontainer was built with expected features.
# Runs inside the built container.

echo "Running ollama-claude-cli-cpu tests..."

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
node_version=$(node --version)
echo "OK — node version: $node_version"

# Check Claude CLI is installed
if ! command -v claude > /dev/null 2>&1; then
    echo "ERROR: claude CLI is not installed"
    exit 1
fi
echo "OK — claude CLI is installed"

# Check GitHub CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
gh_version=$(gh --version | head -1)
echo "OK — gh CLI is installed ($gh_version)"

# Check Claude CLI settings exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    echo "ERROR: settings.json is missing"
    exit 1
fi
echo "OK — settings.json exists"

# Check Claude CLI config directory is persisted
if [ ! -d "$HOME/.claude" ]; then
    echo "ERROR: .claude directory is missing"
    exit 1
fi
echo "OK — .claude directory persisted"

# CPU-specific: ensure no GPU runtime arguments leaked into the container
if [ -f "/proc/1/cgroup" ] && grep -q "nvidia" /proc/1/cgroup 2>/dev/null; then
    echo "WARN — nvidia cgroup detected (may be host-related)"
else
    echo "OK — no nvidia cgroup in container"
fi

echo "All tests passed!"
