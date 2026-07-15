# Adding NVIDIA GPU Support

Both templates enable GPU passthrough for the outer container via `--gpus=all` in `runArgs`. If your workflow also runs CUDA workloads inside containers that are launched from within the devcontainer, add the NVIDIA Container Toolkit feature.

## When to add the NVIDIA Container Toolkit feature

Add it when you need:

- GPU access inside a Docker-in-Docker container.
- CUDA-enabled tools or model servers running in inner containers.
- The `nvidia` runtime to be the default for inner `docker run` calls.

The `ollama-claude-cli-studio` template already bundles `nvidia-container-toolkit`, but leaves it disabled by default. The minimal `ollama-claude-cli` template does not include it.

## Enable the bundled feature in the studio template

In `src/ollama-claude-cli-studio/.devcontainer/devcontainer.json`, change:

```json
"ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0": {
  "enable": false,
  "defaultRuntime": false,
  "restartDockerd": true
}
```

to:

```json
"ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0": {
  "enable": true,
  "defaultRuntime": true,
  "restartDockerd": true
}
```

## Add the feature to any template

Paste the feature into the `features` object of `.devcontainer/devcontainer.json`:

```json
"features": {
  "ghcr.io/mrrobot0985/devcontainer-features/nvidia-container-toolkit:0": {
    "enable": true
  }
}
```

## What each option does

| Option | Default | Effect |
| ------ | ------- | ------ |
| `enable` | `false` | Installs and configures the NVIDIA Container Toolkit inside the devcontainer. |
| `defaultRuntime` | `false` | Sets `nvidia` as the default Docker runtime so `docker run` uses GPUs without `--runtime=nvidia`. |
| `restartDockerd` | `true` | Restarts the inner Docker daemon after changing the runtime configuration. |

## GPU passthrough with Docker-in-Docker

The studio template includes Docker-in-Docker. With the toolkit enabled and `defaultRuntime: true`, containers launched from inside the devcontainer inherit GPU access. For example:

```bash
docker run --rm --gpus all nvidia/cuda:12.0-base nvidia-smi
```

If `defaultRuntime` is left `false`, pass `--runtime=nvidia` explicitly:

```bash
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.0-base nvidia-smi
```

## Verify GPU access inside the container

After rebuilding, run:

```bash
nvidia-smi
```

If the command is not found or fails, confirm:

- The host has a working NVIDIA driver.
- Docker on the host is configured with the NVIDIA Container Toolkit.
- The devcontainer was rebuilt after enabling the feature.
