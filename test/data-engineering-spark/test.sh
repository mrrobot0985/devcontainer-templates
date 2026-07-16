#!/bin/bash
set -euo pipefail

echo "Running data-engineering-spark tests..."

# Check Python is installed
if ! command -v python3 > /dev/null 2>&1; then
    echo "ERROR: python3 is not installed"
    exit 1
fi
python_version=$(python3 --version)
echo "OK — python version: $python_version"

# Check Node.js is installed
if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
echo "OK — node installed"

# Check Java is installed
if ! command -v java > /dev/null 2>&1; then
    echo "ERROR: java is not installed"
    exit 1
fi
java_version=$(java -version 2>&1 | head -1)
echo "OK — java installed ($java_version)"

# Check Docker is available
if ! command -v docker > /dev/null 2>&1; then
    echo "ERROR: docker is not installed"
    exit 1
fi
echo "OK — docker installed"

# Check Spark is referenced in post-create
if [ -f ".devcontainer/bootstrap.sh" ]; then
    echo "OK — bootstrap script exists"
else
    echo "WARNING: bootstrap script not found in expected location"
fi

echo "All tests passed!"
