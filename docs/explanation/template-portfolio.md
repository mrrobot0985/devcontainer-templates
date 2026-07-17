# Template Portfolio

This document freezes **what this collection is for** before the template set grows further. It defines the mission, the portfolio layers (A–D), and the sense rules that decide which templates belong and how they may combine.

For how purpose-driven families are designed day to day, see [Template Design Philosophy](template-design.md). For the published inventory, see the [Template Catalog](../reference/template-catalog.md).

## Mission

Ship **purpose-driven** devcontainer templates that:

1. **Showcase monorepo differentiators** — owned features for agent configuration, privacy, security floors, and lifecycle — not thin wrappers around a single CLI install.
1. **Give first-class agents clean entry points** — each supported agent gets a coherent minimal (and, where justified, studio) template rather than a feature checklist.
1. **Avoid combinatorial sprawl** — do not multiply templates by every hardware or language axis for every agent.
1. **Stay buildable** — every shipped template must apply, smoke-test, and resolve published features.

The collection is **agent-first**. Language, cloud, and data stacks only stay when they earn their place against that mission (see Layer D).

## Portfolio layers

| Layer | Role                                                             | Examples (today or planned)                                                               |
| ----- | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------- |
| **A** | Claude depth — owned features configure the agent                | `ollama-claude-cli*` family                                                               |
| **B** | Agent entry points — install + security floor + home persistence | `grok-build-cli` / `grok-build-cli-studio`; Pi, Hermes, Codex, Gemini, OpenCode (planned) |
| **C** | Multi-agent evaluation — one workspace, many CLIs                | `multi-ai-cli`                                                                            |
| **D** | Domain stacks — not agent-centric                                | `cloud-native-k8s`, `data-engineering-spark` (**keep; re-feature or archive later**)      |

### Layer A — Claude depth

Claude Code is the deepest integration in this monorepo. Owned features configure backend, privacy, hooks, rules, skills, plugins, and related policy. The `ollama-claude-cli*` family is the primary showcase:

| Template                    | Intent                                                |
| --------------------------- | ----------------------------------------------------- |
| `ollama-claude-cli`         | Minimal GPU host-Ollama entry point                   |
| `ollama-claude-cli-cpu`     | Same stack without GPU requirements                   |
| `ollama-claude-cli-compose` | Bundled Ollama via Compose (no host Ollama)           |
| `ollama-claude-cli-python`  | Claude + Python AI/ML toolchain                       |
| `ollama-claude-cli-studio`  | Full studio: DinD, toolkit hooks, richer Claude suite |

**Security floor (target):** official Claude Code install + `claude-code-backend` / `claude-code-privacy` as appropriate + `container-firewall` + `non-root-enforcer` (and studio-level audit/sandbox where justified).

Layer A is the only place where a **rich variant matrix** (cpu / compose / python / studio) is intentional: Claude owns the feature surface that makes those variants meaningful.

### Layer B — Agent entry points

Other first-class agents get **dedicated templates**, not Claude-shaped forks.

Typical shape:

- **Minimal:** install the agent (prefer official or mature community features), agent-agnostic security floor, persist the agent's home directory (`~/.grok`, `~/.pi`, …).
- **Studio (optional):** DinD / host isolation / MCP tooling only when dogfood shows a real need.

**Non-goals for Layer B:**

- Do **not** attach Claude-only suite features (`claude-code-hooks`, `claude-code-rules`, `claude-code-skills`, …) to non-Claude agents.
- Do **not** recreate the full Ollama cpu/gpu/compose/python matrix for API-first agents.
- Prefer community install features when they are the standard (for example Grok Build via a maintained community feature) rather than bare owned installers that add no policy.

First-class agents tracked for dedicated entry points include Grok Build, Pi, Hermes, OpenAI Codex CLI, Google Gemini CLI, and OpenCode. Additional CLIs (Aider, Goose, and similar) are evaluated case by case rather than assumed.

### Layer C — Multi-agent evaluation

`multi-ai-cli` is the **comparison and evaluation** workspace: several agent CLIs in one environment so users can try providers without maintaining N projects.

Rules for Layer C:

- Install each agent reliably; document multi-key auth honestly.
- Apply an **agent-agnostic** floor (`non-root-enforcer`, `ai-agent-sandbox`, multi-provider firewall tags when available).
- Gate Claude-only features so they apply only when Claude is present and intended.
- Persist per-agent homes (`~/.claude`, `~/.grok`, `~/.pi`, …), not a single shared config tree.
- Prefer `policy: monitor` or omit firewall over shipping a **broken whitelist**.

Layer C complements Layer B; it does not replace dedicated entry points for daily single-agent work.

### Layer D — Domain stacks (keep; re-feature later)

`cloud-native-k8s` and `data-engineering-spark` remain in the tree as **domain stacks**. They sit **outside** the agent-first growth path. Today they ship with **zero or very few owned monorepo features** — honest tool bundles (kubectl/Helm/k3d/Tilt/DinD; Spark/Jupyter/Polars/MinIO), not differentiator showcases.

#### Decision recorded (issue #66)

| Choice                         | Status                                                                                               |
| ------------------------------ | ---------------------------------------------------------------------------------------------------- |
| **Keep both for now**          | **Selected.** Do **not** delete in this phase.                                                       |
| **Re-feature**                 | **Path forward** when capacity allows: wire owned floor + domain helpers; catalog under Data / Cloud |
| **Archive later if unused**    | **Fallback** after the agent portfolio is stable, if there is no demand or maintenance path          |
| **Major investment right now** | **Out of scope** until Layers A–C are stable                                                         |

Explicit non-action: **do not delete** these templates while documenting the path forward.

#### Revisit criteria

Apply the same decision criteria when revisiting after the agent portfolio (Layers A–C) is stable:

1. Does the template showcase monorepo differentiators, or is it a generic tool bundle?
1. Will it be maintained and smoke-tested with the same bar as Layers A–C?
1. Is there a clear user who would choose it over official/community templates?
1. Does keeping it dilute the agent-first story more than it helps adoption?

**Re-feature target examples** (illustrative, not committed scope):

- `data-engineering-spark` → owned Jupyter/ML/data helpers + firewall + non-root where they fit
- `cloud-native-k8s` → DinD + firewall/docker tags + host isolation + cloud CLI persistence where they fit

Until re-feature or archive, treat Layer D templates as **kept-but-honest**: listed in the catalog with Layer D status and the zero/low owned-feature caveat, not as the growth vector.

## Sense matrix

Use this matrix when proposing a new template or a cross-layer combination.

| Combination                                                                                 | Sense?   | Why                                                                     |
| ------------------------------------------------------------------------------------------- | -------- | ----------------------------------------------------------------------- |
| Claude minimal / cpu / compose / python / studio (Layer A)                                  | **Good** | Owned Claude features make each variant a real capability delta         |
| Dedicated agent minimal (+ studio when justified) (Layer B)                                 | **Good** | Clean entry point + security floor + home persistence                   |
| `multi-ai-cli` with several agents + agent-agnostic floor (Layer C)                         | **Good** | Evaluation workspace; not a substitute for daily single-agent templates |
| Claude suite features on Grok / Pi / Hermes / Codex / …                                     | **Bad**  | Wrong ownership model; confuses install with Claude-specific policy     |
| Full cpu/gpu/compose/python matrix for every Layer B agent                                  | **Bad**  | Combinatorial sprawl; most agents are API-first                         |
| Domain template with zero owned features and no path forward (Layer D drift)                | **Bad**  | Fails mission; must re-feature or archive with a recorded date          |
| Domain template kept with honest Layer D caveat + revisit criteria                          | **OK**   | Temporary honesty; re-feature or archive after agents stabilize         |
| Options for base image / model map / python version on one template                         | **Good** | Parameter variance, not a new capability                                |
| New template for a one-line feature difference                                              | **Bad**  | Use `options` or extend an existing purpose-driven template             |
| Firewall whitelist without correct provider service tags                                    | **Bad**  | Ships a false security story; use monitor mode or wait for tags         |
| Bare installer feature when a mature community/official install exists and we add no policy | **Bad**  | Maintenance without differentiation                                     |

### Capability vs parameter (quick test)

- **Parameter** (image variant, model map, python version) → `options` on an existing template.
- **Capability** (DinD, bundled Ollama service, multi-agent install set, different primary agent) → separate purpose-driven template or family member.

## How layers relate

```text
Layer A  Claude depth (rich family)
Layer B  One clean door per first-class agent
Layer C  Side-by-side evaluation (multi-ai-cli)
Layer D  Domain stacks — keep for now; re-feature or archive after agents stabilize

Growth order: stabilize A → redesign C → ship B agents → revisit D (re-feature or archive) → full catalog/registry sync
```

Phase numbers live in the portfolio epic and issue tracker; this document owns **intent**, not schedule.

## What this collection is not

- A mirror of every official language template.
- A matrix generator that multiplies agent × hardware × language without a capability story.
- A place to dump unfinished stacks “for later” without a decision gate.

## Related docs

- [Template Design Philosophy](template-design.md) — purpose-driven families and when to add templates
- [Template Catalog](../reference/template-catalog.md) — inventory and apply commands
- [Choosing a Template](../tutorials/choosing-a-template.md) — user-facing selection guide
- [Naming Conventions](naming-conventions.md) — IDs and options
- [Persistence Model](persistence-model.md) — per-agent home volumes
