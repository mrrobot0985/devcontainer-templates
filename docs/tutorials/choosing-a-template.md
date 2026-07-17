# Choosing the Right Template

This guide helps you pick the best template for your hardware, workflow, and use case.

## Layer A security floor

All five Claude + Ollama templates share the same security floor:

- Official `claude-code`
- `claude-code-backend`
- `claude-code-privacy`
- `container-firewall`
- `non-root-enforcer`

Pick a variant for **hardware and workflow**, not for basic security — that is already consistent.

## Quick Reference

| Template                    | GPU                                                  | Host Ollama | Python | Best For                                 |
| --------------------------- | ---------------------------------------------------- | ----------- | ------ | ---------------------------------------- |
| `ollama-claude-cli`         | Outer `--gpus=all`                                   | Required    | No     | Local NVIDIA workstation (minimal)       |
| `ollama-claude-cli-cpu`     | No                                                   | Required    | No     | MacBooks, Codespaces, cloud CPUs         |
| `ollama-claude-cli-compose` | Optional (compose)                                   | Bundled     | No     | Quick start without host Ollama          |
| `ollama-claude-cli-python`  | Outer `--gpus=all`                                   | Required    | Yes    | AI/ML development with Python            |
| `ollama-claude-cli-studio`  | Outer `--gpus=all` + community nvidia toolkit (DinD) | Required    | No     | Full agentic workflow + Docker-in-Docker |

## Decision Tree

### 1. Do you have a GPU?

**Yes →** Use GPU-capable templates:

- `ollama-claude-cli` for minimal setup
- `ollama-claude-cli-python` for Python + AI libraries
- `ollama-claude-cli-studio` for full agentic workflows with Docker-in-Docker and the community NVIDIA Container Toolkit (inner/DinD GPU)

**No →** Use CPU-friendly templates:

- `ollama-claude-cli-cpu` for general development
- `ollama-claude-cli-compose` for bundled Ollama (no host installation needed)
- On CPU hosts, avoid or strip `--gpus=all` if a GPU template fails to start

### 2. Is Ollama already running on your host?

**Yes →** Any non-compose template works. They connect to `host.docker.internal:11434`.

**No →** Use `ollama-claude-cli-compose`. It bundles Ollama as a Docker Compose service.

### 3. Are you doing Python AI/ML work?

**Yes →** Use `ollama-claude-cli-python`. It includes Python 3.12, the `uv` package manager, and pre-installed libraries:

- `openai`, `anthropic`, `ollama` for API clients
- `langchain`, `chromadb` for RAG and agents
- `sentence-transformers`, `numpy`, `pandas` for embeddings and data
- `jupyter`, `ipython` for interactive notebooks

The virtual environment at `/workspaces/.venv` persists across container rebuilds.

### 4. Do you need Docker inside the container?

**Yes →** Use `ollama-claude-cli-studio`. It includes Docker-in-Docker and the community NVIDIA Container Toolkit so GPU-accelerated **inner** containers can access the host GPU (when the host is configured). Outer GPU uses `--gpus=all` separately.

Studio also adds lifecycle hooks, rules, skills, audit log, and agent sandbox on top of the Layer A floor.

## Platform-Specific Guidance

### Apple Silicon (M1/M2/M3)

Use `ollama-claude-cli-cpu` or strip `--gpus=all` from Python if needed. These avoid a GPU runtime that fails on macOS. Ollama runs natively on Apple Silicon and is accessed via `host.docker.internal:11434`.

### GitHub Codespaces

Prefer `ollama-claude-cli-cpu` or `ollama-claude-cli-compose`. Codespaces typically does not provide GPU runners. Host Ollama must be reachable, or use Compose.

### Local NVIDIA Workstation

Use `ollama-claude-cli` for minimal setup or `ollama-claude-cli-studio` for full capabilities. Ensure Ollama is running on the host with GPU support:

```bash
ollama serve
```

### Cloud VM (AWS, GCP, Azure)

Use `ollama-claude-cli-cpu` for CPU instances or `ollama-claude-cli` / `ollama-claude-cli-python` for GPU instances. Install Ollama on the VM host before launching the devcontainer.

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
