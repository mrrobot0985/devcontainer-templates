# Template Design Philosophy

This collection ships **purpose-driven template families**, not a single pair of environments and not a flat menu of near-duplicates. Each template exists because it delivers a distinct workflow or capability. Related templates form a **family** when they share an agent or mission but differ by a real capability boundary (for example GPU vs CPU, host Ollama vs Compose, minimal vs studio).

The portfolio layers (Claude depth, agent entry points, multi-agent evaluation, deferred domain stacks) are defined in [Template Portfolio](template-portfolio.md). This document explains **how** templates are designed inside that portfolio.

## Purpose-driven vs generic templates

Devcontainer template collections usually fall into two categories:

- **Generic templates** provide a single language, runtime, or base image. They expose options for common variants rather than creating a new template for every version.
- **Purpose-driven templates** combine multiple tools into a ready-to-use environment for a specific workflow. Their IDs name the stack or outcome they deliver.

The official `devcontainers/templates` repository follows this pattern: generic templates like `python` and `go` sit alongside purpose-driven templates like `go-postgres` and `ruby-rails-postgres`.

**This collection is purpose-driven.** Templates are named for agents and workflows (`ollama-claude-cli-studio`, `multi-ai-cli`, planned `grok-build-cli`), not for “Ubuntu plus a package list.”

## Families, not sprawl

A **family** is a set of templates that share one primary agent or mission and differ only where capability changes:

| Family | Role in the portfolio |
| ------ | --------------------- |
| `ollama-claude-cli*` (Layer A) | Deep Claude + Ollama stack; richest variant set because owned features justify each member |
| Dedicated agent entry points (Layer B) | One minimal door per first-class agent; studio only when needed |
| `multi-ai-cli` (Layer C) | Single multi-agent evaluation workspace |
| Domain stacks (Layer D) | Provisional k8s/spark templates; fate deferred — not a growth pattern yet |

Families grow when a new member answers a question users actually ask (“I have no GPU,” “I need DinD,” “I want several agents side by side”). Families do **not** grow by cloning an entire matrix onto every new agent.

### Why Layer A has more members

Claude is where this monorepo’s owned features are deepest (backend, privacy, hooks, rules, skills, plugins). That depth makes separate templates for CPU, Compose-bundled Ollama, Python AI tooling, and studio/DinD **capability** differences, not cosmetic forks.

### Why Layer B stays thin

Most other agents are API-first. A dedicated **minimal** template (install + security floor + home persistence) is enough for a first-class entry point. A **studio** sibling is optional. Replicating cpu/gpu/compose/python for each agent is almost always the wrong trade.

## Using options to avoid sprawl

The Dev Container Specification supports an `options` object in `devcontainer-template.json` so a single template can cover variants. This collection uses `options` for differences that do not change the environment’s identity, for example:

- Ubuntu base image version (`imageVariant`)
- Model map overrides for Ollama-backed Claude templates (`modelMap`)
- Python version on the Claude + Python template (`pythonVersion`)

**Rule of thumb:**

- **Parameter** → option on an existing template.
- **Capability** (Docker-in-Docker, different primary agent, multi-agent install set, bundled vs host Ollama) → separate purpose-driven template or family member.

Adding Docker-in-Docker, for example, changes what the container can do. That belongs in a studio template (or a clearly named sibling), not as a quiet boolean on every minimal template unless the family is deliberately designed that way.

## Security and differentiation floor

Purpose-driven does not mean “install the CLI and stop.” Templates in Layers A–C should reflect monorepo differentiators where they apply:

- **Agent-agnostic floor:** non-root enforcement, sandbox/audit posture, container firewall with correct provider tags (or honest monitor mode until tags exist).
- **Agent-specific configuration:** only for the agent the template owns (Claude suite features stay on Claude templates).
- **Persistence:** named volumes for the agent home directory so rebuilds do not wipe auth and settings (see [Persistence Model](persistence-model.md)).

Do not ship a security feature that pretends to protect every agent while only wiring Claude domains or deleted feature IDs.

## Consequences of the design

- **Clear decisions.** Users pick a family and then a member by hardware or scope, not a fifty-row feature matrix.
- **Coherent maintenance.** Each template has an identity, a smoke path, and a known layer.
- **Controlled growth.** New agents get Layer B entry points (and optional multi-ai inclusion), not a copy of the entire Claude matrix.
- **Honest catalog.** Provisional Layer D templates are labeled as such until re-feature or archive.

This approach trades exhaustive customizability for clarity. When a future workflow does not fit an existing family member, add a **purpose-driven** template (or family member) with a capability story — not an options dump and not an unowned domain clone.

## Related docs

- [Template Portfolio](template-portfolio.md) — mission, layers A–D, sense matrix
- [Template Catalog](../reference/template-catalog.md) — current inventory
- [Naming Conventions](naming-conventions.md) — IDs, display names, options
