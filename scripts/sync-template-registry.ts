#!/usr/bin/env tsx
/**
 * sync-template-registry.ts
 *
 * Compares the template directories under src/ with the hard-coded registry
 * in packages/create-devcontainer/src/templates.ts.
 *
 * Usage:
 *   npx tsx scripts/sync-template-registry.ts          # validate (exit 1 on drift)
 *   npx tsx scripts/sync-template-registry.ts --write  # regenerate the registry
 */

import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join, relative } from "node:path";

const REPO_ROOT = new URL("..", import.meta.url).pathname;
const SRC_DIR = join(REPO_ROOT, "src");
const REGISTRY_PATH = join(
  REPO_ROOT,
  "packages",
  "create-devcontainer",
  "src",
  "templates.ts"
);

interface TemplateMeta {
  id: string;
  name: string;
  description: string;
  version?: string;
  options?: Record<string, { type: string; default?: unknown }>;
}

function discoverTemplates(): TemplateMeta[] {
  const entries = readdirSync(SRC_DIR, { withFileTypes: true });
  const templates: TemplateMeta[] = [];

  for (const entry of entries) {
    if (!entry.isDirectory()) continue;
    const jsonPath = join(SRC_DIR, entry.name, "devcontainer-template.json");
    try {
      const raw = readFileSync(jsonPath, "utf-8");
      const data = JSON.parse(raw) as TemplateMeta;
      templates.push(data);
    } catch {
      // Skip directories without a valid devcontainer-template.json
    }
  }

  templates.sort((a, b) => a.id.localeCompare(b.id));
  return templates;
}

function generateRegistry(templates: TemplateMeta[]): string {
  const lines: string[] = [];
  lines.push(`/**
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
  version: string;
  ghcrUri: string;
  sourcePath: string;
  defaults: Record<string, string>;
}

export const templates: readonly Template[] = [`);

  for (const t of templates) {
    const defaultValue = t.options?.imageVariant?.default;
    const defaultStr =
      typeof defaultValue === "string" ? defaultValue : "jammy";
    const version =
      typeof t.version === "string" && t.version.length > 0
        ? t.version
        : "0.0.0";
    const description = t.description
      .replace(/\\/g, "\\\\")
      .replace(/"/g, '\\"');
    const name = t.name.replace(/\\/g, "\\\\").replace(/"/g, '\\"');

    lines.push(`  {`);
    lines.push(`    id: "${t.id}",`);
    lines.push(`    name: "${name}",`);
    lines.push(`    description: "${description}",`);
    lines.push(`    version: "${version}",`);
    lines.push(`    ghcrUri:`);
    lines.push(`      "ghcr.io/mrrobot0985/devcontainer-templates/${t.id}:latest",`);
    lines.push(`    sourcePath: "src/${t.id}",`);
    lines.push(`    defaults: { imageVariant: "${defaultStr}" },`);
    lines.push(`  },`);
  }

  lines.push(`];`);
  lines.push(``);
  lines.push(`const byId = new Map<string, Template>();`);
  lines.push(`for (const t of templates) {`);
  lines.push(`  byId.set(t.id, t);`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export function getTemplate(id: string): Template | undefined {`);
  lines.push(`  return byId.get(id);`);
  lines.push(`}`);
  lines.push(``);
  lines.push(`export function listTemplates(): readonly Template[] {`);
  lines.push(`  return templates;`);
  lines.push(`}`);
  lines.push(``);

  return lines.join("\n");
}

function main(): void {
  const writeMode = process.argv.includes("--write");
  const discovered = discoverTemplates();
  const generated = generateRegistry(discovered);

  let existing = "";
  try {
    existing = readFileSync(REGISTRY_PATH, "utf-8");
  } catch {
    // File doesn't exist yet
  }

  if (existing === generated) {
    console.log("Template registry is up to date.");
    process.exit(0);
  }

  if (writeMode) {
    writeFileSync(REGISTRY_PATH, generated, "utf-8");
    console.log(
      `Updated ${relative(REPO_ROOT, REGISTRY_PATH)} (${discovered.length} templates).`
    );
    process.exit(0);
  }

  console.error("Template registry is out of sync with src/.\n");
  console.error("Discovered templates:");
  for (const t of discovered) {
    console.error(`  ${t.id}`);
  }
  console.error(
    `\nRun the following command to regenerate ${relative(REPO_ROOT, REGISTRY_PATH)}:`
  );
  console.error(`  npx tsx scripts/sync-template-registry.ts --write`);
  process.exit(1);
}

main();
