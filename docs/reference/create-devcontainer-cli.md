# create-devcontainer CLI Reference

`@mrrobot0985/create-devcontainer` is an npm helper that copies templates from the [mrrobot0985/devcontainer-templates](https://github.com/mrrobot0985/devcontainer-templates) collection into any workspace. It is useful for scaffolding a new project without needing the Dev Container CLI or GHCR access.

## Installation and usage

The package is designed to be run with `npx` without a global install:

```bash
npx @mrrobot0985/create-devcontainer <template-id> [target-folder]
```

If you do not provide a target folder, the current directory is used.

## Templates

| ID | Name |
| -- | ---- |
| `ollama-claude-cli` | Ollama + Claude CLI |
| `ollama-claude-cli-studio` | Ollama + Claude CLI Studio |

Run the command with no arguments to see the full list.

## Options

| Flag | Description |
| ---- | ----------- |
| `--registry` | Force GHCR registry mode. The default is the bundled local copy. |
| `--force` | Overwrite an existing `.devcontainer` directory. |
| `--name <name>` | Override the devcontainer configuration name. |
| `--readme` | Create a `README.md` skeleton in the target directory. |
| `--help` | Show help. |
| `--version` | Show version. |

## Examples

Apply the minimal template to the current directory:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli .
```

Apply the studio template to a specific project:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli-studio ./my-project
```

Apply with a custom devcontainer name:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --name "My Project"
```

Apply and generate a `README.md` skeleton:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --readme
```

Combine name and README to create a named devcontainer and a matching README title:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --name "My Project" --readme
```

Pull from GHCR instead of using the bundled template:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --registry
```

## Development

Run from the repository source:

```bash
cd packages/create-devcontainer
npm install
npx tsx src/index.ts ollama-claude-cli ../../test-output
```

Build and test the package:

```bash
npm run build
npm test
```

## Template registry sync

The helper keeps a hard-coded registry in `packages/create-devcontainer/src/templates.ts`. When templates are added, removed, or renamed in `src/`, regenerate the registry:

```bash
npx tsx scripts/sync-template-registry.ts --write
```

CI and the pre-commit hook validate that the registry stays in sync with `src/`.
