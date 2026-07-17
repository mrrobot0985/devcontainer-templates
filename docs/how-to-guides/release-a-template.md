# Releasing a Template

This repository uses git tags to trigger releases. Templates and the npm package have separate tag prefixes so their release histories do not collide.

## Release a devcontainer template

1. **Update the version** in `src/<template>/devcontainer-template.json`:

   ```json
   {
     "id": "ollama-claude-cli",
     "version": "0.2.0"
   }
   ```

1. **Commit the change** with a conventional commit message:

   ```bash
   git add src/ollama-claude-cli/devcontainer-template.json
   git commit -m "feat(ollama-claude-cli): bump version to 0.2.0"
   ```

1. **Create a signed tag** with the template name and version:

   ```bash
   git tag -s ollama-claude-cli-v0.2.0 -m "release ollama-claude-cli v0.2.0"
   ```

1. **Push the tag** to trigger `release.yaml`:

   ```bash
   git push origin ollama-claude-cli-v0.2.0
   ```

The `release.yaml` workflow runs on every `*-v*` tag and publishes the matching template to GHCR:

```text
ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:0.2.0
```

Templates are private by default in GHCR. After the first publish, set the package visibility to public in its GHCR package settings page.

## Release the npm package

The `@mrrobot0985/create-devcontainer` helper is released independently with `v*` or `@*` tags.

1. **Update the version** in `packages/create-devcontainer/package.json`.

1. **Commit the change**:

   ```bash
   git add packages/create-devcontainer/package.json
   git commit -m "chore(create-devcontainer): bump version to 1.1.0"
   ```

1. **Create and push a signed tag**:

   ```bash
   git tag -s v1.1.0 -m "release create-devcontainer v1.1.0"
   git push origin v1.1.0
   ```

The `create-devcontainer-ci.yaml` workflow runs on tag pushes and publishes the built package to npm.

### npm lag gate

After a monorepo version bump, CI requires the registry to match. Fail closed when:

```bash
npm view @mrrobot0985/create-devcontainer version   # must be >= package.json
```

If the lag gate is red, push the matching `vX.Y.Z` tag (this section) so publish can catch up. The gate also runs on a weekly schedule.

## Why prefixed tags matter

A single git tag namespace is shared across all templates and the npm package. Without a prefix, `v1.0.0` is ambiguous — it could apply to any template or the package. Prefixed tags keep release histories independent and readable.

| Artifact    | Tag format                          | Example                    |
| ----------- | ----------------------------------- | -------------------------- |
| Template    | `<template-name>-v<semver>`         | `ollama-claude-cli-v0.2.0` |
| npm package | `v<semver>` or `@<scope>/v<semver>` | `v1.1.0`                   |

## Verify a release

- Check the Actions tab for the `Release Dev Container Templates` or `create-devcontainer CI` run.

- Pull the template from GHCR:

  ```bash
  devcontainer templates apply \
    --workspace-folder ./my-project \
    --template-id ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:0.2.0
  ```

- Verify the npm package:

  ```bash
  npm view @mrrobot0985/create-devcontainer version
  ```
