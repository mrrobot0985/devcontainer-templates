#!/bin/bash
set -e

# Multi-AI CLI Workspace — bootstrap script
# Installs Claude Code, OpenAI Codex CLI, Google Gemini CLI, and OpenCode CLI
# Path-filter smoke: keep this file under src/multi-ai-cli so detect-changes selects it.

echo "Installing AI CLI tools..."

# Claude Code
npm install -g @anthropic-ai/claude-code

# OpenAI Codex CLI
npm install -g @openai/codex

# Google Gemini CLI (via pip)
pip install --user google-generativeai-cli 2>/dev/null || echo "Gemini CLI not available on PyPI; skipping"

# OpenCode CLI
npm install -g opencode-ai 2>/dev/null || echo "OpenCode CLI install failed; skipping"

# Create a shared MCP config directory
mkdir -p /home/vscode/.config/mcp
chown -R vscode:vscode /home/vscode/.config

echo "Multi-AI CLI workspace ready."
echo "  Claude Code: claude"
echo "  OpenAI Codex: codex"
echo "  Available tools installed."
