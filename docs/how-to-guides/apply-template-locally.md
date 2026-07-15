# Applying a Template Locally

There are three ways to apply a template from this collection to a local workspace. Choose the one that fits your workflow.

## Option 1: `npx @mrrobot0985/create-devcontainer` (recommended for new projects)

The helper copies a bundled template into your target directory. It does not require GHCR access during development and works offline once installed.

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project
```

Apply to the current directory:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli .
```

Useful flags:

| Flag                  | Purpose                                                       |
| --------------------- | ------------------------------------------------------------- |
| `--registry`          | Pull the template from GHCR instead of using the bundled copy |
| `--force`             | Overwrite an existing `.devcontainer` directory               |
| `--name "My Project"` | Override the devcontainer configuration name                  |
| `--readme`            | Create a `README.md` skeleton in the target directory         |

Combine flags:

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --name "My Project" --readme
```

## Option 2: `devcontainer templates apply` from GHCR

Use the Dev Container CLI to apply a published template directly from the GitHub Container Registry:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
```

Use a specific major version:

```bash
devcontainer templates apply \
  --workspace-folder ./my-project \
  --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:1
```

This method is useful when you want the exact published artifact rather than the bundled source.

## When to use `--registry`

The bundled copy is updated whenever the npm package is published. Use `--registry` when:

- You want the latest template published to GHCR before the next npm package release.
- You are testing a template change that has been published but not yet bundled.
- The bundled copy has been removed or you need a pinned registry version.

```bash
npx @mrrobot0985/create-devcontainer ollama-claude-cli ./my-project --registry
```

## Render a template with default options for inspection

The `render-template.sh` script copies a template to a destination directory and substitutes `${templateOption:<key>}` placeholders with their default values. This is useful for inspecting what will actually be applied or for feeding a rendered configuration into a manual build.

```bash
./scripts/render-template.sh ollama-claude-cli /tmp/rendered-template
```

The output includes the rendered source files and copies the matching smoke test into `/tmp/rendered-template/test-project`.

## Next step

After applying, build the devcontainer with VS Code: (`Dev Containers: Rebuild and Reopen in Container`) or with the CLI:

```bash
cd ./my-project
devcontainer up --workspace-folder .
```
