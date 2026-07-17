# Dev Container Templates

![CI - Test Templates](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container templates for AI coding agents (Claude + Ollama, Grok Build, multi-agent, and domain stacks).

Published namespace:

```text
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

This repository includes 10 templates:

| Template | Description | Version | README |
| -------- | ----------- | ------- | ------ |
| `cloud-native-k8s` | Devcontainer template for cloud-native development with Kubernetes. Includes kubectl, Helm, k3d, ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/cloud-native-k8s/README.md) |
| `data-engineering-spark` | Devcontainer template for data engineering with Apache Spark 3.5, Jupyter, Polars, and MinIO for ... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/data-engineering-spark/README.md) |
| `grok-build-cli` | Minimal devcontainer for xAI Grok Build CLI with container firewall (grok-build tags), non-root enf... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/grok-build-cli/README.md) |
| `grok-build-cli-studio` | Full-featured devcontainer for xAI Grok Build CLI with Docker-in-Docker, host isolation audit, con... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/grok-build-cli-studio/README.md) |
| `multi-ai-cli` | Devcontainer template bundling Claude Code, OpenAI Codex CLI, Google Gemini CLI, and OpenCode CLI... | ![Version](https://img.shields.io/badge/version-1.0.0-blue?style=flat-square) | [README](src/multi-ai-cli/README.md) |
| `ollama-claude-cli` | Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, conta... | ![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square) | [README](src/ollama-claude-cli/README.md) |
| `ollama-claude-cli-compose` | Devcontainer with a bundled Ollama service via Docker Compose. No host Ollama required. Includes ... | ![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square) | [README](src/ollama-claude-cli-compose/README.md) |
| `ollama-claude-cli-cpu` | CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, cont... | ![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square) | [README](src/ollama-claude-cli-cpu/README.md) |
| `ollama-claude-cli-python` | Devcontainer for Claude CLI with Ollama backend, Python 3.12, uv package manager, and common LLM/... | ![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square) | [README](src/ollama-claude-cli-python/README.md) |
| `ollama-claude-cli-studio` | Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker,... | ![Version](https://img.shields.io/badge/version-1.1.0-blue?style=flat-square) | [README](src/ollama-claude-cli-studio/README.md) |

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
