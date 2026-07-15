import { describe, expect, it } from "vitest";
import { getTemplate, listTemplates } from "../src/templates.js";

describe("template registry", () => {
  it("lists all known templates", () => {
    const ids = listTemplates().map((t) => t.id);
    expect(ids).toContain("ollama-claude-cli");
    expect(ids).toContain("ollama-claude-cli-studio");
    expect(ids).toContain("ollama-claude-sandcastle-studio");
  });

  it("retrieves a template by id", () => {
    const t = getTemplate("ollama-claude-cli");
    expect(t).toBeDefined();
    expect(t?.name).toBe("Ollama + Claude CLI");
    expect(t?.defaults.imageVariant).toBe("jammy");
  });

  it("retrieves the sandcastle studio template", () => {
    const t = getTemplate("ollama-claude-sandcastle-studio");
    expect(t).toBeDefined();
    expect(t?.name).toBe("Ollama + Claude CLI + Sandcastle Studio");
    expect(t?.sourcePath).toBe("src/ollama-claude-sandcastle-studio");
  });

  it("returns undefined for unknown ids", () => {
    expect(getTemplate("nonexistent")).toBeUndefined();
  });
});
