/**
 * Cheap static consumer-path gate: apply every registry template from the
 * bundled path, parse the generated devcontainer.json, and assert floor
 * feature keys + canonical mount stems (Layer A–D policy markers).
 *
 * Wired into existing `npm test` / create-devcontainer CI — no second workflow.
 */
import { execSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { applyTemplate } from "../src/apply.js";
import { TEMPLATE_LAYERS } from "../src/layers.js";
import { listTemplates, type Template } from "../src/templates.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const pkgDir = join(__dirname, "..");

/** Owned security floor feature id markers (paths must contain these). */
const FLOOR_FEATURE_MARKERS = [
  "non-root-enforcer:1",
  "container-firewall:1",
  "ai-agent-sandbox:1",
] as const;

type MountExpectation = { sourcePrefix: string; target: string };

/** Layer A: historical Claude config volume stem. */
const LAYER_A_MOUNT: MountExpectation = {
  sourcePrefix: "claude-cli-config-",
  target: "/home/vscode/.claude",
};

/**
 * Layer B canonical mounts (naming-schema-guide / templates#85 children).
 * OpenCode uses community feature host binds (no template named volumes).
 */
const LAYER_B_MOUNTS: Record<string, MountExpectation[]> = {
  "codex-cli": [
    { sourcePrefix: "codex-cli-home-", target: "/home/vscode/.codex" },
  ],
  "gemini-cli": [
    { sourcePrefix: "gemini-cli-home-", target: "/home/vscode/.gemini" },
  ],
  "grok-build-cli": [
    { sourcePrefix: "grok-build-cli-home-", target: "/home/vscode/.grok" },
  ],
  "grok-build-cli-studio": [
    {
      sourcePrefix: "grok-build-cli-studio-home-",
      target: "/home/vscode/.grok",
    },
  ],
  "hermes-agent": [
    { sourcePrefix: "hermes-agent-home-", target: "/home/vscode/.hermes" },
  ],
  "pi-coding-agent": [
    { sourcePrefix: "pi-coding-agent-home-", target: "/home/vscode/.pi" },
  ],
  // OpenCode: community feature uses host binds + onCreate symlinks;
  // named volumes on home paths break smoke (see persistence-model.md).
  "opencode-cli": [],
};

/** Layer C: multi-ai-* prefixes for every agent home + shared MCP. */
const MULTI_AI_MOUNTS: MountExpectation[] = [
  { sourcePrefix: "multi-ai-claude-", target: "/home/vscode/.claude" },
  { sourcePrefix: "multi-ai-grok-", target: "/home/vscode/.grok" },
  { sourcePrefix: "multi-ai-pi-", target: "/home/vscode/.pi" },
  { sourcePrefix: "multi-ai-hermes-", target: "/home/vscode/.hermes" },
  { sourcePrefix: "multi-ai-codex-", target: "/home/vscode/.codex" },
  { sourcePrefix: "multi-ai-gemini-", target: "/home/vscode/.gemini" },
  // OpenCode homes via community feature host binds (not named volumes)
  { sourcePrefix: "multi-ai-mcp-", target: "/home/vscode/.mcp" },
];

function layerOf(templateId: string): string {
  for (const layer of TEMPLATE_LAYERS) {
    if ((layer.templateIds as readonly string[]).includes(templateId)) {
      return layer.id;
    }
  }
  throw new Error(`Template "${templateId}" is not assigned to TEMPLATE_LAYERS`);
}

function featureKeysContain(featureKeys: string[], marker: string): boolean {
  return featureKeys.some((key) => key.includes(marker));
}

function parseDevcontainer(targetDir: string): Record<string, unknown> {
  const path = join(targetDir, ".devcontainer", "devcontainer.json");
  expect(existsSync(path), `missing ${path}`).toBe(true);
  return JSON.parse(readFileSync(path, "utf-8")) as Record<string, unknown>;
}

function assertMounts(mounts: string[], expected: MountExpectation[]): void {
  for (const exp of expected) {
    const hit = mounts.find(
      (m) =>
        m.includes(`source=${exp.sourcePrefix}`) &&
        m.includes(`target=${exp.target}`)
    );
    expect(
      hit,
      `expected mount source=${exp.sourcePrefix}* target=${exp.target}; got: ${JSON.stringify(mounts)}`
    ).toBeDefined();
  }
}

describe("apply all templates (floor + mount policy)", () => {
  const temps: string[] = [];

  beforeAll(() => {
    // Consumer path applies from packages/.../templates/; keep that tree in
    // sync with src/ so local runs match CI (where templates/ is not checked in).
    execSync("node scripts/copy-templates.js", {
      cwd: pkgDir,
      stdio: "pipe",
    });
  });

  afterEach(() => {
    while (temps.length > 0) {
      const dir = temps.pop();
      if (dir) {
        rmSync(dir, { recursive: true, force: true });
      }
    }
  });

  const templates = listTemplates();

  it("covers all 15 registry templates", () => {
    expect(templates).toHaveLength(15);
  });

  it.each(templates.map((t) => [t.id, t] as const))(
    "applies %s with floor/mount policy markers",
    (_id, template: Template) => {
      const id = template.id;
      const tmp = mkdtempSync(join(tmpdir(), `apply-all-${id}-`));
      temps.push(tmp);

      applyTemplate(template, {
        targetDir: tmp,
        force: false,
        mode: "bundled",
      });

      const config = parseDevcontainer(tmp);
      const features = (config.features ?? {}) as Record<string, unknown>;
      const featureKeys = Object.keys(features);
      const mounts = Array.isArray(config.mounts)
        ? (config.mounts as string[])
        : [];
      const layer = layerOf(id);

      // remoteUser is non-root (vscode) when set
      if (config.remoteUser !== undefined) {
        expect(config.remoteUser).not.toBe("root");
        expect(config.remoteUser).toBe("vscode");
      }

      // Floor feature keys: Layer B/C/D always; Layer A after floor + sandbox work
      for (const marker of FLOOR_FEATURE_MARKERS) {
        expect(
          featureKeysContain(featureKeys, marker),
          `${id} (Layer ${layer}) missing floor feature containing "${marker}". keys=${JSON.stringify(featureKeys)}`
        ).toBe(true);
      }

      if (layer === "A") {
        assertMounts(mounts, [LAYER_A_MOUNT]);
      } else if (layer === "B") {
        const expected = LAYER_B_MOUNTS[id];
        expect(expected, `missing Layer B mount policy for ${id}`).toBeDefined();
        assertMounts(mounts, expected);
        if (id === "opencode-cli") {
          for (const m of mounts) {
            expect(
              m,
              `opencode-cli must not use named volumes on OpenCode homes (community feature binds): ${m}`
            ).not.toMatch(/opencode-cli-(data|config)-/);
          }
        }
      } else if (layer === "C") {
        assertMounts(mounts, MULTI_AI_MOUNTS);
        for (const m of mounts) {
          expect(
            m,
            `Layer C mount must use multi-ai-* source prefix: ${m}`
          ).toMatch(/source=multi-ai-/);
        }
      }
      // Layer D: domain stacks — floor only; no agent home mounts required
    }
  );
});
