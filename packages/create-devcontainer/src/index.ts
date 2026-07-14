#!/usr/bin/env node

import { existsSync, mkdirSync } from "node:fs";
import { resolve } from "node:path";
import { program } from "commander";
import { applyTemplate } from "./apply.js";
import { getTemplate, listTemplates } from "./templates.js";

program
  .name("create-devcontainer")
  .description("Instantiate a devcontainer template into a workspace")
  .version("1.0.0")
  .argument("[template]", "Template ID to apply")
  .argument("[target-folder]", "Target workspace folder (defaults to .)", ".")
  .option(
    "--registry",
    "Force GHCR registry mode (default is bundled local copy)"
  )
  .option("--force", "Overwrite an existing .devcontainer directory")
  .option("--name <name>", "Override the devcontainer configuration name")
  .action((templateId: string | undefined, targetFolder: string, options) => {
    const available = listTemplates();

    if (!templateId) {
      console.error("Error: No template specified.\n");
      console.error("Usage: create-devcontainer <template> [target-folder]\n");
      console.error("Available templates:");
      for (const t of available) {
        console.error(`  ${t.id.padEnd(36)} ${t.name}`);
      }
      console.error("\nRun with --help for more options.");
      process.exit(1);
    }

    const template = getTemplate(templateId);
    if (!template) {
      console.error(`Error: Unknown template "${templateId}".\n`);
      console.error("Available templates:");
      for (const t of available) {
        console.error(`  ${t.id.padEnd(36)} ${t.name}`);
      }
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
