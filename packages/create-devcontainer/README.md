# @mrrobot0985/create-devcontainer

![npm version](https://img.shields.io/npm/v/@mrrobot0985/create-devcontainer)
![CI](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/create-devcontainer-ci.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Instantiate devcontainer templates from the [mrrobot0985/devcontainer-templates](https://github.com/mrrobot0985/devcontainer-templates) collection into any workspace.

## Usage

```bash
npx @mrrobot0985/create-devcontainer <template-id> [target-folder]
```

### Examples

Apply the minimal Ollama + Claude CLI template to the current directory:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli .
```

Apply the studio template to a specific project:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```

Apply the minimal template with a custom devcontainer name:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --name "My Project"
```

## Templates

| ID | Name |
| -- | ---- |
| `ollama-claude-cli` | Ollama + Claude CLI |
| `ollama-claude-cli-studio` | Ollama + Claude CLI Studio |

Run `create-devcontainer` with no arguments to see the full list.

## Options

| Flag | Description |
| ---- | ----------- |
| `--registry` | Force GHCR registry mode (default is bundled local copy) |
| `--force` | Overwrite an existing `.devcontainer` directory |
| `--name` | Override the devcontainer configuration name |
| `--help` | Show help |
| `--version` | Show version |

## Development

Run from the repo source:

```bash
cd packages/create-devcontainer
npm install
npx tsx src/index.ts ollama-claude-cli ../../test-output
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
