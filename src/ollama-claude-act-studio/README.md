# Ollama + Claude CLI + Act Studio (ollama-claude-act-studio)

Prototype devcontainer that combines Claude CLI with [nektos/act](https://github.com/nektos/act) to run a local GitHub Actions workflow for autonomous project exploration and planning.

## What it does

When the container starts, the bootstrap script:

1. Configures the Ollama backend connection
2. Verifies tooling (gh, docker, act, claude)
3. Executes `.act/workflows/bootstrap.yml` via `act`

The workflow then runs `claude -p` commands to:

- Read and summarize `README.md`
- Plan the next iteration of the `/prototype`

## Includes

- Node.js 20
- Claude CLI (via official Anthropic feature)
- GitHub CLI (`github-cli`)
- nektos/act (`ghcr.io/dhoeric/features/act`)
- Custom backend configuration (`claude-code-backend`)
- Privacy defaults (`claude-code-privacy`)
- Docker-in-Docker (for act to spawn workflow containers)

## Persistence

Authentication tokens, user settings, and session history under `~/.claude` are preserved across container rebuilds via a named Docker volume:

```json
"mounts": [
    "source=claude-cli-config-${devcontainerId},target=/home/vscode/.claude,type=volume"
]
```

## Options

| Options Id | Description | Type | Default Value |
| ----- | ----- | ----- | ----- |
| `imageVariant` | Ubuntu version (use ubuntu-22.04 or ubuntu-18.04 on local arm64/Apple Silicon): | string | jammy |

## Usage

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-act-studio:latest
```

Or create a new project with the `create-devcontainer` helper:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-act-studio ./my-project
```

## Prototype Notes

- This template is experimental. The act workflow assumes `claude` is available in the execution environment.
- When running via `act --bind`, the workflow shares the host container's filesystem and can access the installed `claude` binary.
- Without `--bind`, the workflow runner image does not include Claude and will skip the AI steps gracefully.
