# create-devcontainer CLI Reference

`@mrrobot0985/create-devcontainer` is an npm helper that copies templates from the [mrrobot0985/devcontainer-templates](https://github.com/mrrobot0985/devcontainer-templates) collection into any workspace. It is useful for scaffolding a new project without needing the Dev Container CLI or GHCR access for the **template files** themselves (features inside a template still resolve from GHCR at `devcontainer up` time).

## Published vs monorepo versions

| Surface                                     | What it is                                                                |
| ------------------------------------------- | ------------------------------------------------------------------------- |
| **Monorepo** `packages/create-devcontainer` | Source of truth for the 15-template portfolio (registry + bundled copies) |
| **npm** `@mrrobot0985/create-devcontainer`  | What `npx` users get                                                      |

As of the 2026-07 maturity audit, **npm can lag monorepo** (example: monorepo `0.8.x` with 15 templates while npm `latest` was still an older release with a smaller registry). Always check:

```bash
npm view @mrrobot0985/create-devcontainer version
node -p "require('./packages/create-devcontainer/package.json').version"  # from repo root
```

If versions differ, prefer running from monorepo source (`npx tsx packages/create-devcontainer/src/index.ts …`) until publish catches up ([templates#83](https://github.com/mrrobot0985/devcontainer-templates/issues/83)).

## Installation and usage

The package is designed to be run with `npx` without a global install:

```bash
npx @mrrobot0985/create-devcontainer <template-id> [target-folder]
```

If you do not provide a target folder, the current directory is used.

## Templates

The monorepo registry includes the full portfolio (Layer A–D). IDs include:

| ID                                                                                                                                | Layer (summary)            |
| --------------------------------------------------------------------------------------------------------------------------------- | -------------------------- |
| `ollama-claude-cli`, `ollama-claude-cli-cpu`, `ollama-claude-cli-compose`, `ollama-claude-cli-python`, `ollama-claude-cli-studio` | A — Claude depth           |
| `grok-build-cli`, `grok-build-cli-studio`, `codex-cli`, `gemini-cli`, `opencode-cli`, `pi-coding-agent`, `hermes-agent`           | B — agent entry points     |
| `multi-ai-cli`                                                                                                                    | C — multi-agent evaluation |
| `cloud-native-k8s`, `data-engineering-spark`                                                                                      | D — domain stacks          |

Run the command with no arguments (or `--help`) to see the list **shipped in the version you are running**.

## Options

| Flag            | Description                                                      |
| --------------- | ---------------------------------------------------------------- |
| `--registry`    | Force GHCR registry mode. The default is the bundled local copy. |
| `--force`       | Overwrite an existing `.devcontainer` directory.                 |
| `--name <name>` | Override the devcontainer configuration name.                    |
| `--readme`      | Create a `README.md` skeleton in the target directory.           |
| `--help`        | Show help.                                                       |
| `--version`     | Show version.                                                    |

## Examples

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli .
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
npx @mrrobot0985/create-devcontainer multi-ai-cli ./compare --name "Multi AI"
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --readme
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --registry
```

## Development

```bash
cd packages/create-devcontainer
npm install
npx tsx src/index.ts ollama-claude-cli ../../test-output
npm run build
npm test
```

## Template registry sync

The helper keeps a hard-coded registry in `packages/create-devcontainer/src/templates.ts`. When templates are added, removed, or renamed in `src/`, regenerate the registry:

```bash
npx tsx scripts/sync-template-registry.ts --write
```

CI and the pre-commit hook validate that the registry stays in sync with `src/`.

## Publishing

npm publish is driven by create-devcontainer CI on `v*` / `@*` tags (see [CI workflows](ci-workflows.md)). Template GHCR publish uses `*-v*` tags and is separate.
