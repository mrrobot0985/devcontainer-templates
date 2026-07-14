#!/usr/bin/env node
/**
 * copy-templates.js
 *
 * Copies template source files from the repo root src/ into templates/
 * so they are bundled with the published npm package.
 */

import { cpSync, existsSync, mkdirSync, readdirSync } from "node:fs";
import { dirname, join } from "node:path";

const pkgDir = dirname(new URL(import.meta.url).pathname);
const repoRoot = join(pkgDir, "..", "..", "..");
const srcDir = join(repoRoot, "src");
const destDir = join(pkgDir, "..", "templates");

if (!existsSync(srcDir)) {
  console.error("Source directory not found:", srcDir);
  process.exit(1);
}

if (existsSync(destDir)) {
  // Remove existing to ensure clean copy
  const { rmSync } = await import("node:fs");
  rmSync(destDir, { recursive: true, force: true });
}

mkdirSync(destDir, { recursive: true });

const entries = readdirSync(srcDir, { withFileTypes: true });
let copied = 0;

for (const entry of entries) {
  if (!entry.isDirectory()) continue;
  const srcPath = join(srcDir, entry.name);
  const destPath = join(destDir, entry.name);
  cpSync(srcPath, destPath, { recursive: true });
  copied++;
}

console.log(`Copied ${copied} templates to ${destDir}`);
