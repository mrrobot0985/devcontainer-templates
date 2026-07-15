# Persistence Model

Devcontainers are meant to be rebuilt frequently. Without persistence, every rebuild would reset the Claude CLI configuration, authentication state, user settings, and session history. The templates in this collection preserve `~/.claude` across rebuilds using a named Docker volume.

## Named volume per devcontainer

Both templates declare a mount that binds a Docker volume to `/home/vscode/.claude`:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

The `${devcontainerId}` variable is resolved by the Dev Container CLI to a stable identifier for the workspace. This means:

- Rebuilding the same workspace keeps the same volume and the same `~/.claude` contents.
- Deleting the volume or removing the `.devcontainer` configuration removes the persisted state.

## Per-project isolation

The `${devcontainerId}` suffix isolates state per project. Settings from one workspace do not leak into another because each workspace gets a different volume name. This is important when you work on multiple Claude-backed projects from the same host.

For example, two projects using the same template will mount different volumes:

```text
claude-cli-config-<project-a-id>
claude-cli-config-<project-b-id>
```

## What is persisted

The volume preserves everything under `~/.claude`, including:

- Claude CLI settings (`settings.json`)
- Authentication tokens and session state
- User-level configuration written by features or bootstrap scripts

## What is not persisted

Everything outside `~/.claude` is tied to the container image or the workspace bind mount. Rebuilding resets:

- Installed system packages not part of the image
- Files outside `/home/vscode/.claude` and outside the workspace mount
- Container-level state such as running background processes

## Rebuild behavior

When you run `devcontainer up --workspace-folder . --build-no-cache`, the old container is replaced but the named volume is reused. The first startup after a rebuild may re-run `postCreateCommand` and bootstrap scripts, but the persisted Claude CLI state remains available immediately.

## Cleaning up persisted state

To start fresh, remove the named volume. The exact name depends on the resolved `${devcontainerId}`. You can list volumes and remove the matching one:

```bash
docker volume ls | grep claude-cli-config-
docker volume rm claude-cli-config-<devcontainerId>
```

Removing the volume resets all Claude CLI state for that workspace. You can also delete the `.devcontainer` configuration and rebuild, which typically creates a new `${devcontainerId}` and therefore a new volume.
