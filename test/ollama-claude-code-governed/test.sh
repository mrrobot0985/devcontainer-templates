#!/bin/bash
set -euo pipefail

# Test — verify the devcontainer was built with expected features.
# Runs inside the built container.

echo "Running ollama-claude-code-governed tests..."

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

# Check GitHub CLI is installed
if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
gh_version=$(gh --version | head -1)
echo "OK — gh CLI is installed ($gh_version)"

# Check Claude Code settings exist
if [ ! -f "$HOME/.claude/settings.json" ]; then
    echo "ERROR: settings.json is missing"
    exit 1
fi
echo "OK — settings.json exists"

# Check Claude Code config directory is persisted
if [ ! -d "$HOME/.claude" ]; then
    echo "ERROR: .claude directory is missing"
    exit 1
fi
echo "OK — .claude directory persisted"

# Check behavior rules are installed
if [ ! -d "$HOME/.claude/rules" ]; then
    echo "ERROR: rules directory is missing at $HOME/.claude/rules"
    exit 1
fi
rules_count=$(find "$HOME/.claude/rules" -type f | wc -l)
if [ "$rules_count" -eq 0 ]; then
    echo "ERROR: no rule files found in $HOME/.claude/rules"
    exit 1
fi
echo "OK — rules installed ($rules_count files)"

echo "All tests passed!"
