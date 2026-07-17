# Multi-AI CLI Workspace (multi-ai-cli)

![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square)

Layer C multi-agent **evaluation** workspace: several coding-agent CLIs in one
container so you can compare providers without maintaining N projects. This is
not a substitute for dedicated single-agent templates (Layers A/B) for daily work.

## Agents installed

| Agent | Binary | Install path |
| ----- | ------ | ------------ |
| Claude Code | `claude` | Official `ghcr.io/anthropics/devcontainer-features/claude-code:1` |
| Grok Build | `grok` | Community `ghcr.io/sliekens/devcontainer-features/grok-build:1` |
| Pi | `pi` | Bootstrap: `npm i -g @earendil-works/pi-coding-agent` |
| Hermes | `hermes` | Community `ghcr.io/devcontainer-community/devcontainer-features/hermes-agent.nousresearch.com:1` |
| OpenAI Codex CLI | `codex` | Community `ghcr.io/sliekens/devcontainer-features/codex:1` |
| Google Gemini CLI | `gemini` | Bootstrap: `npm i -g @google/gemini-cli` |
| OpenCode | `opencode` | Community `ghcr.io/sliekens/devcontainer-features/opencode:1` |

## Security floor (agent-agnostic)

Claude-only suite features (`claude-code-backend`, `claude-code-privacy`, hooks,
rules, skills, plugins, `claude-code-mcp-*`) are **not** attached here. Multi-ai
uses the shared floor so every agent is covered the same way:

| Feature | Role |
| ------- | ---- |
| `non-root-enforcer:1` | Audit non-root `remoteUser` |
| `ai-agent-sandbox:1` | Runtime posture audit (`preset: moderate`) |
| `container-firewall:1` | Whitelist via composite tag `services: multi-ai` (GHCR **1.1.0+**), plus OpenCode CDN hosts |
| `mcp-server-manager:1` | Shared MCP config under `~/.mcp/` (not Claude-only MCP features) |

`claude-code-backend` is intentionally omitted. For Ollama or other custom Claude
backends, use a Layer A `ollama-claude-cli*` template.

## Auth (multi-key — honest expectations)

There is **no single login** for this workspace. Each vendor needs its own
credentials or interactive login:

| Agent | Typical auth |
| ----- | ------------ |
| Claude | `ANTHROPIC_API_KEY` or `claude` login |
| Grok | `XAI_API_KEY` / SuperGrok or X Premium Plus (see xAI docs) |
| Pi | Provider API keys or `pi` `/login` |
| Hermes | `hermes model` + provider keys (OpenRouter, Nous portal, …) |
| Codex | `OPENAI_API_KEY` or `codex` login |
| Gemini | `GEMINI_API_KEY` or Google account login |
| OpenCode | Provider keys per [OpenCode docs](https://opencode.ai/docs/) |

Do not put secrets in `devcontainer.json`. Prefer host env pass-through, a secret
manager, or each CLI's login flow.

## Persistence (per-agent homes)

Named Docker volumes isolate auth and settings **per project** (`${devcontainerId}`):

| Path | Volume purpose |
| ---- | -------------- |
| `~/.claude` | Claude Code |
| `~/.grok` | Grok Build |
| `~/.pi` | Pi |
| `~/.hermes` | Hermes |
| `~/.codex` | Codex |
| `~/.gemini` | Gemini CLI |
| `~/.local/share/opencode` | OpenCode data/auth |
| `~/.config/opencode` | OpenCode config |
| `~/.mcp` | Shared MCP manager config |

Community install features may also bind host paths for Grok/Codex/OpenCode state;
`initializeCommand` pre-creates those host directories when needed.

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version | string | jammy |

## Usage

### Using the Dev Container CLI

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/multi-ai-cli:1
```

### Using the `create-devcontainer` helper

```bash
npx @mrrobot0985/create-devcontainer multi-ai-cli ./my-project
```

## Commands

| Command | Tool |
| ------- | ---- |
| `claude` | Claude Code |
| `grok` | Grok Build |
| `pi` | Pi coding agent |
| `hermes` | Hermes Agent |
| `codex` | OpenAI Codex CLI |
| `gemini` | Google Gemini CLI |
| `opencode` | OpenCode |

## MCP

Shared MCP servers are written by `mcp-server-manager` (default: `github`) under
`~/.mcp/`. Point each agent at that config if it does not auto-discover it. Do not
expect Claude-only MCP orchestrator features in this template.

## Related

- Layer A (Claude depth + Ollama): `ollama-claude-cli*`
- Layer B (dedicated single-agent entry points): planned Grok / Pi / Hermes / Codex / Gemini / OpenCode templates
- Portfolio intent: [Template Portfolio](../../docs/explanation/template-portfolio.md)
