#!/bin/bash
cd $(dirname "$0")
source test-utils.sh

# Template specific tests
check "distro" lsb_release -c
check "node-installed" node --version
check "claude-installed" which claude
check "gh-installed" gh --version
check "settings-exists" test -f ~/.claude/settings.json
check "hooks-dir-exists" test -d ~/.claude/hooks
check "claude-dir-persisted" test -d ~/.claude

# Ollama is only installed when using container-local instance
# With the default http://host.docker.internal:11434, Ollama is expected on the host
OLLAMA_BASE_URL="http://host.docker.internal:11434"
if [ "$OLLAMA_BASE_URL" = "http://localhost:11434" ] || [ "$OLLAMA_BASE_URL" = "http://127.0.0.1:11434" ]; then
	check "ollama-installed" which ollama
fi

# Report result
reportResults
