import { describe, expect, it } from "vitest";
import { getTemplate, listTemplates } from "../src/templates.js";

describe("template registry", () => {
  it("lists all known templates", () => {
    const ids = listTemplates().map((t) => t.id);
    expect(ids).toContain("ollama-claude-code");
    expect(ids).toContain("ollama-claude-code-studio");
    expect(ids).toContain("ollama-claude-code-studio-docker");
  });

  it("retrieves a template by id", () => {
    const t = getTemplate("ollama-claude-code");
    expect(t).toBeDefined();
    expect(t?.name).toBe("Ollama + Claude Code");
    expect(t?.defaults.imageVariant).toBe("jammy");
  });

  it("returns undefined for unknown ids", () => {
    expect(getTemplate("nonexistent")).toBeUndefined();
  });
});
