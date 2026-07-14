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
    id: "ollama-claude-code",
    name: "Ollama + Claude Code",
    description: "Minimal devcontainer for Claude Code with a pre-configured Ollama backend, privacy defaults, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code:latest",
    sourcePath: "src/ollama-claude-code",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-code-studio",
    name: "Ollama + Claude Code Studio",
    description: "Full-featured devcontainer for Claude Code with a pre-configured Ollama backend, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-studio:latest",
    sourcePath: "src/ollama-claude-code-studio",
    defaults: { imageVariant: "jammy" },
  },
  {
    id: "ollama-claude-code-studio-docker",
    name: "Ollama + Claude Code Studio + Docker",
    description: "Full-featured devcontainer for Claude Code with a pre-configured Ollama backend, Docker-in-Docker, lifecycle hooks, behavior rules, skills library, and persistent settings. Includes Node.js and GitHub CLI. Requires Ollama to be running on the host.",
    ghcrUri:
      "ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-code-studio-docker:latest",
    sourcePath: "src/ollama-claude-code-studio-docker",
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
