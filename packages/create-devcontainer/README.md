# @mrrobot0985/create-devcontainer

Instantiate devcontainer templates from the [mrrobot0985/devcontainer-templates](https://github.com/mrrobot0985/devcontainer-templates) collection into any workspace.

## Usage

```bash
npx @mrrobot0985/create-devcontainer <template-id> [target-folder]
```

### Examples

Apply the minimal Ollama + Claude Code template to the current directory:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-code .
```

Apply the studio + Docker variant to a specific project:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-code-studio-docker ./my-project
```

## Templates

| ID | Name |
| -- | ---- |
| `ollama-claude-code` | Ollama + Claude Code |
| `ollama-claude-code-studio` | Ollama + Claude Code Studio |
| `ollama-claude-code-studio-docker` | Ollama + Claude Code Studio + Docker |

Run `create-devcontainer` with no arguments to see the full list.

## Options

| Flag | Description |
| ---- | ----------- |
| `--dev` | Force local dev mode (copies files from this repo instead of using GHCR) |
| `--registry` | Force GHCR registry mode (default when installed from npm) |
| `--force` | Overwrite an existing `.devcontainer` directory |
| `--help` | Show help |
| `--version` | Show version |

## Development

Run from the repo source:

```bash
cd packages/create-devcontainer
npm install
npx tsx src/index.ts ollama-claude-code ../../test-output
```

Build and test:

```bash
npm run build
npm test
```

### Template Sync Check

The hard-coded template registry must stay in sync with `src/` in the repo root.
If you add, remove, or rename a template, regenerate the registry:

```bash
npx tsx scripts/sync-template-registry.ts --write
```

CI and the pre-commit hook validate this automatically and fail if they drift.
