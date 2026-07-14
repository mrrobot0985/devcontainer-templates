import { describe, expect, it } from "vitest";
import { mkdtempSync, readFileSync, writeFileSync, mkdirSync, existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { applyTemplate } from "../src/apply.js";
import type { Template } from "../src/templates.js";

const fakeTemplate: Template = {
  id: "test-template",
  name: "Test Template",
  description: "A test template.",
  ghcrUri: "ghcr.io/example/test:1",
  sourcePath: "test/fixtures/test-template",
  defaults: { imageVariant: "jammy" },
};

describe("applyTemplate", () => {
  it("refuses to overwrite an existing .devcontainer without --force", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    mkdirSync(join(tmp, ".devcontainer"), { recursive: true });
    writeFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "{}");

    expect(() =>
      applyTemplate(fakeTemplate, { targetDir: tmp, force: false, mode: "dev" })
    ).toThrow("Refusing to overwrite");
  });

  it("throws when the source directory is missing in dev mode", () => {
    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));

    expect(() =>
      applyTemplate(fakeTemplate, { targetDir: tmp, force: false, mode: "dev" })
    ).toThrow("Template source directory not found");
  });

  it("copies files and substitutes options in dev mode", () => {
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template");
    mkdirSync(fixtureDir, { recursive: true });
    writeFileSync(
      join(fixtureDir, "devcontainer.json"),
      '{"image": "base:${templateOption:imageVariant}"}'
    );

    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    const template: Template = {
      ...fakeTemplate,
      sourcePath: "test/fixtures/test-template",
    };

    applyTemplate(template, { targetDir: tmp, force: false, mode: "dev" });

    const result = readFileSync(join(tmp, "devcontainer.json"), "utf-8");
    expect(result).toBe('{"image": "base:jammy"}');
  });
});
