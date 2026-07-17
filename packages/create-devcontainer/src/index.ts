#!/usr/bin/env node

import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { program } from "commander";
import { applyTemplate } from "./apply.js";
import { TEMPLATE_CATALOG_URL, TEMPLATE_LAYERS } from "./layers.js";
import { getTemplate, listTemplates, type Template } from "./templates.js";

const __dirname = dirname(fileURLToPath(import.meta.url));
const packageJsonPath = resolve(__dirname, "..", "package.json");
const packageVersion = JSON.parse(readFileSync(packageJsonPath, "utf-8")).version;

function printAvailableTemplates(templates: readonly Template[]): void {
  const byId = new Map(templates.map((t) => [t.id, t]));
  const listed = new Set<string>();

  console.error("Available templates:\n");
  for (const layer of TEMPLATE_LAYERS) {
    console.error(`  ${layer.label}`);
    for (const id of layer.templateIds) {
      const t = byId.get(id);
      if (!t) continue;
      listed.add(id);
      const version = t.version ? `v${t.version}` : "";
      console.error(
        `    ${t.id.padEnd(30)} ${version.padEnd(8)} ${t.name}`
      );
    }
    console.error("");
  }

  const ungrouped = templates.filter((t) => !listed.has(t.id));
  if (ungrouped.length > 0) {
    console.error("  Other");
    for (const t of ungrouped) {
      const version = t.version ? `v${t.version}` : "";
      console.error(
        `    ${t.id.padEnd(30)} ${version.padEnd(8)} ${t.name}`
      );
    }
    console.error("");
  }

  console.error(`Catalog: ${TEMPLATE_CATALOG_URL}`);
}

program
  .name("create-devcontainer")
  .description(
    "Instantiate a devcontainer template into a workspace.\n" +
      `Full catalog (Layers A–D): ${TEMPLATE_CATALOG_URL}`
  )
  .version(packageVersion)
  .argument("[template]", "Template ID to apply")
  .argument("[target-folder]", "Target workspace folder (defaults to .)", ".")
  .option(
    "--registry",
    "Force GHCR registry mode (default is bundled local copy)"
  )
  .option("--force", "Overwrite an existing .devcontainer directory")
  .option("--name <name>", "Override the devcontainer configuration name")
  .option("--readme", "Create a README.md skeleton in the target directory")
  .addHelpText(
    "after",
    `\nCatalog:\n  ${TEMPLATE_CATALOG_URL}\n\nLayers:\n  A  Claude + Ollama family\n  B  Dedicated agent entry points\n  C  Multi-agent evaluation\n  D  Domain stacks (k8s, spark)\n`
  )
  .action((templateId: string | undefined, targetFolder: string, options) => {
    const available = listTemplates();

    if (!templateId) {
      console.error("Error: No template specified.\n");
      console.error("Usage: create-devcontainer <template> [target-folder]\n");
      printAvailableTemplates(available);
      console.error("\nRun with --help for more options.");
      process.exit(1);
    }

    const template = getTemplate(templateId);
    if (!template) {
      console.error(`Error: Unknown template "${templateId}".\n`);
      printAvailableTemplates(available);
      process.exit(1);
    }

    const targetDir = resolve(targetFolder);
    if (!existsSync(targetDir)) {
      mkdirSync(targetDir, { recursive: true });
    }

    const mode: "bundled" | "registry" = options.registry ? "registry" : "bundled";

    try {
      applyTemplate(template, {
        targetDir,
        force: options.force ?? false,
        mode,
        name: options.name,
        readme: options.readme ?? false,
      });
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      console.error(`Error: ${message}`);
      process.exit(1);
    }

    console.log(`Template "${template.name}" applied to ${targetDir}/.devcontainer/`);
    if (mode === "registry") {
      console.log("Next: cd", targetDir, "&& devcontainer up --workspace-folder .");
    } else {
      console.log("Next: review the files and run devcontainer up --workspace-folder .");
    }
  });

program.parse();
