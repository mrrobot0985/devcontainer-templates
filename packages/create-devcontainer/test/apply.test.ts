import { describe, expect, it } from "vitest";
import { mkdtempSync, readFileSync, writeFileSync, mkdirSync, existsSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { applyTemplate } from "../src/apply.js";
import type { Template } from "../src/templates.js";

const fakeTemplate: Template = {
  id: "test-template",
  name: "Test Template",
  description: "A test template.",
  version: "0.0.0",
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
    // Clean up any fixture created by other tests so this test is deterministic
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template");
    if (existsSync(fixtureDir)) {
      rmSync(fixtureDir, { recursive: true, force: true });
    }

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

  it("overrides devcontainer name when --name is provided", () => {
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template-name");
    mkdirSync(join(fixtureDir, ".devcontainer"), { recursive: true });
    writeFileSync(
      join(fixtureDir, ".devcontainer", "devcontainer.json"),
      '{"name": "Default Name", "image": "base:${templateOption:imageVariant}"}'
    );

    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    const template: Template = {
      ...fakeTemplate,
      sourcePath: "test/fixtures/test-template-name",
    };

    applyTemplate(template, {
      targetDir: tmp,
      force: false,
      mode: "dev",
      name: "Custom Name",
    });

    const result = JSON.parse(
      readFileSync(join(tmp, ".devcontainer", "devcontainer.json"), "utf-8")
    ) as Record<string, unknown>;
    expect(result.name).toBe("Custom Name");
    expect(result.image).toBe("base:jammy");
  });

  it("creates a README.md skeleton when --readme is provided", () => {
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template-readme");
    mkdirSync(join(fixtureDir, ".devcontainer"), { recursive: true });
    writeFileSync(
      join(fixtureDir, ".devcontainer", "devcontainer.json"),
      '{"image": "base:${templateOption:imageVariant}"}'
    );

    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    const template: Template = {
      ...fakeTemplate,
      sourcePath: "test/fixtures/test-template-readme",
    };

    applyTemplate(template, {
      targetDir: tmp,
      force: false,
      mode: "dev",
      readme: true,
    });

    const readme = readFileSync(join(tmp, "README.md"), "utf-8");
    expect(readme.startsWith("# Test Template")).toBe(true);
  });

  it("uses --name as README title when both --readme and --name are provided", () => {
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template-readme-name");
    mkdirSync(join(fixtureDir, ".devcontainer"), { recursive: true });
    writeFileSync(
      join(fixtureDir, ".devcontainer", "devcontainer.json"),
      '{"image": "base:${templateOption:imageVariant}"}'
    );

    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    const template: Template = {
      ...fakeTemplate,
      sourcePath: "test/fixtures/test-template-readme-name",
    };

    applyTemplate(template, {
      targetDir: tmp,
      force: false,
      mode: "dev",
      name: "My Project",
      readme: true,
    });

    const readme = readFileSync(join(tmp, "README.md"), "utf-8");
    expect(readme.startsWith("# My Project")).toBe(true);
  });

  it("does not copy template README.md when --readme is not provided", () => {
    const repoRoot = new URL("../../../", import.meta.url).pathname;
    const fixtureDir = join(repoRoot, "test", "fixtures", "test-template-no-readme");
    mkdirSync(join(fixtureDir, ".devcontainer"), { recursive: true });
    writeFileSync(
      join(fixtureDir, ".devcontainer", "devcontainer.json"),
      '{"image": "base:${templateOption:imageVariant}"}'
    );
    writeFileSync(
      join(fixtureDir, "README.md"),
      "# Template README\nThis should not be copied."
    );

    const tmp = mkdtempSync(join(tmpdir(), "create-devcontainer-"));
    const template: Template = {
      ...fakeTemplate,
      sourcePath: "test/fixtures/test-template-no-readme",
    };

    applyTemplate(template, {
      targetDir: tmp,
      force: false,
      mode: "dev",
    });

    expect(existsSync(join(tmp, "README.md"))).toBe(false);
  });
});
