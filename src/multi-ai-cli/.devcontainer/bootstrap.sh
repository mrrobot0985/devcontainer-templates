#!/usr/bin/env bash
# Multi-AI CLI Workspace — post-create bootstrap
# Installs agents that lack a mature community feature and prepares home dirs.
set -euo pipefail

echo "=== Multi-AI CLI bootstrap ==="

REMOTE_USER="${_REMOTE_USER:-vscode}"
HOME_DIR="$(getent passwd "${REMOTE_USER}" | cut -d: -f6)"
HOME_DIR="${HOME_DIR:-/home/${REMOTE_USER}}"

# Agent home directories (named volumes may mount empty).
AGENT_HOMES=(
	"${HOME_DIR}/.claude"
	"${HOME_DIR}/.grok"
	"${HOME_DIR}/.pi"
	"${HOME_DIR}/.hermes"
	"${HOME_DIR}/.codex"
	"${HOME_DIR}/.gemini"
	"${HOME_DIR}/.local/share/opencode"
	"${HOME_DIR}/.config/opencode"
	"${HOME_DIR}/.mcp"
)

for dir in "${AGENT_HOMES[@]}"; do
	mkdir -p "${dir}"
done

if command -v chown >/dev/null 2>&1; then
	chown -R "${REMOTE_USER}:${REMOTE_USER}" \
		"${HOME_DIR}/.claude" \
		"${HOME_DIR}/.grok" \
		"${HOME_DIR}/.pi" \
		"${HOME_DIR}/.hermes" \
		"${HOME_DIR}/.codex" \
		"${HOME_DIR}/.gemini" \
		"${HOME_DIR}/.local" \
		"${HOME_DIR}/.config" \
		"${HOME_DIR}/.mcp" 2>/dev/null || true
fi

# Prefer the non-root user for global npm installs when possible.
run_as_user() {
	if [ "$(id -u)" -eq 0 ] && id "${REMOTE_USER}" >/dev/null 2>&1; then
		su -s /bin/bash "${REMOTE_USER}" -c "$*"
	else
		bash -c "$*"
	fi
}

install_npm_global() {
	local pkg="$1"
	local bin_name="$2"
	if command -v "${bin_name}" >/dev/null 2>&1; then
		echo "OK — ${bin_name} already on PATH ($(command -v "${bin_name}"))"
		return 0
	fi
	echo "Installing ${pkg}..."
	if run_as_user "npm install -g --ignore-scripts ${pkg}"; then
		if command -v "${bin_name}" >/dev/null 2>&1; then
			echo "OK — installed ${bin_name}"
			return 0
		fi
		echo "WARN — ${pkg} installed but ${bin_name} not on PATH yet"
		return 0
	fi
	echo "ERROR — failed to install ${pkg}"
	return 1
}

# Pi coding agent (no mature community feature; official npm package).
install_npm_global "@earendil-works/pi-coding-agent" "pi"

# Google Gemini CLI (official npm package; avoid broken PyPI names).
install_npm_global "@google/gemini-cli" "gemini"

echo ""
echo "=== Feature-installed agents (expect already on PATH) ==="
for cmd in claude grok codex opencode hermes; do
	if command -v "${cmd}" >/dev/null 2>&1; then
		echo "OK — ${cmd}: $(command -v "${cmd}")"
	else
		echo "WARN — ${cmd} not on PATH (feature install may have failed or binary name differs)"
	fi
done

echo ""
echo "=== Multi-AI CLI workspace ready ==="
echo "Commands (when installed): claude, grok, pi, hermes, codex, gemini, opencode"
echo ""
echo "Auth is per-vendor — configure keys or login flows separately:"
echo "  Claude:  ANTHROPIC_API_KEY or 'claude' login"
echo "  Grok:    XAI_API_KEY / SuperGrok subscription (see xAI docs)"
echo "  Pi:      provider keys or 'pi' /login"
echo "  Hermes:  'hermes model' / provider keys (OpenRouter, Nous portal, ...)"
echo "  Codex:   OPENAI_API_KEY or 'codex' login"
echo "  Gemini:  GEMINI_API_KEY / Google login"
echo "  OpenCode: provider keys per OpenCode docs"
echo ""
echo "Shared MCP config: ~/.mcp/ (mcp-server-manager)"
echo "Ollama/custom Claude backends are not wired here — use Layer A ollama-claude-cli* templates."
