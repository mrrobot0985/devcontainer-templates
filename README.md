# Dev Container Templates

![CI - Test Templates](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container templates for Ollama-backed Claude environments.

Published namespace:

```text
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

This repository includes 8 templates:

| Template | Description | Version | README |
| -------- | ----------- | ------- | ------ |
| `cloud-native-k8s` | Devcontainer template for cloud-native development with Kubernetes. Includes kubectl, Helm, k3d, Tilt, and Docker-in-... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/cloud-native-k8s/README.md) |
| `data-engineering-spark` | Devcontainer template for data engineering with Apache Spark 3.5, Jupyter, Polars, and MinIO for lakehouse-style loca... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/data-engineering-spark/README.md) |
| `multi-ai-cli` | Devcontainer template bundling Claude Code, OpenAI Codex CLI, Google Gemini CLI, and OpenCode CLI with shared MCP ser... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/multi-ai-cli/README.md) |
| `ollama-claude-cli` | Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and p... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ollama-claude-cli/README.md) |
| `ollama-claude-cli-compose` | Devcontainer with a bundled Ollama service via Docker Compose. No host Ollama required. Includes Claude CLI, privacy ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ollama-claude-cli-compose/README.md) |
| `ollama-claude-cli-cpu` | CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ollama-claude-cli-cpu/README.md) |
| `ollama-claude-cli-python` | Devcontainer for Claude CLI with Ollama backend, Python 3.12, uv package manager, and common LLM/AI libraries pre-ins... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ollama-claude-cli-python/README.md) |
| `ollama-claude-cli-studio` | Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, NVIDIA Container To... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/ollama-claude-cli-studio/README.md) |
Install templates into any workspace with the [`create-devcontainer`](docs/reference/create-devcontainer-cli.md) npm helper:

```bash
npx @mrrobot0985/create-devcontainer <template> ./my-project
```

## Documentation

- [Tutorials](docs/tutorials/)
- [How-to guides](docs/how-to-guides/)
- [Reference](docs/reference/)
- [Explanation](docs/explanation/)

## License

MIT
