# Compose-Based Devcontainer Deployments That Still Use Features

## TL;DR

Yes — a `devcontainer.json` can use Docker Compose as its deployment method and still install [Dev Container Features](https://containers.dev/features) into the primary development container. The `features` object lives in the common part of the spec and applies to whichever service is named by `service`. The reference CLI implements this by generating temporary Dockerfiles and temporary Docker Compose override files, then running `docker compose build` / `docker compose up` with those overrides.

---

## 1. How `dockerComposeFile` and `service` work

In a Docker Compose devcontainer, three properties are required in `devcontainer.json`:

- `dockerComposeFile` — a path, or an ordered array of paths, to Compose files relative to `devcontainer.json`. Later files override earlier ones ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).
- `service` — the Compose service name that is the primary dev container; editors and the CLI connect to this service ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).
- `workspaceFolder` — the path inside the primary container that the editor opens ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).

Optional Compose-specific properties include:

- `runServices` — services that should be started/stopped alongside the dev container. Defaults to all services if omitted ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).
- `shutdownAction` — `"none"` or `"stopCompose"`; defaults to `"stopCompose"` for Compose, meaning all Compose services are stopped when the editor disconnects ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).
- `overrideCommand` — whether the tool overwrites the container’s default command. Defaults to `false` for Compose and `true` for single-container scenarios ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).

Example:

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

([Using Images, Dockerfiles, and Docker Compose](https://containers.dev/guide/dockerfile))

---

## 2. Features are supported in Compose-based configurations

`features` is not Compose-specific; it is part of the `devContainerCommon` definition in the JSON schema, which is combined with the `composeContainer` definition ([`devContainer.base.schema.json`](https://github.com/devcontainers/spec/blob/main/schemas/devContainer.base.schema.json)). This means any feature referenced in `devcontainer.json` is installed into the container of the selected `service`.

> `features` — “An object of Dev Container Feature IDs and related options to be added into your primary container.” ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/))

A Feature is installed as root during the image build by running its `install.sh` script, and it can declare its own lifecycle hooks (`onCreateCommand`, `postCreateCommand`, etc.) that run before the user-defined commands in `devcontainer.json` ([devcontainer-features.md](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md)).

### 2.1 What the CLI does under the hood

The reference implementation in [`devcontainers/cli`](https://github.com/devcontainers/cli) handles Compose + Features in two phases:

1. **Build phase** (`buildAndExtendDockerCompose` in [`src/spec-node/dockerCompose.ts`](https://github.com/devcontainers/cli/blob/main/src/spec-node/dockerCompose.ts)):
   - Reads the merged Compose config for the selected service.
   - If the service has a `build` section, it uses that Dockerfile; otherwise it synthesises a minimal `FROM <image>` Dockerfile.
   - Generates a `Dockerfile-with-features` by concatenating the original Dockerfile with Feature installation layers produced by `getFeaturesBuildOptions` in [`src/spec-node/containerFeatures.ts`](https://github.com/devcontainers/cli/blob/main/src/spec-node/containerFeatures.ts).
   - Writes a temporary build override file such as `docker-compose.devcontainer.build-<timestamp>.yml` that points the service to the generated Dockerfile, passes build args like `_DEV_CONTAINERS_BASE_IMAGE`, and adds `cache_from` if configured.
   - Runs `docker compose build` with the original files plus the override.

2. **Runtime phase** (`startContainer` in [`src/spec-node/dockerCompose.ts`](https://github.com/devcontainers/cli/blob/main/src/spec-node/dockerCompose.ts)):
   - Generates a second override file (`docker-compose.devcontainer.containerFeatures-*.yml`) that overrides the service’s image name, entrypoint, command, environment variables, labels, mounts, and GPU settings based on the installed Features and `devcontainer.json`.
   - Runs `docker compose up -d` with both override files.

This means Feature installation happens **during image build**, before the container is started — not while the Compose service is already running.

---

## 3. Role of the CLI and VS Code extension

- The [Dev Container CLI](https://github.com/devcontainers/cli) is the spec’s reference implementation. It reads `devcontainer.json` and creates/containers from it, supporting both single containers and Docker Compose ([Reference Implementation](https://containers.dev/implementors/reference/)).
- The VS Code Dev Containers extension uses the same model. Its docs describe the same `dockerComposeFile` + `service` + `workspaceFolder` pattern and explicitly show adding Features via the `features` property ([Create a Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container)).
- The extension also lets you set “always installed” Features via the `dev.containers.defaultFeatures` user setting ([Developing inside a Container](https://code.visualstudio.com/docs/devcontainers/containers)).

Because both the CLI and the extension ultimately apply the same spec, the behavior described here applies whether you run `devcontainer up` from the terminal or open the folder in VS Code.

---

## 4. How `build` / `dockerfile` in `devcontainer.json` interacts with Compose

The schema is mutually exclusive at the top level: a valid `devcontainer.json` is either a Compose scenario (`composeContainer` + `devContainerCommon`) or an image/Dockerfile scenario (`dockerfileContainer`/`imageContainer` + `nonComposeBase` + `devContainerCommon`). You cannot combine `dockerComposeFile` with the top-level `build.dockerfile` property because they belong to different scenario branches ([`devContainer.base.schema.json`](https://github.com/devcontainers/spec/blob/main/schemas/devContainer.base.schema.json)).

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

([Using Images, Dockerfiles, and Docker Compose](https://containers.dev/guide/dockerfile))

If you also declare `features` in `devcontainer.json`, the CLI will read the `build` section from the Compose service, rewrite/extend the referenced Dockerfile, and build a new image for that service.

For image-based Compose services, the CLI synthesises a Dockerfile from `FROM <image>` and appends the Feature layers, so Features still work even when the service does not define a `build` section.

---

## 5. Limitations, gotchas, and ordering concerns

### 5.1 Features apply to the primary service only

Only the service named in `service` receives the Feature treatment. Other services defined in the same Compose file do not get their own `devcontainer.json` Features applied automatically. This is a documented spec-level limitation ([devcontainers/spec#546](https://github.com/devcontainers/spec/issues/546)).

### 5.2 Multiple `devcontainer.json` files in one Compose project

A single `docker-compose.yml` can be referenced by multiple `devcontainer.json` files, each targeting a different `service`. However, the CLI currently generates **one shared runtime override file** for the whole Compose project, so only the most recently processed service gets its Features and lifecycle metadata applied. The other service(s) may be rebuilt unexpectedly and end up without their Features ([devcontainers/cli#1211](https://github.com/devcontainers/cli/issues/1211)).

### 5.3 Compose `build.secrets` can be dropped when Features are present

If a Compose service uses `build.secrets`, adding `features` to `devcontainer.json` may cause those secrets to be ignored during the generated build override, producing errors such as `failed to solve: unexpected key 'env' in 'env=SOME_SECRET'`. The current workaround is to remove Features from `devcontainer.json` when Compose build secrets are required ([devcontainers/cli#997](https://github.com/devcontainers/cli/issues/997)).

### 5.4 Feature installation order

By default the CLI decides the order, but Features can declare:

- `dependsOn` — hard dependencies that must be installed first.
- `installsAfter` — soft ordering hints.

You can override the order with `overrideFeatureInstallOrder` in `devcontainer.json`, which lists Feature IDs in the desired priority order while still respecting dependencies ([devcontainer-features.md](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md)).

### 5.5 Lifecycle ordering

The general lifecycle is:

1. `initializeCommand` on the host.
2. Build/create the container image (Features are installed here).
3. `onCreateCommand` inside the container.
4. `updateContentCommand` when content changes.
5. `postCreateCommand` after the container is assigned to the user.
6. `postStartCommand` each time the container starts.
7. `postAttachCommand` each time an editor attaches.

Feature-declared lifecycle hooks run in Feature installation order before user-defined commands ([devcontainer-features.md](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md)). If any lifecycle script fails, subsequent scripts do not run ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).

### 5.6 Pre-built images and metadata labels

Pre-building is recommended for faster startup. When you pre-build with the CLI, it embeds merged metadata in the `devcontainer.metadata` image label. This label is automatically picked up when the image is referenced directly, in a Dockerfile `FROM`, or in a Compose file ([Reference Implementation](https://containers.dev/implementors/reference/)).

However, **not every property can be stored in the image label**. The metadata reference marks labelable properties with a 🏷️. Properties that are *not* labelable include `features`, `dockerComposeFile`, `service`, and `runServices` ([Dev Container metadata reference](https://containers.dev/implementors/json_reference/)).

Therefore:

- `dockerComposeFile` + `service` must stay in the local `devcontainer.json`.
- `features` must also stay in the local `devcontainer.json`; they are baked into the image layers at build time, but the `features` object itself is not read from the image label.
- Runtime properties such as `postCreateCommand`, `containerEnv`, `remoteUser`, `mounts`, and `customizations` can be pre-baked into the label.

### 5.7 One container per VS Code window

Even with Compose, VS Code can connect to only one container per window. For multiple services, open separate windows or use the “Dev Containers: Switch Container” command ([Connect to multiple containers](https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers)).

### 5.8 Rebuilds are required for configuration changes

Changes to `features`, Compose build settings, or `devcontainer.json` generally require a rebuild (`Dev Containers: Rebuild Container` or `devcontainer build`) rather than a simple container restart ([Create a Dev Container](https://code.visualstudio.com/docs/devcontainers/create-dev-container)).

---

## 6. Relevant spec/schema references

- [Dev Container metadata reference](https://containers.dev/implementors/json_reference/) — canonical descriptions of `dockerComposeFile`, `service`, `runServices`, `workspaceFolder`, `shutdownAction`, `overrideCommand`, `features`, `build.dockerfile`, and lifecycle scripts.
- [devcontainer.json schema](https://containers.dev/implementors/json_schema/) — links to the formal schemas on GitHub.
- [`devContainer.base.schema.json`](https://github.com/devcontainers/spec/blob/main/schemas/devContainer.base.schema.json) — defines `devContainerCommon`, `composeContainer`, `dockerfileContainer`, `imageContainer`, `nonComposeBase`, and `buildOptions`.
- [`devContainer.schema.json`](https://github.com/devcontainers/spec/blob/main/schemas/devContainer.schema.json) — the top-level schema.
- [Development Container Specification overview](https://containers.dev/implementors/spec/) — high-level spec.
- [Dev Container Features spec](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md) — Feature installation, ordering, and lifecycle hooks.
- [Dev Container reference docs](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-reference.md) — orchestration options, config merging, lifecycle, and metadata labels.

---

## 7. Minimal working example

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

When opened, the CLI will extend the Dockerfile with the GitHub CLI Feature, build the `devcontainer` service image, start both `devcontainer` and `db`, and run `gh --version` inside the primary container.

---

## Sources

- <https://containers.dev/implementors/json_reference/>
- <https://containers.dev/implementors/json_schema/>
- <https://containers.dev/implementors/spec/>
- <https://containers.dev/implementors/reference/>
- <https://containers.dev/guide/dockerfile>
- <https://containers.dev/features>
- <https://github.com/devcontainers/spec/blob/main/schemas/devContainer.base.schema.json>
- <https://github.com/devcontainers/spec/blob/main/schemas/devContainer.schema.json>
- <https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-features.md>
- <https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-reference.md>
- <https://github.com/devcontainers/cli/blob/main/src/spec-node/dockerCompose.ts>
- <https://github.com/devcontainers/cli/blob/main/src/spec-node/containerFeatures.ts>
- <https://github.com/devcontainers/spec/issues/546>
- <https://github.com/devcontainers/cli/issues/1211>
- <https://github.com/devcontainers/cli/issues/997>
- <https://code.visualstudio.com/docs/devcontainers/create-dev-container>
- <https://code.visualstudio.com/docs/devcontainers/containers>
- <https://code.visualstudio.com/remote/advancedcontainers/connect-multiple-containers>
- <https://docs.docker.com/reference/compose-file/build/>
- <https://compose-spec.github.io/compose-spec/build.html>
