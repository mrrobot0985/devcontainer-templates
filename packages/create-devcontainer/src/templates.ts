/**
 * Hard-coded registry of available devcontainer templates.
 *
 * When templates are added, removed, or renamed in src/, this file must be
 * updated to match.  The sync-check script (scripts/sync-template-registry.ts)
 * validates this automatically in CI and in the pre-commit hook.
 */

export interface Template {
  id: string;
  name: string;
  description: string;
  ghcrUri: string;
  sourcePath: string;
  defaults: Record<string, string>;
}

export const templates: readonly Template[] = [
  {
    id: "cloud-native-k8s",
    name: "Cloud Native Kubernetes",
    description: "Devcontainer template for cloud-native development with Kubernetes. Includes kubectl, Helm, k3d, Tilt, and Docker-in-Docker for building and deploying to local clusters.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/cloud-native-k8s:latest",
    sourcePath: "src/cloud-native-k8s",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "data-engineering-spark",
    name: "Data Engineering with Spark",
    description: "Devcontainer template for data engineering with Apache Spark 3.5, Jupyter, Polars, and MinIO for lakehouse-style local development",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/data-engineering-spark:latest",
    sourcePath: "src/data-engineering-spark",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "grok-build-cli",
    name: "Grok Build CLI",
    description: "Minimal devcontainer for xAI Grok Build CLI with container firewall (grok-build tags), non-root enforcer, AI agent sandbox, and persistent ~/.grok state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/grok-build-cli:latest",
    sourcePath: "src/grok-build-cli",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "grok-build-cli-studio",
    name: "Grok Build CLI Studio",
    description: "Full-featured devcontainer for xAI Grok Build CLI with Docker-in-Docker, host isolation audit, container firewall (grok-build + docker), AI agent sandbox, MCP server manager, non-root enforcer, and persistent ~/.grok state. Includes Node.js and GitHub CLI. API-first — no Ollama or Claude suite features.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/grok-build-cli-studio:latest",
    sourcePath: "src/grok-build-cli-studio",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "multi-ai-cli",
    name: "Multi-AI CLI Workspace",
    description: "Layer C multi-agent evaluation workspace: Claude Code, Grok Build, Pi, Hermes, Codex, Gemini CLI, and OpenCode with agent-agnostic security floor, per-agent home volumes, and shared MCP config. Each vendor requires its own API key or login.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/multi-ai-cli:latest",
    sourcePath: "src/multi-ai-cli",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-cli",
    name: "Ollama + Claude CLI",
    description: "Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, non-root enforcer, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest",
    sourcePath: "src/ollama-claude-cli",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-cli-compose",
    name: "Ollama + Claude CLI (Compose)",
    description: "Devcontainer with a bundled Ollama service via Docker Compose. No host Ollama required. Includes Claude CLI, privacy defaults, container firewall, non-root enforcer, and persistent settings. CPU by default; GPU support available via compose file edit. Includes Node.js and GitHub CLI.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-compose:latest",
    sourcePath: "src/ollama-claude-cli-compose",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-cli-cpu",
    name: "Ollama + Claude CLI (CPU)",
    description: "CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, non-root enforcer, and persistent settings. No GPU required. Works on Apple Silicon, GitHub Codespaces, and cloud CPU instances. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-cpu:latest",
    sourcePath: "src/ollama-claude-cli-cpu",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-cli-python",
    name: "Ollama + Claude CLI + Python",
    description: "Devcontainer for Claude CLI with Ollama backend, Python 3.12, uv package manager, and common LLM/AI libraries pre-installed in a project virtual environment. Supports GPU acceleration via --gpus=all. Security floor includes privacy, container firewall, and non-root enforcer. Works on Apple Silicon (CPU fallback), Codespaces, and cloud instances. Includes Node.js and GitHub CLI.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-python:latest",
    sourcePath: "src/ollama-claude-cli-python",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-cli-studio",
    name: "Ollama + Claude CLI Studio",
    description: "Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, community NVIDIA Container Toolkit, container firewall, non-root enforcer, audit log, agent sandbox, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest",
    sourcePath: "src/ollama-claude-cli-studio",
    defaults: { imageVariant: "jammy" },
  },
];

const byId = new Map<string, Template>();
for (const t of templates) {
  byId.set(t.id, t);
}

export function getTemplate(id: string): Template | undefined {
  return byId.get(id);
}

export function listTemplates(): readonly Template[] {
  return templates;
}
