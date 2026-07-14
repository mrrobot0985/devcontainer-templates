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
  mode: "bundled" | "registry" | "dev";
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
    stdio: "pipe",
    shell: false,
    encoding: "utf-8",
  });

  if (result.status !== 0) {
    const stderr = result.stderr ?? "";
    const stdout = result.stdout ?? "";
    const combined = stdout + stderr;

    if (
      combined.includes("Failed to fetch template") ||
      combined.includes("manifest unknown") ||
      combined.includes("not found")
    ) {
      throw new Error(
        `Template "${template.id}" is not available from the registry (${template.ghcrUri}).\n\n` +
          `This usually means the template has not been published to GHCR yet, ` +
          `or the GHCR package is private.\n\n` +
          `To apply the template from local source instead, run:\n` +
          `  npx @mrrobot0985/create-devcontainer ${template.id} ${options.targetDir}`
      );
    }

    throw new Error(
      `devcontainer templates apply exited with code ${result.status ?? result.signal}\n${combined}`
    );
  }

  // Print stdout so the user sees devcontainer CLI output on success
  if (result.stdout) {
    console.log(result.stdout);
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
 * Resolve the source directory.
 * When the package is installed from npm, templates are bundled under templates/.
 * When running from the repo source, they live two levels up under src/.
 */
function resolveSourceDir(sourcePath: string): string {
  const pkgDir = dirname(import.meta.dirname ?? ".");

  // 1. Bundled templates (installed from npm)
  const bundledDir = join(pkgDir, "templates", sourcePath.replace(/^src\//, ""));
  if (existsSync(bundledDir)) {
    return bundledDir;
  }

  // 2. Repo source (running from git checkout)
  const repoRoot = join(pkgDir, "..", "..");
  const repoDir = join(repoRoot, sourcePath);
  if (existsSync(repoDir)) {
    return repoDir;
  }

  // Return bundled path as fallback for error message
  return bundledDir;
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
      if (entry.name === "devcontainer-template.json") {
        continue;
      }
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
