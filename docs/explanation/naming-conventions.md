# Devcontainer Naming Conventions

Devcontainer templates have one strict naming rule and a much larger set of emergent conventions. Understanding both helps you choose clear, discoverable IDs when adding templates to this collection.

## The only hard rule: `id` must match the directory name

The [Development Container Specification](https://containers.dev/implementors/spec/) requires that every template lives in its own folder containing at least:

- `devcontainer-template.json` (metadata)
- `.devcontainer/devcontainer.json` (configuration)

The `id` field in `devcontainer-template.json` must be unique in its repository or published package, and it must match the name of the directory where the file resides. This single rule makes every other naming decision load-bearing: the directory name becomes the template's machine identity.

Example layout:

```text
src/
  go-postgres/
    devcontainer-template.json   ← "id": "go-postgres"
    .devcontainer/devcontainer.json
```

## De facto naming scheme: kebab-case, lowercase, hyphenated

The spec does not mandate character case or separators, but the official collection and most community collections use **kebab-case**. Examples from the official `devcontainers/templates` repository include:

- `javascript-node`
- `javascript-node-postgres`
- `docker-in-docker`
- `docker-outside-of-docker-compose`
- `ruby-rails-postgres`
- `kubernetes-helm-minikube`

Kebab-case is the practical standard because it is URL-safe, works in OCI registry references, and is readable in CLI and editor UIs.

## Template IDs, display names, and descriptions

The metadata file separates the machine ID from the human-readable label.

Required properties in `devcontainer-template.json` are `id`, `version`, `name`, and `description`. Optional but commonly used properties include `documentationURL`, `licenseURL`, `options`, `platforms`, `publisher`, `keywords`, and `optionalPaths`.

Official example:

```json
{
  "id": "javascript-node",
  "version": "5.0.0",
  "name": "Node.js & JavaScript",
  "description": "Develop Node.js based applications. Includes Node.js, eslint, nvm, and yarn.",
  "publisher": "Dev Container Spec Maintainers",
  "platforms": ["Node.js", "JavaScript"]
}
```

The pattern is:

- `id` is the kebab-case directory name.
- `name` is a friendly label, often mirroring the ID but with spaces and connectors.
- `description` states the concrete purpose and what is installed.
- `platforms` lists searchable language or platform tags.

## Publishing and namespace conventions

Templates are distributed as OCI artifacts. The conventions are defined in the Template Distribution spec:

- A collection of templates lives in one repository under a `src/` directory.
- The namespace is a unique identifier for the collection and must differ from any features collection in the same namespace. The common pattern is `<owner>/<repo>`, for example `devcontainers/templates`.
- Each template is packaged as `devcontainer-template-<id>.tgz`.
- Published reference format: `<registry>/<namespace>/<id>[:<version>]`.
- The auto-generated `devcontainer-collection.json` is published at `<registry>/<namespace>:latest`.

Examples:

```text
ghcr.io/devcontainers/templates/go:6.0.0
ghcr.io/devcontainers/templates/go-postgres:latest
ghcr.io/devcontainers/templates:latest          ← collection metadata
```

This collection follows the same pattern:

```text
ghcr.io/mrrobot0985/devcontainer-templates/ollama-claude-cli:latest
ghcr.io/mrrobot0985/devcontainer-templates:latest
```

## How successful collections organize templates

### Official collection: generic plus combination templates

The official `devcontainers/templates` repository contains templates organized into clear categories:

**Base images and operating systems:**

- `alpine`, `debian`, `ubuntu`, `universal`

**Single-language / single-runtime templates:**

- `cpp`, `dotnet`, `dotnet-fsharp`, `go`, `java`, `javascript-node`, `php`, `powershell`, `python`, `ruby`, `rust`, `typescript-node`

**Framework or content-specific templates:**

- `jekyll`, `markdown`

**Language plus database combinations:**

- `go-postgres`, `java-postgres`, `javascript-node-mongo`, `javascript-node-postgres`, `php-mariadb`, `ruby-rails-postgres`, `rust-postgres`

**Docker and Kubernetes tooling templates:**

- `docker-existing-docker-compose`, `docker-existing-dockerfile`, `docker-in-docker`, `docker-outside-of-docker`, `docker-outside-of-docker-compose`, `kubernetes-helm`, `kubernetes-helm-minikube`

This structure shows that the official collection treats a template as either a generic starting point for a language or base image, or a purpose-driven combination of a language/runtime with a specific database, tool, or deployment target.

### Community collections: highly purpose-driven names

Community templates tend to use longer, more descriptive IDs that name a specific stack, product, or job-to-be-done:

- Product or platform scoped: `azure-functions-python`, `aws-lambda-dotnet`, `sap-cap-typescript-node`
- Multi-tool stacks: `ansible-bitwarden-kubernetes-tofu`, `dotnet-node-mssql`
- Role or workflow scoped: `github-actions-runner-devcontainer`, `azure-pipelines-agent-devcontainer`
- Hardware or target scoped: `esp-idf`, `ros2-workspace`, `viper-ic-analog`

When a template is maintained outside the core set, its ID is usually chosen to be discoverable by someone searching for that exact product or workflow.

## Purpose-driven vs generic templates

### Generic templates

Generic templates optimize for breadth. They typically:

- Target a single language, base image, or runtime.
- Expose `options` for version variants rather than creating a new template per version.
- Use short IDs: `python`, `go`, `java`, `debian`.

Example:

```json
{
  "id": "python",
  "name": "Python 3",
  "description": "Develop Python 3 applications.",
  "options": {
    "imageVariant": {
      "type": "string",
      "description": "Python version...",
      "proposals": ["3-trixie", "3.14-trixie", "3.13-trixie"],
      "default": "3.14-trixie"
    }
  }
}
```

### Purpose-driven templates

Purpose-driven templates optimize for a specific outcome. They typically:

- Combine multiple services or tools into one ready-to-use environment.
- Use compound IDs that name the stack: `go-postgres`, `ruby-rails-postgres`, `docker-in-docker`.
- Include extra services in a Docker Compose file rather than a single container.

Example:

```json
{
  "id": "ruby-rails-postgres",
  "name": "Ruby on Rails & Postgres",
  "description": "Develop Ruby on Rails applications with Postgres. Includes a Rails application container and PostgreSQL server.",
  "platforms": ["Ruby"]
}
```

### Using `options` to avoid template sprawl

The spec explicitly supports the `options` property so a single generic template can cover many variants. This is the recommended way to avoid a flood of nearly identical templates. When a use case cannot be captured by a few boolean or string options, the convention is to create a separate purpose-driven template instead.

## Common naming patterns

Across the official and community indexes, the following patterns appear consistently:

| Pattern                 | Examples                                                                 | Use case                                        |
| ----------------------- | ------------------------------------------------------------------------ | ----------------------------------------------- |
| Base image / OS         | `alpine`, `debian`, `ubuntu`, `universal`                                | Minimal starting environment                    |
| Single language/runtime | `python`, `go`, `java`, `rust`, `dotnet`                                 | Language-specific development                   |
| Language variant        | `dotnet-fsharp`, `typescript-node`                                       | Same runtime family, different primary language |
| Language + database     | `go-postgres`, `java-postgres`, `python-mssql`                           | Full-stack development with a database          |
| Framework + database    | `ruby-rails-postgres`                                                    | Framework-specific full-stack setup             |
| Tooling role            | `docker-in-docker`, `docker-outside-of-docker`, `kubernetes-helm`        | Operations or infrastructure tooling            |
| Product/platform        | `azure-functions-python`, `aws-lambda-dotnet`, `sap-cap-typescript-node` | Vendor- or product-specific setup               |
| Workflow/job            | `github-actions-runner-devcontainer`, `datascience-python-r`             | Specific team workflow                          |

There is no evidence in the spec or official tooling of mandated prefixes such as `lang-`, `stack-`, or `role-`. The community generally prefers self-describing compound names over category prefixes.

## Directory and file layout conventions

The standard repository layout is used by both `devcontainers/templates` and `devcontainers/template-starter`:

```text
repo-root/
  src/
    <template-id>/
      devcontainer-template.json
      .devcontainer/
        devcontainer.json
      NOTES.md                 ← optional, used for generated docs
      README.md                ← often auto-generated
  test/
    <template-id>/
      test.sh
  .github/
    workflows/
      ...
```

The `test` folder mirrors the `src` folder so that every template has an identically named test directory. The `devcontainer-template.json` is the source of truth for generated `README.md` files in many starter workflows.

## Multiple devcontainer configurations in one repo

While templates are packaged from `src/<id>/`, a consuming repository can host multiple devcontainer configurations for GitHub Codespaces or VS Code:. GitHub recommends placing alternative configurations in subdirectories under `.devcontainer/`:

```text
.devcontainer/
  devcontainer.json              ← default
  database-dev/devcontainer.json ← alternative
  gui-dev/devcontainer.json      ← alternative
```

This convention is for repository-local configurations, not for published template collections, but it shows the same kebab-case naming habit in subdirectory names.

## Recommendations for this repository

1. Use kebab-case for every template ID and directory name.
1. Make the directory name and `id` identical.
1. Prefer self-describing compound IDs over category prefixes.
1. Distinguish generic from purpose-driven templates: use `options` for common variants and new templates for distinct stacks or workflows.
1. Mirror directory names in `test/` and keep the namespace aligned with the repo path.
1. Keep template collections separate from feature collections. The spec requires different namespaces for templates and features.
