#!/bin/bash
set -euo pipefail

# Bootstrap — verify expected tooling is present after feature installation.

echo "Bootstrap starting..."

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "Bootstrap ERROR: node is not installed"
    exit 1
fi
node_version=$(node --version)
echo "Bootstrap OK — node version: $node_version"

# Check Claude Code CLI is installed
if ! command -v claude > /dev/null 2>&1; then
    echo "Bootstrap ERROR: claude CLI is not installed"
    exit 1
fi
echo "Bootstrap OK — claude CLI is installed"

# Check GitHub CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo "Bootstrap ERROR: gh is not installed"
    exit 1
fi
gh_version=$(gh --version | head -1)
echo "Bootstrap OK — gh CLI is installed ($gh_version)"

# Check Claude Code settings exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    echo "Bootstrap ERROR: settings.json is missing"
    exit 1
fi
echo "Bootstrap OK — settings.json exists"

# Check Claude Code config directory is persisted
if [ ! -d "$HOME/.claude" ]; then
    echo "Bootstrap ERROR: .claude directory is missing"
    exit 1
fi
echo "Bootstrap OK — .claude directory persisted"

echo "Bootstrap complete."
