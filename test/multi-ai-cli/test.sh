#!/bin/bash
set -euo pipefail

echo "Running multi-ai-cli tests..."

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
node_version=$(node --version)
echo "OK — node version: $node_version"

# Check Python is installed
if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is not installed"
    exit 1
fi
python_version=$(python3 --version)
echo "OK — python version: $python_version"

# Check GitHub CLI is installed
if ! command -v gh > /dev/null 2>&1; then
    echo "ERROR: gh is not installed"
    exit 1
fi
echo "OK — gh CLI is installed"

# Check non-root-enforcer installed
if ! command -v devcontainer-non-root-enforcer > /dev/null 2>&1; then
    echo "ERROR: non-root-enforcer is not installed"
    exit 1
fi
echo "OK — non-root-enforcer installed"

# Check container-security-scan installed
if ! command -v devcontainer-security-scan > /dev/null 2>&1; then
    echo "ERROR: container-security-scan is not installed"
    exit 1
fi
echo "OK — container-security-scan installed"

echo "All tests passed!"
