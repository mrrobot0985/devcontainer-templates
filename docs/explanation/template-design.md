# Template Design Philosophy

This collection deliberately contains only two templates: a minimal environment and a full studio environment. The goal is to give users a clear, purpose-driven choice rather than a menu of similar configurations that differ by one or two features.

## Purpose-driven vs generic templates

Devcontainer template collections usually fall into two categories:

- **Generic templates** provide a single language, runtime, or base image. They expose options for common variants rather than creating a new template for every version.
- **Purpose-driven templates** combine multiple tools into a ready-to-use environment for a specific workflow. Their IDs name the stack or outcome they deliver.

The official `devcontainers/templates` repository follows this pattern: generic templates like `python` and `go` sit alongside purpose-driven templates like `go-postgres` and `ruby-rails-postgres`.

## Why only two templates exist

The two templates represent the two meaningful entry points for this stack:

1. **`ollama-claude-cli`** — the minimal environment. It gives you Claude CLI, a pre-configured Ollama backend, privacy defaults, and persistent settings. Choose this when you only need the CLI and nothing else.

1. **`ollama-claude-cli-studio`** — the full workspace. It adds Docker-in-Docker, NVIDIA Container Toolkit, lifecycle hooks, behavior rules, skills, and plugins. Choose this when you need the surrounding tooling that supports a complete local Claude workflow.

The line between them is the Docker daemon. Once you need Docker-in-Docker or GPU tooling inside inner containers, the environment changes enough to justify a separate template rather than a set of options.

## Using options to avoid sprawl

The Dev Container Specification supports an `options` object in `devcontainer-template.json` so a single template can cover variants. This collection uses `options` for the Ubuntu base image version (`imageVariant`) because the underlying environment does not change meaningfully between `jammy` and `focal`.

Options are the right tool when the difference is a parameter. A new template is the right tool when the difference is a capability. For example, adding Docker-in-Docker changes what the container can do, so it belongs in the studio template rather than as an option on the minimal template.

## Consequences of the design

- **Fewer decisions.** Users pick an environment by scope, not by feature checklist.
- **Simpler maintenance.** Each template has a coherent identity and a single smoke test.
- **Easier releases.** Template tags map one-to-one to a complete environment.

This approach trades exhaustive customizability for clarity. If a future workflow does not fit either existing template, the collection will add a third purpose-driven template rather than adding options to an existing one.
