# Compose-Based Devcontainers with Features

A `devcontainer.json` can use Docker Compose as its deployment method and still install [Dev Container Features](https://containers.dev/features) into the primary development container. The `features` object is part of the common spec and applies to whichever Compose service is named by `service`. The reference CLI implements this by generating temporary Dockerfiles and temporary Compose override files, then running `docker compose build` and `docker compose up` with those overrides.

## How `dockerComposeFile` and `service` work

A Compose-based `devcontainer.json` requires three properties:

- `dockerComposeFile` — a path, or an ordered array of paths, to Compose files relative to `devcontainer.json`. Later files override earlier ones.
- `service` — the Compose service that becomes the primary dev container; editors and the CLI connect to this service.
- `workspaceFolder` — the path inside the primary container that the editor opens.

Optional Compose-specific properties include:

- `runServices` — services that start and stop alongside the dev container. Defaults to all services if omitted.
- `shutdownAction` — `"none"` or `"stopCompose"`; defaults to `"stopCompose"`, meaning all Compose services stop when the editor disconnects.
- `overrideCommand` — whether the tool overwrites the container's default command. Defaults to `false` for Compose.

Example `devcontainer.json`:

```json
{
  "dockerComposeFile": "docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "shutdownAction": "stopCompose",
  "features": {
    "ghcr.io/devcontainers/features/github-cli": {}
  }
}
```

The corresponding Compose file usually keeps the dev service alive with a long-running command:

```yaml
services:
  devcontainer:
    image: mcr.microsoft.com/devcontainers/base:ubuntu
    volumes:
      - ..:/workspaces:cached
    command: sleep infinity
```

## Features are supported in Compose-based configurations

`features` is not Compose-specific. It belongs to the common part of the JSON schema, so any feature referenced in `devcontainer.json` is installed into the container of the selected `service`. A feature runs its `install.sh` script as root during image build and can declare its own lifecycle hooks (`onCreateCommand`, `postCreateCommand`, and so on) that run before user-defined commands in `devcontainer.json`.

### What the CLI does under the hood

The reference implementation in `devcontainers/cli` handles Compose plus Features in two phases:

1. **Build phase**: it reads the merged Compose config for the selected service. If the service has a `build` section, it uses that Dockerfile; otherwise it synthesizes a minimal `FROM <image>` Dockerfile. It then generates a `Dockerfile-with-features` by appending feature installation layers, writes a temporary build override file such as `docker-compose.devcontainer.build-<timestamp>.yml`, and runs `docker compose build` with the original files plus the override.

1. **Runtime phase**: it generates a second override file that overrides the service's image name, entrypoint, command, environment variables, labels, mounts, and GPU settings based on the installed features and `devcontainer.json`. It then runs `docker compose up -d` with both override files.

Feature installation therefore happens during image build, before the container starts.

## Role of the CLI and VS Code: extension

The Dev Container CLI is the spec's reference implementation. It reads `devcontainer.json` and creates containers from it, supporting both single containers and Docker Compose. The VS Code: Dev Containers extension follows the same model, so the behavior described here applies whether you run `devcontainer up` from the terminal or open the folder in VS Code:.

## How `build` / `dockerfile` in `devcontainer.json` interacts with Compose

The schema is mutually exclusive at the top level: a valid `devcontainer.json` is either a Compose scenario or an image/Dockerfile scenario. You cannot combine `dockerComposeFile` with the top-level `build.dockerfile` property because they belong to different scenario branches.

When using Compose, the Dockerfile reference belongs in the Compose file, not in `devcontainer.json`:

```yaml
services:
  devcontainer:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ..:/workspaces:cached
    command: sleep infinity
```

If you also declare `features` in `devcontainer.json`, the CLI reads the `build` section from the Compose service, rewrites or extends the referenced Dockerfile, and builds a new image for that service. For image-based Compose services, the CLI synthesizes a Dockerfile from `FROM <image>` and appends the feature layers, so features still work even without a `build` section.

## Limitations, gotchas, and ordering concerns

### Features apply to the primary service only

Only the service named in `service` receives feature installation. Other services in the same Compose file do not get features applied automatically. This is a documented spec-level limitation.

### Multiple `devcontainer.json` files in one Compose project

A single `docker-compose.yml` can be referenced by multiple `devcontainer.json` files, each targeting a different `service`. However, the CLI currently generates one shared runtime override file for the whole Compose project, so only the most recently processed service gets its features and lifecycle metadata applied. The other services may be rebuilt unexpectedly and end up without their features.

### Compose `build.secrets` can be dropped when Features are present

If a Compose service uses `build.secrets`, adding `features` to `devcontainer.json` may cause those secrets to be ignored during the generated build override. The current workaround is to remove features from `devcontainer.json` when Compose build secrets are required.

### Feature installation order

By default the CLI decides the order, but features can declare:

- `dependsOn` — hard dependencies that must be installed first.
- `installsAfter` — soft ordering hints.

You can override the order with `overrideFeatureInstallOrder` in `devcontainer.json`.

### Lifecycle ordering

The general lifecycle is:

1. `initializeCommand` on the host.
1. Build or create the container image. Features are installed here.
1. `onCreateCommand` inside the container.
1. `updateContentCommand` when content changes.
1. `postCreateCommand` after the container is assigned to the user.
1. `postStartCommand` each time the container starts.
1. `postAttachCommand` each time an editor attaches.

Feature-declared lifecycle hooks run in feature installation order before user-defined commands. If any lifecycle script fails, subsequent scripts do not run.

### Pre-built images and metadata labels

Pre-building is recommended for faster startup. When you pre-build with the CLI, it embeds merged metadata in the `devcontainer.metadata` image label. This label is automatically picked up when the image is referenced directly, in a Dockerfile `FROM`, or in a Compose file.

However, not every property can be stored in the image label. Non-labelable properties include `features`, `dockerComposeFile`, `service`, and `runServices`. Therefore:

- `dockerComposeFile` and `service` must stay in the local `devcontainer.json`.
- `features` must also stay in the local `devcontainer.json`; they are baked into image layers at build time, but the `features` object itself is not read from the image label.
- Runtime properties such as `postCreateCommand`, `containerEnv`, `remoteUser`, `mounts`, and `customizations` can be pre-baked into the label.

### One container per VS Code: window

Even with Compose, VS Code: can connect to only one container per window. For multiple services, open separate windows or use the `Dev Containers: Switch Container` command.

### Rebuilds are required for configuration changes

Changes to `features`, Compose build settings, or `devcontainer.json` generally require a rebuild (`Dev Containers: Rebuild Container` or `devcontainer build`) rather than a simple container restart.

## Minimal working example

`docker-compose.yml`:

```yaml
services:
  devcontainer:
    build:
      context: .
      dockerfile: Dockerfile
    volumes:
      - ..:/workspaces:cached
    command: sleep infinity

  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: postgres
```

`.devcontainer/devcontainer.json`:

```json
{
  "dockerComposeFile": "../docker-compose.yml",
  "service": "devcontainer",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "shutdownAction": "stopCompose",
  "features": {
    "ghcr.io/devcontainers/features/github-cli": {}
  },
  "postCreateCommand": "gh --version"
}
```

When opened, the CLI extends the Dockerfile with the GitHub CLI feature, builds the `devcontainer` service image, starts both `devcontainer` and `db`, and runs `gh --version` inside the primary container.
