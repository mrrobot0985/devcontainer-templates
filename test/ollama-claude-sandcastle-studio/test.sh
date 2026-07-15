#!/bin/bash
set -euo pipefail

# Test — verify the devcontainer was built with expected features.
# Runs inside the built container.

echo "Running ollama-claude-sandcastle-studio tests..."

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

# Check Docker CLI is installed (required for sandcastle isolation)
if ! command -v docker > /dev/null 2>&1; then
    echo "ERROR: docker CLI is not installed"
    exit 1
fi
docker_version=$(docker --version)
echo "OK — docker CLI is installed ($docker_version)"

# Check bootstrap script has no syntax errors
bootstrap="$PWD/.devcontainer/bootstrap.sh"
if [ ! -f "$bootstrap" ]; then
    echo "ERROR: bootstrap.sh is missing"
    exit 1
fi
if ! bash -n "$bootstrap"; then
    echo "ERROR: bootstrap.sh has syntax errors"
    exit 1
fi
echo "OK — bootstrap.sh has no syntax errors"

# Check sandcastle scripts are present
sandcastle_dir="$PWD/.devcontainer/sandcastle"
for script in runner.mjs validate-branch.sh ralph-loop.sh; do
    if [ ! -f "$sandcastle_dir/$script" ]; then
        echo "ERROR: sandcastle script is missing: $script"
        exit 1
    fi
done
echo "OK — sandcastle scripts are present"

# Check Claude CLI config directory is persisted
if [ ! -d "$HOME/.claude" ]; then
    echo "ERROR: .claude directory is missing"
    exit 1
fi
echo "OK — .claude directory persisted"

echo "All tests passed!"
