import { describe, expect, it } from "vitest";
import { TEMPLATE_LAYERS } from "../src/layers.js";
import { getTemplate, listTemplates } from "../src/templates.js";

describe("template registry", () => {
  it("lists all 15 known templates", () => {
    const ids = listTemplates().map((t) => t.id);
    expect(ids).toHaveLength(15);
    expect(ids).toContain("ollama-claude-cli");
    expect(ids).toContain("ollama-claude-cli-studio");
    expect(ids).toContain("ollama-claude-cli-cpu");
    expect(ids).toContain("ollama-claude-cli-compose");
    expect(ids).toContain("ollama-claude-cli-python");
    expect(ids).toContain("grok-build-cli");
    expect(ids).toContain("grok-build-cli-studio");
    expect(ids).toContain("pi-coding-agent");
    expect(ids).toContain("hermes-agent");
    expect(ids).toContain("codex-cli");
    expect(ids).toContain("gemini-cli");
    expect(ids).toContain("opencode-cli");
    expect(ids).toContain("multi-ai-cli");
    expect(ids).toContain("cloud-native-k8s");
    expect(ids).toContain("data-engineering-spark");
  });

  it("includes version and description for every template", () => {
    for (const t of listTemplates()) {
      expect(t.version).toMatch(/^\d+\.\d+\.\d+$/);
      expect(t.description.length).toBeGreaterThan(10);
      expect(t.name.length).toBeGreaterThan(0);
      expect(t.ghcrUri).toContain(t.id);
      expect(t.sourcePath).toBe(`src/${t.id}`);
    }
  });

  it("retrieves a template by id", () => {
    const t = getTemplate("ollama-claude-cli");
    expect(t).toBeDefined();
    expect(t?.name).toBe("Ollama + Claude CLI");
    expect(t?.version).toBe("1.1.0");
    expect(t?.defaults.imageVariant).toBe("jammy");
  });

  it("returns undefined for unknown ids", () => {
    expect(getTemplate("nonexistent")).toBeUndefined();
  });

  it("covers every registry id in Layer A/B/C/D groups", () => {
    const registryIds = new Set(listTemplates().map((t) => t.id));
    const layerIds = new Set(TEMPLATE_LAYERS.flatMap((l) => l.templateIds));
    expect(layerIds).toEqual(registryIds);
  });
});
