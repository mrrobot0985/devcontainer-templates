#!/bin/bash
set -euo pipefail

# Test — verify the Python devcontainer was built with expected features.
# Runs inside the built container.

echo "Running ollama-claude-cli-python tests..."

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

# Check Python is installed
if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is not installed"
    exit 1
fi
python_version=$(python3 --version)
echo "OK — $python_version"

# Check uv is installed
if ! command -v uv > /dev/null 2>&1; then
    echo "ERROR: uv is not installed"
    exit 1
fi
echo "OK — uv is installed"

# Check virtual environment exists
if [ ! -d "/workspaces/.venv" ]; then
    echo "ERROR: Python virtual environment at /workspaces/.venv is missing"
    exit 1
fi
echo "OK — virtual environment exists"

# Check key packages are installed in venv
if [ -f "/workspaces/.venv/bin/python" ]; then
    venv_python="/workspaces/.venv/bin/python"
    for pkg in openai ollama langchain chromadb numpy pandas; do
        if $venv_python -c "import $pkg" 2>/dev/null; then
            echo "OK — package $pkg is installed in venv"
        else
            echo "WARN — package $pkg not found in venv"
        fi
    done
else
    echo "WARN — venv python binary not found"
fi

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

echo "All tests passed!"
