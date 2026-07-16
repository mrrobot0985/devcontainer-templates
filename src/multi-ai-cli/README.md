# Multi-AI CLI Workspace

Devcontainer template bundling multiple AI coding assistants for evaluation and
comparison: Claude Code, OpenAI Codex CLI, and shared MCP server configuration.

## What's Inside

- **Claude Code** (`claude`) — Anthropic's AI coding assistant
- **OpenAI Codex CLI** (`codex`) — OpenAI's coding agent
- **Shared MCP config** — `/home/vscode/.config/mcp/` for cross-tool server config
- **Privacy defaults** — telemetry disabled
- **Security scan** — Trivy vulnerability scan on container creation
- **Non-root enforcement** — validates remoteUser is not root

## Usage

```json
"image": "ghcr.io/mrrobot0985/devcontainer-templates/multi-ai-cli:latest"
```

## Commands

| Command | Tool |
|---------|------|
| `claude` | Claude Code |
| `codex` | OpenAI Codex CLI |

## MCP Servers

Place `.mcp.json` in the workspace root. The `claude-code-mcp-orchestrator`
feature (if added) will manage server lifecycle.

## Notes

- API keys must be configured separately for each tool.
- Gemini CLI and OpenCode CLI are installed opportunistically if available.
