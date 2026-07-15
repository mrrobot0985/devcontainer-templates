# Creating Your First Template

This tutorial adds a new devcontainer template to the repository. By the end, you will have a publishable template with metadata, a `.devcontainer` configuration, and a smoke test.

## Step 1: Choose an ID and create the directory

Template IDs must match their directory name and use kebab-case. Create the directory under `src/`:

```bash
mkdir -p src/my-template/.devcontainer
mkdir -p test/my-template
```

## Step 2: Write `devcontainer-template.json`

Create `src/my-template/devcontainer-template.json` with the required metadata:

```json
{
  "id": "my-template",
  "version": "0.1.0",
  "name": "My Template",
  "description": "Short description of what this template provides.",
  "documentationURL": "https://github.com/mrrobot0985/devcontainer-templates/tree/main/src/my-template",
  "licenseURL": "https://github.com/mrrobot0985/devcontainer-templates/blob/main/LICENSE",
  "options": {
    "imageVariant": {
      "type": "string",
      "description": "Ubuntu version:",
      "proposals": ["jammy", "focal"],
      "default": "jammy"
    }
  },
  "platforms": ["Any"]
}
```

The `id` must match the directory name exactly. The `version` should follow semantic versioning. The `options` object exposes user-configurable values; the Dev Container CLI substitutes `${templateOption:<key>}` placeholders with the chosen values at apply time.

## Step 3: Write `.devcontainer/devcontainer.json`

Create `src/my-template/.devcontainer/devcontainer.json` with the actual container configuration. Here is a minimal example that uses the `imageVariant` option:

```json
{
  "name": "My Template",
  "image": "mcr.microsoft.com/devcontainers/base:${templateOption:imageVariant}",
  "remoteUser": "vscode",
  "features": {
    "ghcr.io/devcontainers/features/node:2.1.0": {
      "version": "20"
    }
  },
  "postCreateCommand": "bash .devcontainer/bootstrap.sh"
}
```

If your template needs a custom bootstrap script, add `src/my-template/.devcontainer/bootstrap.sh`:

```bash
#!/bin/bash
set -euo pipefail
echo "Bootstrap complete"
```

## Step 4: Add a smoke test

Create `test/my-template/test.sh` to verify the built container meets expectations. Keep it focused on the features your template installs:

```bash
#!/bin/bash
set -euo pipefail

if ! command -v node > /dev/null 2>&1; then
    echo "ERROR: node is not installed"
    exit 1
fi
node --version

echo "All tests passed!"
```

Make the script executable:

```bash
chmod +x test/my-template/test.sh
```

## Step 5: Generate the template README

Run the README generator so the template has an auto-generated README:

```bash
python3 scripts/generate-template-readmes.py
```

## Step 6: Update the create-devcontainer registry

The `create-devcontainer` helper keeps a hard-coded registry of templates. Regenerate it after adding a template:

```bash
npx tsx scripts/sync-template-registry.ts --write
```

## Step 7: Validate locally

Run the local CI gate before pushing:

```bash
./scripts/local-ci.sh
```

Optionally run the smoke test for your template only:

```bash
./.github/actions/smoke-test/build.sh my-template
./.github/actions/smoke-test/test.sh my-template
```

## Step 8: Commit and release

When the local gate passes, commit your changes with a conventional commit message such as `feat: add my-template`. Open a pull request. After merge, release the template by bumping the version in `devcontainer-template.json`, tagging `my-template-v0.1.0`, and pushing the tag.

See [Releasing a Template](../how-to-guides/release-a-template.md) for the exact release workflow.
