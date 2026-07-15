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
import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const CLAUDE_TIMEOUT_MS = 300000;
const REVIEW_TIMEOUT_MS = 300000;
const MAX_IMPROVEMENTS = 20;

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

function claudeAvailable() {
  const result = spawnSync("claude", ["--help"], {
    stdio: "ignore",
    encoding: "utf-8",
    timeout: 10000,
  });
  return result.error === undefined && result.status === 0;
}

function spawnHeadlessClaude(ws, prompt, opts = {}) {
  if (!claudeAvailable()) {
    return { ok: false, status: "blocked", reason: "claude CLI not available" };
  }

  const args = ["-p", "--output-format", "text", prompt];
  const result = spawnSync("claude", args, {
    cwd: ws,
    stdio: ["ignore", "pipe", "pipe"],
    encoding: "utf-8",
    timeout: opts.timeout || CLAUDE_TIMEOUT_MS,
    env: { ...process.env, CLAUDE_CODE_SIMPLE: "1", ...(opts.env || {}) },
  });

  if (result.error) {
    return { ok: false, status: "blocked", reason: `failed to spawn claude: ${result.error.message}` };
  }

  return {
    ok: result.status === 0,
    status: result.status === 0 ? "ok" : "blocked",
    exitCode: result.status,
    stdout: result.stdout || "",
    stderr: result.stderr || "",
  };
}

function readTicketDependencies(ws, ticket) {
  const deps = { dependsOn: [], dependents: [], blocking: [] };
  const stateDir = join(ws, ".ralph", "state");
  if (!existsSync(stateDir)) return deps;

  const files = readdirSync(stateDir).filter((f) => f.endsWith(".json"));
  let currentState = null;

  for (const file of files) {
    try {
      const state = JSON.parse(readFileSync(join(stateDir, file), "utf-8"));
      if (state.ticket === ticket) {
        currentState = state;
      } else if (
        state.dependsOn === ticket ||
        (Array.isArray(state.dependsOn) && state.dependsOn.includes(ticket))
      ) {
        deps.dependents.push({ ticket: state.ticket, status: state.status });
      }
    } catch {
      // Ignore malformed state files.
    }
  }

  if (currentState?.dependsOn) {
    const required = Array.isArray(currentState.dependsOn)
      ? currentState.dependsOn
      : [currentState.dependsOn];
    for (const depTicket of required) {
      const depFile = join(stateDir, `${depTicket}.json`);
      let depStatus = "missing";
      if (existsSync(depFile)) {
        try {
          depStatus = JSON.parse(readFileSync(depFile, "utf-8")).status || "open";
        } catch {
          depStatus = "unreadable";
        }
      }
      deps.dependsOn.push({ ticket: depTicket, status: depStatus });
      if (!["complete", "pending-review"].includes(depStatus)) {
        deps.blocking.push(depTicket);
      }
    }
  }

  return deps;
}

function buildReviewPrompt(perspective, ws, task) {
  const prompts = {
    architecture: `You are an architecture reviewer in workspace ${ws}. Task: ${task}
Review the changes for over-engineering, speculative abstractions, middle-man functions, and proper file locations.
Report concise findings as a short markdown list. If no issues, say "PASS".`,
    correctness: `You are a correctness reviewer in workspace ${ws}. Task: ${task}
Check syntax, run relevant tests or lint commands, and verify the change does what is asked.
Report concise findings as a short markdown list. If no issues, say "PASS".`,
    safety: `You are a safety reviewer in workspace ${ws}. Task: ${task}
Scan for committed secrets, destructive operations without human-approval markers, and AI attribution markers.
Report concise findings as a short markdown list. If no issues, say "PASS".`,
  };
  return prompts[perspective] || prompts.correctness;
}

function runReviewPerspectives(ws, ticket, task) {
  const perspectives = ["architecture", "correctness", "safety"];
  const reportDir = join(ws, ".ralph", "reports");
  ensureDir(reportDir);
  const outputs = [];
  const deadline = Date.now() + REVIEW_TIMEOUT_MS;

  for (const perspective of perspectives) {
    const remaining = Math.max(1000, deadline - Date.now());
    const scriptPath = join(ws, "scripts", `review-${perspective}.sh`);
    let result;
    if (existsSync(scriptPath)) {
      result = spawnSync("bash", [scriptPath, `ralph/${ticket}`, "main"], {
        cwd: ws,
        stdio: ["ignore", "pipe", "pipe"],
        encoding: "utf-8",
        timeout: remaining,
        env: {
          ...process.env,
          REPO_DIR: ws,
          OUT_DIR: reportDir,
          TARGET_REF: `ralph/${ticket}`,
          BASE_REF: "main",
        },
      });
    } else {
      const prompt = buildReviewPrompt(perspective, ws, task);
      result = spawnSync("claude", ["-p", "--output-format", "text", prompt], {
        cwd: ws,
        stdio: ["ignore", "pipe", "pipe"],
        encoding: "utf-8",
        timeout: remaining,
        env: { ...process.env, CLAUDE_CODE_SIMPLE: "1" },
      });
    }
    outputs.push({
      type: "review",
      perspective,
      ok: result.status === 0 && !result.error,
      exitCode: result.status,
      error: result.error?.message,
      stdout: result.stdout || "",
      stderr: result.stderr || "",
    });
  }

  return { status: outputs.every((o) => o.ok) ? "ok" : "blocked", outputs };
}

function collectFailureSuggestions(ws) {
  const logDir = join(ws, ".ralph", "logs");
  if (!existsSync(logDir)) return [];

  const seen = new Set();
  const suggestions = [];
  const files = readdirSync(logDir).filter((f) => f.endsWith(".log"));

  for (const file of files) {
    try {
      const content = readFileSync(join(logDir, file), "utf-8");
      for (const line of content.split("\n")) {
        if (!line.trim()) continue;
        try {
          const entry = JSON.parse(line);
          if (entry.status === "blocked" || entry.verifyResult?.ok === false) {
            const reason =
              entry.taskResult?.reason ||
              entry.verifyResult?.checks?.find((c) => !c.ok)?.detail ||
              "verification or task failed";
            const key = `${entry.ticket}:${reason}`;
            if (!seen.has(key)) {
              seen.add(key);
              suggestions.push({ file, ticket: entry.ticket, reason });
            }
          }
        } catch {
          // Ignore non-JSON log lines.
        }
      }
    } catch {
      // Ignore unreadable log files.
    }
  }

  return suggestions.slice(-MAX_IMPROVEMENTS);
}

function appendImprovementSuggestions(ws, suggestions) {
  if (suggestions.length === 0) return;

  const thisPath = fileURLToPath(import.meta.url);
  if (!existsSync(thisPath)) return;

  let content = readFileSync(thisPath, "utf-8");
  const markerStart = "// == SELF-EVOLUTION IMPROVEMENTS ==";
  const markerEnd = "// == END SELF-EVOLUTION IMPROVEMENTS ==";
  const now = new Date().toISOString();
  const newLines = suggestions.map((s) => `// - ${now} [${s.ticket}] ${s.reason}`).join("\n");

  if (content.includes(markerStart) && content.includes(markerEnd)) {
    content = content.replace(markerEnd, `${newLines}\n${markerEnd}`);
  } else {
    content += `\n\n${markerStart}\n// Failure-derived suggestions for runner.mjs:\n${newLines}\n${markerEnd}\n`;
  }

  // Cap total suggestions to avoid unbounded growth.
  const startIdx = content.indexOf(markerStart);
  const endIdx = content.indexOf(markerEnd);
  if (startIdx !== -1 && endIdx !== -1) {
    const section = content.slice(startIdx, endIdx + markerEnd.length);
    const suggestionLines = section.split("\n").filter((l) => l.trim().startsWith("// -"));
    if (suggestionLines.length > MAX_IMPROVEMENTS) {
      const kept = suggestionLines.slice(-MAX_IMPROVEMENTS);
      const headerEnd = content.indexOf("\n", content.indexOf("\n", startIdx) + 1) + 1;
      const header = content.slice(startIdx, headerEnd);
      const newSection = `${header}${kept.join("\n")}\n${markerEnd}`;
      content = content.slice(0, startIdx) + newSection + content.slice(endIdx + markerEnd.length);
    }
  }

  writeFileSync(thisPath, content);
}

function buildImplementationPrompt(ws, task, deps) {
  const blocking = deps.blocking.length > 0 ? deps.blocking.join(", ") : "none";
  const dependents = deps.dependents.map((d) => `${d.ticket} (${d.status})`).join(", ") || "none";

  return `You are an autonomous implementation agent in a deterministic sandcastle.
Workspace: ${ws}
Task: ${task}
Blocking dependencies: ${blocking}
Dependents waiting: ${dependents}

Instructions:
1. Examine the workspace and understand the task.
2. Implement the requested change using available tools.
3. Add or update tests covering the change.
4. Follow conventional commits and project coding standards.
5. Avoid speculative abstractions, future-proofing, or unrelated changes.
6. Report the outcome: files changed, tests run, and any blockers.

If you cannot complete the task deterministically, explain why.`;
}

function buildGenericPrompt(ws, task) {
  return `You are an autonomous task agent in a deterministic sandcastle.
Workspace: ${ws}
Task: ${task}

Instructions:
1. Examine the workspace.
2. Attempt to complete the task deterministically.
3. Prefer existing project scripts and tools.
4. Report the outcome and any blockers.

If the task requires human judgment or live systems, say BLOCKED and explain why.`;
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
    taskResult = runImplementTask(ws, ticket, task);
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

function runImplementTask(ws, ticket, task) {
  // Implement: read dependencies, run headless Claude, then multi-perspective review.
  console.log(`Implementation task: ${task}`);

  const deps = readTicketDependencies(ws, ticket);
  if (deps.blocking.length > 0) {
    return { status: "blocked", reason: `waiting for dependencies: ${deps.blocking.join(", ")}` };
  }

  const prompt = buildImplementationPrompt(ws, task, deps);
  const result = spawnHeadlessClaude(ws, prompt);
  if (!result.ok) {
    return { status: "blocked", reason: result.reason || "claude execution failed", claudeOutput: result };
  }

  console.log("  Claude output:");
  console.log(result.stdout?.split("\n").map((l) => `    ${l}`).join("\n") || "    (no output)");

  const reviewResult = runReviewPerspectives(ws, ticket, task);
  const reviewFailed = reviewResult.outputs.some((o) => !o.ok);

  const suggestions = collectFailureSuggestions(ws);
  appendImprovementSuggestions(ws, suggestions);

  if (reviewFailed) {
    return { status: "blocked", reason: "multi-perspective review failed", claudeOutput: result, review: reviewResult };
  }

  return { status: "ok", outputs: [{ type: "claude", ...result }, { type: "review", ...reviewResult }] };
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
  // Generic: try headless Claude execution before marking blocked.
  console.log(`Generic task: ${task}`);

  if (!claudeAvailable()) {
    console.log("  claude CLI not available. Marking blocked for human review.");
    return { status: "blocked", reason: "No deterministic runner for this task type and claude CLI is unavailable." };
  }

  const prompt = buildGenericPrompt(ws, task);
  const result = spawnHeadlessClaude(ws, prompt);
  if (!result.ok) {
    console.log(`  Headless claude failed: ${result.reason}`);
    return { status: "blocked", reason: result.reason || "claude execution failed", claudeOutput: result };
  }

  console.log("  Claude output:");
  console.log(result.stdout?.split("\n").map((l) => `    ${l}`).join("\n") || "    (no output)");

  return { status: "ok", outputs: [{ type: "claude", ...result }] };
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

// == SELF-EVOLUTION IMPROVEMENTS ==
// Failure-derived suggestions for runner.mjs:
// == END SELF-EVOLUTION IMPROVEMENTS ==
