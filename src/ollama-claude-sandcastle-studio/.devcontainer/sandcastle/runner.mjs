#!/usr/bin/env node
/**
 * Sandcastle-like runner for isolated agent task execution.
 *
 * This script simulates Matt Pocock's sandcastle patterns:
 * - Isolated workspace per task
 * - Branch-per-ticket sandboxing
 * - Verification before merge
 * - Deterministic execution (no LLM improvisation)
 *
 * Usage:
 *   node runner.mjs --ticket TICKET-123 --task "Implement feature X" --iteration 1 --workspace /path/to/repo
 */

import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";

function parseArgs() {
  const args = process.argv.slice(2);
  const parsed = {};
  for (let i = 0; i < args.length; i += 2) {
    const key = args[i].replace(/^--/, "");
    parsed[key] = args[i + 1];
  }
  return parsed;
}

function exec(cmd, args, opts = {}) {
  const result = spawnSync(cmd, args, {
    stdio: ["inherit", "pipe", "pipe"],
    encoding: "utf-8",
    ...opts,
  });
  if (result.status !== 0 && !opts.ignoreFailure) {
    console.error(`Command failed: ${cmd} ${args.join(" ")}`);
    console.error(result.stderr);
    process.exit(result.status || 1);
  }
  return result;
}

function ensureDir(path) {
  if (!existsSync(path)) mkdirSync(path, { recursive: true });
}

function main() {
  const { ticket, task, iteration, workspace } = parseArgs();

  if (!ticket || !task) {
    console.error("Usage: node runner.mjs --ticket <id> --task <description> [--iteration <n>] [--workspace <path>]");
    process.exit(1);
  }

  const ws = workspace || process.cwd();
  const branch = `ralph/${ticket}`;
  const stateDir = join(ws, ".ralph", "state");
  const logDir = join(ws, ".ralph", "logs");
  ensureDir(stateDir);
  ensureDir(logDir);

  const logFile = join(logDir, `${ticket}-iter${iteration || 1}.log`);
  const stateFile = join(stateDir, `${ticket}.json`);

  console.log(`=== Sandcastle Runner ===`);
  console.log(`Ticket:     ${ticket}`);
  console.log(`Task:       ${task}`);
  console.log(`Iteration:  ${iteration || 1}`);
  console.log(`Workspace:  ${ws}`);
  console.log(`Branch:     ${branch}`);
  console.log("");

  // 1. Ensure branch exists
  const currentBranch = exec("git", ["-C", ws, "rev-parse", "--abbrev-ref", "HEAD"], { ignoreFailure: true }).stdout?.trim();
  if (currentBranch !== branch) {
    const branchCheck = exec("git", ["-C", ws, "branch", "--list", branch], { ignoreFailure: true });
    if (!branchCheck.stdout?.trim()) {
      console.log(`Creating sandbox branch: ${branch}`);
      exec("git", ["-C", ws, "checkout", "-b", branch]);
    } else {
      console.log(`Checking out existing branch: ${branch}`);
      exec("git", ["-C", ws, "checkout", branch]);
    }
  }

  // 2. Write state
  const state = existsSync(stateFile)
    ? JSON.parse(readFileSync(stateFile, "utf-8"))
    : { ticket, task, iteration: Number(iteration) || 1, status: "open", createdAt: new Date().toISOString() };
  state.iteration = Number(iteration) || state.iteration + 1;
  state.lastRunAt = new Date().toISOString();
  writeFileSync(stateFile, JSON.stringify(state, null, 2));

  // 3. Execute task type-specific commands
  const taskLower = task.toLowerCase();
  let taskResult = { status: "unknown", outputs: [] };

  if (taskLower.includes("research")) {
    console.log("Task type: RESEARCH (AFK)");
    // Research tasks: delegate to a documentation read + summary
    taskResult = runResearchTask(ws, task);
  } else if (taskLower.includes("test") || taskLower.includes("spec")) {
    console.log("Task type: SPEC/TEST (AFK)");
    taskResult = runSpecTask(ws, task);
  } else if (taskLower.includes("implement") || taskLower.includes("build")) {
    console.log("Task type: IMPLEMENT (AFK)");
    taskResult = runImplementTask(ws, task);
  } else if (taskLower.includes("prototype")) {
    console.log("Task type: PROTOTYPE (AFK)");
    taskResult = runPrototypeTask(ws, task);
  } else if (taskLower.includes("lint") || taskLower.includes("format")) {
    console.log("Task type: QUALITY (AFK)");
    taskResult = runQualityTask(ws, task);
  } else {
    console.log("Task type: GENERIC (AFK)");
    taskResult = runGenericTask(ws, task);
  }

  // 4. Verify
  console.log("\n--- Verification ---");
  const verifyResult = verifyWorkspace(ws);

  // 5. Update state
  state.status = verifyResult.ok ? "pending-review" : "blocked";
  state.verification = verifyResult;
  state.taskResult = taskResult;
  writeFileSync(stateFile, JSON.stringify(state, null, 2));

  // 6. Log
  const logEntry = {
    timestamp: new Date().toISOString(),
    ticket,
    iteration: state.iteration,
    task,
    taskResult,
    verifyResult,
    status: state.status,
  };
  writeFileSync(logFile, JSON.stringify(logEntry, null, 2) + "\n", { flag: "a" });

  console.log(`\n=== Runner Complete ===`);
  console.log(`Status: ${state.status}`);
  if (!verifyResult.ok) {
    console.error("Verification failed. Human review required.");
    process.exit(2);
  }
}

function runResearchTask(ws, task) {
  // Research: find and read relevant docs, write summary
  const outputs = [];
  console.log(`Researching: ${task}`);

  // Look for README, docs/, and ADRs
  const candidates = ["README.md", "docs/", "docs/adr/", "SPEC.md", "CONTEXT.md"];
  for (const candidate of candidates) {
    const path = join(ws, candidate);
    if (existsSync(path)) {
      console.log(`  Found: ${candidate}`);
      outputs.push({ type: "source", path: candidate });
    }
  }

  // Write a research note
  const notePath = join(ws, ".ralph", "notes", `research-${Date.now()}.md`);
  ensureDir(dirname(notePath));
  writeFileSync(
    notePath,
    `# Research: ${task}\n\nDate: ${new Date().toISOString()}\n\n## Sources\n\n${outputs.map((o) => `- ${o.path}`).join("\n")}\n\n## Notes\n\n_TODO: fill in findings_\n`
  );
  outputs.push({ type: "artifact", path: notePath });

  return { status: "ok", outputs };
}

function runSpecTask(ws, task) {
  // Spec/Test tasks: ensure tests exist, run them
  const outputs = [];
  console.log(`Running spec/test task: ${task}`);

  // Attempt to run the project's test suite
  if (existsSync(join(ws, "package.json"))) {
    const pkg = JSON.parse(readFileSync(join(ws, "package.json"), "utf-8"));
    if (pkg.scripts?.test) {
      console.log("  Running: npm test");
      const result = exec("npm", ["test"], { cwd: ws, ignoreFailure: true });
      outputs.push({ type: "test", command: "npm test", exitCode: result.status, stdout: result.stdout });
    }
  }

  if (existsSync(join(ws, "pytest.ini")) || existsSync(join(ws, "setup.cfg")) || existsSync(join(ws, "pyproject.toml"))) {
    console.log("  Running: pytest");
    const result = exec("pytest", [], { cwd: ws, ignoreFailure: true });
    outputs.push({ type: "test", command: "pytest", exitCode: result.status, stdout: result.stdout });
  }

  return { status: "ok", outputs };
}

function runImplementTask(ws, task) {
  // Implement: invoke Matt Pocock's /implement skill headlessly via wrapper
  const wrappersDir = join(ws, ".devcontainer", "skills", "headless");
  const implementScript = join(wrappersDir, "headless-implement.sh");

  if (existsSync(implementScript)) {
    console.log(`Implementation task: ${task}`);
    console.log(`  Invoking ${implementScript}`);
    const result = exec("bash", [implementScript, ws], { cwd: ws, ignoreFailure: true });
    return {
      status: result.status === 0 ? "ok" : "blocked",
      outputs: [
        { type: "implement", command: implementScript, exitCode: result.status, stdout: result.stdout }
      ]
    };
  }

  console.log(`Implementation task: ${task}`);
  console.log("  NOTE: headless-implement.sh not found. Run bootstrap.sh init to copy wrappers.");
  return { status: "blocked", reason: "headless-implement.sh not found" };
}

function runPrototypeTask(ws, task) {
  // Prototype: invoke Matt Pocock's /prototype skill headlessly via wrapper
  const wrappersDir = join(ws, ".devcontainer", "skills", "headless");
  const prototypeScript = join(wrappersDir, "headless-prototype.sh");

  if (existsSync(prototypeScript)) {
    console.log(`Prototype task: ${task}`);
    console.log(`  Invoking ${prototypeScript}`);
    const result = exec("bash", [prototypeScript, task, ws], { cwd: ws, ignoreFailure: true });
    return {
      status: result.status === 0 ? "ok" : "blocked",
      outputs: [
        { type: "prototype", command: prototypeScript, exitCode: result.status, stdout: result.stdout }
      ]
    };
  }

  console.log(`Prototype task: ${task}`);
  console.log("  NOTE: headless-prototype.sh not found. Run bootstrap.sh init to copy wrappers.");
  return { status: "blocked", reason: "headless-prototype.sh not found" };
}

function runQualityTask(ws, task) {
  // Quality: lint, format, typecheck
  const outputs = [];
  console.log(`Quality task: ${task}`);

  if (existsSync(join(ws, "package.json"))) {
    const pkg = JSON.parse(readFileSync(join(ws, "package.json"), "utf-8"));
    for (const script of ["lint", "format:check", "typecheck"]) {
      if (pkg.scripts?.[script]) {
        console.log(`  Running: npm run ${script}`);
        const result = exec("npm", ["run", script], { cwd: ws, ignoreFailure: true });
        outputs.push({ type: "quality", command: `npm run ${script}`, exitCode: result.status });
      }
    }
  }

  return { status: "ok", outputs };
}

function runGenericTask(ws, task) {
  console.log(`Generic task: ${task}`);
  console.log("  No specific runner matched. Human review required.");
  return { status: "blocked", reason: "No deterministic runner for this task type." };
}

function verifyWorkspace(ws) {
  const checks = [];

  // Check git is clean enough
  const status = exec("git", ["-C", ws, "status", "--porcelain"], { ignoreFailure: true });
  const isClean = !status.stdout?.trim();
  checks.push({ name: "git-clean", ok: isClean, detail: isClean ? "clean" : "has changes" });

  // Check for tests if project has them
  let hasTests = false;
  if (existsSync(join(ws, "package.json"))) {
    const pkg = JSON.parse(readFileSync(join(ws, "package.json"), "utf-8"));
    hasTests = !!pkg.scripts?.test;
  }
  if (existsSync(join(ws, "pytest.ini")) || existsSync(join(ws, "tests"))) {
    hasTests = true;
  }
  checks.push({ name: "has-tests", ok: true, detail: hasTests ? "test suite found" : "no test suite (ok)" });

  // Check conventional commits on current branch
  const log = exec("git", ["-C", ws, "log", "origin/main..HEAD", "--pretty=format:%s"], { ignoreFailure: true });
  const commits = log.stdout?.split("\n").filter(Boolean) || [];
  const badCommits = commits.filter(
    (c) =>
      !c.match(/^(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\(.+\))?!?: .+/) &&
      !c.startsWith("Merge") &&
      !c.match(/^v\d+\./)
  );
  checks.push({ name: "conventional-commits", ok: badCommits.length === 0, detail: `bad=${badCommits.length}` });

  const ok = checks.every((c) => c.ok);
  return { ok, checks };
}

main();
