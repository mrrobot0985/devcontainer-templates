#!/bin/bash
set -euo pipefail

# Setup Python virtual environment and install common AI/LLM packages.
# Runs as onCreateCommand so it happens once at container creation time.

VENV_DIR="/workspaces/.venv"
PYTHON_BIN="$(command -v python3 || command -v python)"

echo "Setting up Python environment with $PYTHON_BIN ..."

# Install uv if not present
if ! command -v uv >/dev/null 2>&1; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# Create virtual environment
if [ ! -d "$VENV_DIR" ]; then
    uv venv "$VENV_DIR" --python "$PYTHON_BIN"
fi

# Activate for this script
export VIRTUAL_ENV="$VENV_DIR"
export PATH="$VENV_DIR/bin:$PATH"

# Common AI/LLM packages
PACKAGES="
    openai
    anthropic
    ollama
    langchain
    langchain-community
    chromadb
    sentence-transformers
    numpy
    pandas
    requests
    pydantic
    python-dotenv
    jupyter
    ipython
"

echo "Installing packages into $VENV_DIR ..."
uv pip install --upgrade pip
uv pip install $PACKAGES

echo "Python environment setup complete."
echo "To activate in new shells: source $VENV_DIR/bin/activate"
