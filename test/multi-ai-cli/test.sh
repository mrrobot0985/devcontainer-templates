#!/bin/bash
set -euo pipefail

echo "Running multi-ai-cli tests..."

# --- Base toolchain ---
if ! command -v node > /dev/null 2>&1; then
	echo "ERROR: node is not installed"
	exit 1
fi
echo "OK — node version: $(node --version)"

if ! command -v npm > /dev/null 2>&1; then
	echo "ERROR: npm is not installed"
	exit 1
fi
echo "OK — npm is installed"

if ! command -v gh > /dev/null 2>&1; then
	echo "ERROR: gh is not installed"
	exit 1
fi
echo "OK — gh CLI is installed"

# --- Agent-agnostic security floor ---
if ! command -v non-root-enforcer > /dev/null 2>&1; then
	echo "ERROR: non-root-enforcer is not installed"
	exit 1
fi
echo "OK — non-root-enforcer installed"

if [ ! -f /usr/local/bin/ai-agent-sandbox-check ] \
	&& ! command -v ai-agent-sandbox-check > /dev/null 2>&1; then
	echo "ERROR: ai-agent-sandbox check script not found"
	exit 1
fi
echo "OK — ai-agent-sandbox present"

if [ ! -x /usr/local/bin/container-firewall-init ] \
	&& ! command -v container-firewall-init > /dev/null 2>&1; then
	echo "ERROR: container-firewall is not installed"
	exit 1
fi
echo "OK — container-firewall installed"

# multi-ai composite tag must exist on published firewall 1.1.0+
SERVICES_JSON=""
for candidate in \
	/usr/local/share/container-firewall/services.json \
	/usr/local/share/container-firewall-services.json; do
	if [ -f "${candidate}" ]; then
		SERVICES_JSON="${candidate}"
		break
	fi
done
if [ -n "${SERVICES_JSON}" ]; then
	if command -v jq > /dev/null 2>&1; then
		if ! jq -e '."multi-ai"' "${SERVICES_JSON}" > /dev/null 2>&1; then
			echo "ERROR: multi-ai service tag missing from ${SERVICES_JSON}"
			exit 1
		fi
		echo "OK — multi-ai firewall tag present"
	else
		if ! grep -q '"multi-ai"' "${SERVICES_JSON}"; then
			echo "ERROR: multi-ai service tag missing from ${SERVICES_JSON}"
			exit 1
		fi
		echo "OK — multi-ai firewall tag present (grep)"
	fi
else
	echo "WARN — firewall services.json not found; skipping multi-ai tag assertion"
fi

# Deleted feature must not reappear
if command -v devcontainer-security-scan > /dev/null 2>&1; then
	echo "ERROR: container-security-scan must not be installed (deleted feature)"
	exit 1
fi
echo "OK — container-security-scan not present"

# --- Agent binaries (required where network/feature install allows) ---
require_cmd() {
	local name="$1"
	if ! command -v "${name}" > /dev/null 2>&1; then
		echo "ERROR: ${name} is not on PATH"
		exit 1
	fi
	echo "OK — ${name}: $(command -v "${name}")"
}

require_cmd claude
require_cmd grok
require_cmd codex
require_cmd opencode
require_cmd pi
require_cmd gemini
require_cmd hermes

# --- Per-agent home dirs exist ---
for dir in \
	"${HOME}/.claude" \
	"${HOME}/.grok" \
	"${HOME}/.pi" \
	"${HOME}/.hermes" \
	"${HOME}/.codex" \
	"${HOME}/.gemini" \
	"${HOME}/.local/share/opencode" \
	"${HOME}/.config/opencode" \
	"${HOME}/.mcp"; do
	if [ ! -d "${dir}" ]; then
		echo "ERROR: expected agent home missing: ${dir}"
		exit 1
	fi
	echo "OK — home dir: ${dir}"
done

# --- Shared MCP manager (agent-agnostic) ---
if [ -d "${HOME}/.mcp" ]; then
	echo "OK — shared MCP config dir present"
else
	echo "ERROR: ~/.mcp missing (mcp-server-manager)"
	exit 1
fi

echo "All tests passed!"
