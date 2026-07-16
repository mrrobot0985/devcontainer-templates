# Choosing the Right Template

This guide helps you pick the best template for your hardware, workflow, and use case.

## Quick Reference

| Template                    | GPU      | Host Ollama | Python | Best For                                    |
| --------------------------- | -------- | ----------- | ------ | ------------------------------------------- |
| `ollama-claude-cli`         | Required | Required    | No     | Local GPU workstation                       |
| `ollama-claude-cli-cpu`     | No       | Required    | No     | MacBooks, Codespaces, cloud CPUs            |
| `ollama-claude-cli-compose` | Optional | Bundled     | No     | Quick start without host setup              |
| `ollama-claude-cli-python`  | No       | Required    | Yes    | AI/ML development with Python               |
| `ollama-claude-cli-studio`  | Required | Required    | No     | Full agentic workflow with Docker-in-Docker |

## Decision Tree

### 1. Do you have a GPU?

**Yes →** Use the GPU-capable templates:

- `ollama-claude-cli` for minimal setup
- `ollama-claude-cli-studio` for full agentic workflows with Docker-in-Docker and NVIDIA Container Toolkit

**No →** Use CPU-only templates:

- `ollama-claude-cli-cpu` for general development
- `ollama-claude-cli-python` for AI/ML Python work
- `ollama-claude-cli-compose` for bundled Ollama (no host installation needed)

### 2. Is Ollama already running on your host?

**Yes →** Any template works. The CPU and GPU templates connect to `host.docker.internal:11434`.

**No →** Use `ollama-claude-cli-compose`. It bundles Ollama as a Docker Compose service, so no host installation is required.

### 3. Are you doing Python AI/ML work?

**Yes →** Use `ollama-claude-cli-python`. It includes Python 3.12, the `uv` package manager, and pre-installed libraries:

- `openai`, `anthropic`, `ollama` for API clients
- `langchain`, `chromadb` for RAG and agents
- `sentence-transformers`, `numpy`, `pandas` for embeddings and data
- `jupyter`, `ipython` for interactive notebooks

The virtual environment at `/workspaces/.venv` persists across container rebuilds.

### 4. Do you need Docker inside the container?

**Yes →** Use `ollama-claude-cli-studio`. It includes Docker-in-Docker and the NVIDIA Container Toolkit so GPU-accelerated inner containers can access the host GPU.

## Platform-Specific Guidance

### Apple Silicon (M1/M2/M3)

Use `ollama-claude-cli-cpu` or `ollama-claude-cli-python`. These omit the `--gpus=all` flag that fails on macOS. Ollama runs natively on Apple Silicon and is accessed via `host.docker.internal:11434`.

### GitHub Codespaces

Use `ollama-claude-cli-cpu` or `ollama-claude-cli-python`. Codespaces does not provide GPU runners. Ollama must be running on a reachable host or use the Compose template with port forwarding.

### Local NVIDIA Workstation

Use `ollama-claude-cli` for minimal setup or `ollama-claude-cli-studio` for full capabilities. Ensure Ollama is running on the host with GPU support:

```bash
ollama serve
```

### Cloud VM (AWS, GCP, Azure)

Use `ollama-claude-cli-cpu` for CPU instances or `ollama-claude-cli` for GPU instances. Install Ollama on the VM host before launching the devcontainer.

## Next Steps

After choosing a template, apply it:

```bash
npx @mrrobot0985/create-devcontainer <template> ./my-project
cd ./my-project
code .
```

Or with the Dev Container CLI:

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/<template>:latest
```
