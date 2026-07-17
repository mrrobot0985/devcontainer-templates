Full documentation is available in the [template repository docs](../../docs/reference/create-devcontainer-cli.md).

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

Apply a template and generate a `README.md` skeleton:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --readme
```

Combine `--name` and `--readme` to create a named devcontainer and a matching README title:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --name "My Project" --readme
```

## Templates

**Source of truth in this monorepo** ships **15 templates** in four portfolio layers.
What you get via `npx` depends on the **published npm version** (see the badge above).
If monorepo `package.json` is ahead of npm, use a local build or wait for a release
([templates#83](https://github.com/mrrobot0985/devcontainer-templates/issues/83)).

Full details:
[Template Catalog](https://github.com/mrrobot0985/devcontainer-templates/blob/main/docs/reference/template-catalog.md).

### Layer A — Claude + Ollama

| ID                          | Name                          |
| --------------------------- | ----------------------------- |
| `ollama-claude-cli`         | Ollama + Claude CLI           |
| `ollama-claude-cli-cpu`     | Ollama + Claude CLI (CPU)     |
| `ollama-claude-cli-compose` | Ollama + Claude CLI (Compose) |
| `ollama-claude-cli-python`  | Ollama + Claude CLI + Python  |
| `ollama-claude-cli-studio`  | Ollama + Claude CLI Studio    |

### Layer B — Agent entry points

| ID                      | Name                  |
| ----------------------- | --------------------- |
| `grok-build-cli`        | Grok Build CLI        |
| `grok-build-cli-studio` | Grok Build CLI Studio |
| `pi-coding-agent`       | Pi Coding Agent       |
| `hermes-agent`          | Hermes Agent          |
| `codex-cli`             | OpenAI Codex CLI      |
| `gemini-cli`            | Google Gemini CLI     |
| `opencode-cli`          | OpenCode CLI          |

### Layer C — Multi-agent evaluation

| ID             | Name                   |
| -------------- | ---------------------- |
| `multi-ai-cli` | Multi-AI CLI Workspace |

### Layer D — Domain stacks

| ID                       | Name                        |
| ------------------------ | --------------------------- |
| `cloud-native-k8s`       | Cloud Native Kubernetes     |
| `data-engineering-spark` | Data Engineering with Spark |

Run `create-devcontainer` with no arguments to see the full list (grouped by layer).

## Options

| Flag         | Description                                              |
| ------------ | -------------------------------------------------------- |
| `--registry` | Force GHCR registry mode (default is bundled local copy) |
| `--force`    | Overwrite an existing `.devcontainer` directory          |
| `--name`     | Override the devcontainer configuration name             |
| `--readme`   | Create a `README.md` skeleton in the target directory    |
| `--help`     | Show help                                                |
| `--version`  | Show version                                             |

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
