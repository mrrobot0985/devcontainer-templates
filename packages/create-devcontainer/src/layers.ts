/**
 * Portfolio layers (A–D). Order is intentional; IDs match src/ template folders.
 * Keep in sync with docs/reference/template-catalog.md.
 */

/** Catalog URL for full template docs (layers, versions, features). */
export const TEMPLATE_CATALOG_URL =
  "https://github.com/mrrobot0985/devcontainer-templates/blob/main/docs/reference/template-catalog.md";

export const TEMPLATE_LAYERS: readonly {
  id: string;
  label: string;
  templateIds: readonly string[];
}[] = [
  {
    id: "A",
    label: "Layer A — Claude + Ollama",
    templateIds: [
      "ollama-claude-cli",
      "ollama-claude-cli-cpu",
      "ollama-claude-cli-compose",
      "ollama-claude-cli-python",
      "ollama-claude-cli-studio",
    ],
  },
  {
    id: "B",
    label: "Layer B — Agent entry points",
    templateIds: [
      "grok-build-cli",
      "grok-build-cli-studio",
      "pi-coding-agent",
      "hermes-agent",
      "codex-cli",
      "gemini-cli",
      "opencode-cli",
    ],
  },
  {
    id: "C",
    label: "Layer C — Multi-agent evaluation",
    templateIds: ["multi-ai-cli"],
  },
  {
    id: "D",
    label: "Layer D — Domain stacks",
    templateIds: ["cloud-native-k8s", "data-engineering-spark"],
  },
];
