# Adding NVIDIA GPU Support

GPU access in these templates has two separate layers. Do not confuse them.

| Layer | Mechanism | Purpose |
| ----- | --------- | ------- |
| Outer container | `runArgs: ["--gpus=all"]` | Host GPU devices visible **inside** the devcontainer |
| Inner containers (DinD) | NVIDIA Container Toolkit **feature** | Toolkit packages so nested `docker run --gpus ...` works |

## Outer GPU passthrough (`--gpus=all`)

These templates already pass host GPUs into the outer container:

- `ollama-claude-cli`
- `ollama-claude-cli-python`
- `ollama-claude-cli-studio`

CPU / Compose variants omit this (or enable GPU only via compose edits).

Host requirements:

- NVIDIA driver on the host
- Host Docker configured with the NVIDIA Container Toolkit
- Machine actually has a GPU (otherwise drop `--gpus=all` if create fails)

Verify:

```bash
nvidia-smi
```

## When to add the NVIDIA Container Toolkit feature

Add the **community** toolkit feature when you need:

- GPU access inside Docker-in-Docker containers
- CUDA tools or model servers in **inner** containers
- The `nvidia` runtime available to nested Docker

The in-house `ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit` feature was **removed**. Use the community feature instead:

```json
"ghcr.io/srzstephen/devcontainer-features/nvidia-container-toolkit:1": {}
```

Notes:

- The community feature always installs toolkit packages (option is only `version`; there is **no** `enable: false`).
- Official `ghcr.io/devcontainers/features/nvidia-cuda` installs CUDA **inside** the image and is **not** a drop-in for DinD toolkit setup.

## Studio template (already wired)

`ollama-claude-cli-studio` already includes:

1. Outer: `"--gpus=all"` in `runArgs`
2. Inner: `"ghcr.io/srzstephen/devcontainer-features/nvidia-container-toolkit:1": {}`
3. Docker-in-Docker

No extra enable flag is required for the community feature.

## Add the feature to any other template

Paste into the `features` object of `.devcontainer/devcontainer.json`:

```json
"features": {
  "ghcr.io/srzstephen/devcontainer-features/nvidia-container-toolkit:1": {
    "version": "latest"
  }
}
```

## GPU passthrough with Docker-in-Docker

With the studio template (or after adding DinD + the community toolkit), nested containers can request GPUs:

```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

If the host or inner runtime is not configured, this will fail even when outer `nvidia-smi` works.

## Troubleshooting

If GPU access fails, confirm:

- The host has a working NVIDIA driver (`nvidia-smi` on the host).
- Docker on the host is configured with the NVIDIA Container Toolkit.
- The devcontainer was rebuilt after changing features or `runArgs`.
- On Apple Silicon / CPU-only hosts, omit `--gpus=all` and use `ollama-claude-cli-cpu` or the Compose template.
