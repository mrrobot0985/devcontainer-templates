#!/bin/bash
set -euo pipefail

# Test — verify the devcontainer was built with expected features.
# Runs inside the built container.

cd "$(dirname "$0")/.." || exit 1

# Source test utilities if available
if [ -f "test-utils/test-utils.sh" ]; then
    source "test-utils/test-utils.sh"
else
    echo "INFO: test-utils not found, running basic checks"
fi

echo "Running claude-code-dind tests..."

# Check Node.js is installed
if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
node_version=$(node --version)
echo "OK — node version: $node_version"

# Check Claude Code CLI is installed
if ! command -v claude >/dev/null 2>&1; then
    echo "ERROR: claude CLI is not installed"
    exit 1
fi
echo "OK — claude CLI is installed"

# Check Docker-in-Docker is available
if ! command -v docker >/dev/null 2>&1; then
    echo "ERROR: docker is not installed"
    exit 1
fi
if ! docker version >/dev/null 2>&1; then
    echo "ERROR: docker daemon is not reachable"
    exit 1
fi
echo "OK — docker-in-docker is available"

# Check hooks are installed
if [ ! -d "$HOME/.claude/hooks" ]; then
    echo "ERROR: hooks directory is missing at $HOME/.claude/hooks"
    exit 1
fi
hook_count=$(find "$HOME/.claude/hooks" -type f -name "*.sh" | wc -l)
if [ "$hook_count" -eq 0 ]; then
    echo "ERROR: no hook scripts found in $HOME/.claude/hooks"
    exit 1
fi
echo "OK — hooks installed ($hook_count scripts)"

# Check GitHub CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
gh_version=$(gh --version | head -1)
echo "OK — gh CLI is installed ($gh_version)"

# Check privacy settings
if [ ! -f "$HOME/.claude/settings.local.json" ]; then
    echo "ERROR: settings.local.json is missing"
    exit 1
fi
if ! jq -e '.["telemetry"] == false' "$HOME/.claude/settings.local.json" >/dev/null 2>&1; then
    echo "ERROR: telemetry is not disabled in settings"
    exit 1
fi
echo "OK — privacy settings applied"

echo "All tests passed!"
