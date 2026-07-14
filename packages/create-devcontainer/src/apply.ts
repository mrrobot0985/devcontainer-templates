import { spawnSync } from "node:child_process";
import {
  copyFileSync,
  existsSync,
  mkdirSync,
  readdirSync,
  readFileSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { dirname, join, relative } from "node:path";
import type { Template } from "./templates.js";

export interface ApplyOptions {
  targetDir: string;
  force: boolean;
  mode: "dev" | "registry";
}

/**
 * Apply a template to the target workspace directory.
 */
export function applyTemplate(
  template: Template,
  options: ApplyOptions
): void {
  const devcontainerDir = join(options.targetDir, ".devcontainer");

  if (existsSync(devcontainerDir) && !options.force) {
    throw new Error(
      `Refusing to overwrite existing .devcontainer directory: ${devcontainerDir}\n` +
        `Run again with --force to replace it.`
    );
  }

  if (options.mode === "registry") {
    applyFromRegistry(template, options);
  } else {
    applyFromSource(template, options);
  }
}

function applyFromRegistry(template: Template, options: ApplyOptions): void {
  const args = [
    "templates",
    "apply",
    "--workspace-folder",
    options.targetDir,
    "--template-id",
    template.ghcrUri,
    "--template-args",
    JSON.stringify(template.defaults),
  ];

  const result = spawnSync("npx", ["--yes", "@devcontainers/cli", ...args], {
    stdio: "inherit",
    shell: false,
  });

  if (result.status !== 0) {
    throw new Error(
      `devcontainer templates apply exited with code ${result.status ?? result.signal}`
    );
  }
}

function applyFromSource(template: Template, options: ApplyOptions): void {
  const sourceDir = resolveSourceDir(template.sourcePath);
  if (!existsSync(sourceDir)) {
    throw new Error(
      `Template source directory not found: ${sourceDir}\n` +
        `Are you running from the repository root?`
    );
  }

  copyRecursive(sourceDir, options.targetDir, template.defaults);
}

/**
 * Resolve the source directory relative to the repository root.
 * When the package is inside packages/create-devcontainer/, the repo root is two levels up.
 */
function resolveSourceDir(sourcePath: string): string {
  const pkgDir = dirname(import.meta.dirname ?? ".");
  const repoRoot = join(pkgDir, "..", "..");
  return join(repoRoot, sourcePath);
}

/**
 * Recursively copy files from source to target, substituting template options.
 */
function copyRecursive(
  src: string,
  dest: string,
  defaults: Record<string, string>
): void {
  const entries = readdirSync(src, { withFileTypes: true });

  for (const entry of entries) {
    const srcPath = join(src, entry.name);
    const rel = relative(src, srcPath);
    const destPath = join(dest, rel);

    if (entry.isDirectory()) {
      mkdirSync(destPath, { recursive: true });
      copyRecursive(srcPath, destPath, defaults);
    } else {
      mkdirSync(dirname(destPath), { recursive: true });
      let content = readFileSync(srcPath, "utf-8");
      content = substituteOptions(content, defaults);
      writeFileSync(destPath, content, "utf-8");
    }
  }
}

/**
 * Replace ${templateOption:<key>} placeholders with their default values.
 */
function substituteOptions(
  content: string,
  defaults: Record<string, string>
): string {
  for (const [key, value] of Object.entries(defaults)) {
    const pattern = new RegExp(`\\$\\{templateOption:${key}\\}`, "g");
    content = content.replace(pattern, value);
  }
  return content;
}
