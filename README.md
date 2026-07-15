# Dev Container Templates

![CI - Test Templates](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/test-pr.yaml/badge.svg)
![Release](https://github.com/mrrobot0985/devcontainer-templates/actions/workflows/release.yaml/badge.svg)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)

Custom dev container templates for Ollama-backed Claude environments.

Published namespace:

```
ghcr.io/mrrobot0985/devcontainer-templates/<id>:<version>
```

This repository includes 4 templates:

| Template                   | Description                                                                                                                                                                                                               | README                                           |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------ |
| `ollama-claude-cli`        | Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings.                                                                                  | [README](src/ollama-claude-cli/README.md)        |
| `ollama-claude-cli-cpu`  | CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings. No GPU required. Works on Apple Silicon, GitHub Codespaces, and cloud CPU instances. | [README](src/ollama-claude-cli-cpu/README.md)    |
| `ollama-claude-cli-studio` | Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, NVIDIA Container Toolkit, container firewall, lifecycle hooks, behavior rules, skills library, and persistent settings. | [README](src/ollama-claude-cli-studio/README.md) |
| `ollama-claude-cli-compose` | Devcontainer with a bundled Ollama service via Docker Compose. No host Ollama required. CPU by default; GPU support available via compose file edit. | [README](src/ollama-claude-cli-compose/README.md) |

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
