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
    id: "ollama-claude-cli",
    name: "Ollama + Claude CLI",
    description: "Minimal devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest",
    sourcePath: "src/ollama-claude-cli",
    defaults: { imageVariant: "jammy", modelMap: "haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest" },
  },
  {
    id: "ollama-claude-cli-studio",
    name: "Ollama + Claude CLI Studio",
    description: "Full-featured devcontainer for Claude CLI with a pre-configured Ollama backend, Docker-in-Docker, NVIDIA Container Toolkit, container firewall, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-studio:latest",
    sourcePath: "src/ollama-claude-cli-studio",
    defaults: { imageVariant: "jammy", modelMap: "haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest" },
  },
  {
    id: "ollama-claude-cli-cpu",
    name: "Ollama + Claude CLI (CPU)",
    description: "CPU-only devcontainer for Claude CLI with a pre-configured Ollama backend, privacy defaults, container firewall, and persistent settings. No GPU required. Works on Apple Silicon, GitHub Codespaces, and cloud CPU instances. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli-cpu:latest",
    sourcePath: "src/ollama-claude-cli-cpu",
    defaults: { imageVariant: "jammy", modelMap: "haiku:llama3.2:latest,opus:llama3.2:latest,sonnet:llama3.2:latest,subagent:llama3.2:latest" },
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
