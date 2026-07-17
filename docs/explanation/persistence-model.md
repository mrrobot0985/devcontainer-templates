# Persistence Model

Devcontainers are rebuilt frequently. Without persistence, every rebuild would
reset agent CLI configuration, authentication state, and session history.

This collection uses **named Docker volumes** mounted at each agent's home
directory (or config path). The model is **per-agent**, not Claude-only.

## Named volume per agent home

Templates that support persistence declare mounts like:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` variable is resolved by the Dev Container CLI to a
stable identifier for the workspace. Rebuilding the same workspace keeps the
same volume; deleting the volume clears that agent's persisted state.

## Expected mount targets

| Agent / surface | Typical mount target                         | Notes                              |
| --------------- | -------------------------------------------- | ---------------------------------- |
| Claude Code     | `/home/vscode/.claude`                       | Layer A ollama-claude-cli\* family |
| Grok Build      | `/home/vscode/.grok`                         | Layer B grok templates             |
| Codex           | `/home/vscode/.codex`                        | Layer B                            |
| Gemini          | `/home/vscode/.gemini`                       | Layer B                            |
| Pi              | `/home/vscode/.pi`                           | Layer B                            |
| Hermes          | `/home/vscode/.hermes`                       | Layer B                            |
| OpenCode        | `~/.local/share/opencode` and/or config path | May need more than one mount       |
| Multi-AI        | One volume **per** agent home above          | See `multi-ai-cli`                 |

## Current template status (honesty)

As of the 2026-07 maturity audit, **not every Layer B template ships mounts yet**.

| Template                                               | Home mounts today                                |
| ------------------------------------------------------ | ------------------------------------------------ |
| `ollama-claude-cli*`                                   | Yes (`~/.claude`)                                |
| `multi-ai-cli`                                         | Yes (per-agent homes)                            |
| `gemini-cli`, `pi-coding-agent`, `hermes-agent`        | Yes                                              |
| `codex-cli`                                            | **Missing** — tracked in templates#85            |
| `grok-build-cli`                                       | **Missing** — tracked in templates#85            |
| `grok-build-cli-studio`                                | **Missing** — tracked in templates#85            |
| `opencode-cli`                                         | **Missing** — tracked in templates#85            |
| Layer D (`cloud-native-k8s`, `data-engineering-spark`) | No agent home mounts (not agent-auth workspaces) |

Treat the table above as the source of truth until #85 lands. Do not assume a
template persists auth solely because the portfolio narrative says "per-agent homes."

## Per-project isolation

The `${devcontainerId}` suffix isolates state per project so settings from one
workspace do not leak into another.

## What is persisted

Everything under the mounted agent home (for example under `~/.claude`):

- CLI settings and local config
- Authentication / session state written by the agent
- User-level files written by features or bootstrap scripts into that path

## What is not persisted

Everything outside the named volume and outside the workspace bind mount:

- System packages not baked into the image
- Files under `/home/vscode` that are not on a named volume
- Container process state

## Rebuild behavior

`devcontainer up --workspace-folder . --build-no-cache` replaces the container
but reuses named volumes. Bootstrap/`postCreateCommand` may re-run; persisted
agent state remains if the mount was declared.

## Cleaning up

```bash
docker volume ls | grep -E 'claude-cli-config-|multi-ai-|gemini-cli-home-|pi-coding-agent-home-'
# docker volume rm <volume-name>
```

Removing a volume resets that agent surface for that workspace.

## Related

- [Template portfolio](template-portfolio.md) — layers A–D
- [How to combine features](https://github.com/mrrobot0985/devcontainer-features/blob/main/docs/how-to-guides/combine-features.md) — agent-minimal floor + mounts
- Maturity issue [templates#85](https://github.com/mrrobot0985/devcontainer-templates/issues/85) — fill missing Layer B mounts
