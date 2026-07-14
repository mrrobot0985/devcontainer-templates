# Devcontainer Naming Conventions and Purpose-Driven Template Design

## TL;DR

Devcontainer templates have a small, strict set of naming rules and a much larger set of emergent conventions. The hard requirement from the spec is that the template `id` in `devcontainer-template.json` must match the name of the directory that contains it. Everything else is convention: IDs are overwhelmingly written in kebab-case, namespaces mirror the source repo (`<owner>/<repo>`), published references follow `<registry>/<namespace>/<id>[:<version>]`, and collections ship as `<registry>/<namespace>:latest`. Successful template collections mix generic language/base templates (`python`, `go`, `debian`) with purpose-driven combination templates (`go-postgres`, `ruby-rails-postgres`, `azure-functions-python`). The spec encourages using `options` inside a single template to avoid a proliferation of nearly identical templates.

---

## 1. The only hard naming rule: `id` must match the directory name

The [Development Container Specification](https://containers.dev/implementors/spec/) requires that every template lives in its own folder containing at least:

- `devcontainer-template.json` (metadata)
- `.devcontainer/devcontainer.json` (configuration)

The `id` field in `devcontainer-template.json` must be unique in its repository or published package, and it **must match the name of the directory** where the file resides ([Dev Container Templates reference](https://containers.dev/implementors/templates/), [devcontainer-templates.md spec](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates.md)).

Example from the official templates repo:

```text
src/
  go-postgres/
    devcontainer-template.json   ← "id": "go-postgres"
    .devcontainer/devcontainer.json
```

This single rule is what makes every other naming decision load-bearing: the directory name becomes the template's machine identity.

---

## 2. De facto naming scheme: kebab-case, lowercase, hyphenated

The spec does not mandate a character case or separator, but the official collection and the vast majority of community collections use **kebab-case**. Examples from the official `devcontainers/templates` repository:

- `javascript-node`
- `javascript-node-postgres`
- `docker-in-docker`
- `docker-outside-of-docker-compose`
- `ruby-rails-postgres`
- `kubernetes-helm-minikube`

The same pattern holds across community collections, such as `azure-functions-python`, `ansible-bitwarden-kubernetes-tofu`, `datascience-python-r`, and `go-typescript` ([containers.dev templates gallery](https://containers.dev/templates)).

Kebab-case is the practical standard because it is URL-safe, works in OCI registry references, and is readable in CLI and editor UIs.

---

## 3. Template IDs, display names, and descriptions

The metadata file separates the machine ID from the human-readable label.

Required properties in `devcontainer-template.json` are `id`, `version`, `name`, and `description`. Optional but commonly used properties include `documentationURL`, `licenseURL`, `options`, `platforms`, `publisher`, `keywords`, and `optionalPaths` ([Dev Container Templates reference](https://containers.dev/implementors/templates/)).

Official example from `src/javascript-node/devcontainer-template.json`:

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
- `name` is a friendly label, often mirroring the ID but with spaces and connectors (`&`, `-`).
- `description` states the concrete purpose and what is installed.
- `platforms` lists searchable language/platform tags.

---

## 4. Publishing and namespace conventions

Templates are distributed as OCI artifacts. The conventions are defined in the [Template Distribution spec](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates-distribution.md):

- A collection of templates lives in one repository under a `src/` directory.
- The **namespace** is a unique identifier for the collection and must be different from any Features collection in the same namespace. The common pattern is `<owner>/<repo>`, e.g. `devcontainers/templates`.
- Each template is packaged as `devcontainer-template-<id>.tgz`.
- Published reference format: `<registry>/<namespace>/<id>[:<version>]`.
- The auto-generated `devcontainer-collection.json` is published at `<registry>/<namespace>:latest`.

Examples:

```text
ghcr.io/devcontainers/templates/go:6.0.0
ghcr.io/devcontainers/templates/go-postgres:latest
ghcr.io/devcontainers/templates:latest          ← collection metadata
```

The same conventions are used by community collections, such as `ghcr.io/microsoft/datascience-py-r/datascience-python-r:1.0.0` and `ghcr.io/rocker-org/devcontainer-templates/r-ver:1.1.2` ([containers.dev templates gallery](https://containers.dev/templates)).

---

## 5. How successful collections organize templates

### 5.1 Official collection: generic + combination templates

The official `devcontainers/templates` repository contains 40 templates organized into clear categories ([containers.dev templates gallery](https://containers.dev/templates), [GitHub source tree](https://github.com/devcontainers/templates/tree/main/src)):

**Base images and operating systems:**

- `alpine`, `debian`, `ubuntu`, `universal`

**Single-language / single-runtime templates:**

- `cpp`, `dotnet`, `dotnet-fsharp`, `go`, `java`, `javascript-node`, `php`, `powershell`, `python`, `ruby`, `rust`, `typescript-node`

**Framework or content-specific templates:**

- `jekyll`, `markdown`

**Language + database combinations:**

- `go-postgres`, `java-postgres`, `javascript-node-mongo`, `javascript-node-postgres`, `php-mariadb`, `ruby-rails-postgres`, `rust-postgres`

**Docker and Kubernetes tooling templates:**

- `docker-existing-docker-compose`, `docker-existing-dockerfile`, `docker-in-docker`, `docker-outside-of-docker`, `docker-outside-of-docker-compose`, `kubernetes-helm`, `kubernetes-helm-minikube`

This structure shows that the official collection treats a template as either:

1. A **generic starting point** for a language or base image, or
2. A **purpose-driven combination** of a language/runtime with a specific database, tool, or deployment target.

### 5.2 Community collections: highly purpose-driven names

The public index currently lists 168 templates from many maintainers ([containers.dev templates gallery](https://containers.dev/templates)). Community templates tend to use longer, more descriptive IDs that name a specific stack, product, or job-to-be-done:

- Product/platform scoped: `azure-functions-python`, `aws-lambda-dotnet`, `sap-cap-typescript-node`
- Multi-tool stacks: `ansible-bitwarden-kubernetes-tofu`, `dotnet-node-mssql`
- Role or workflow scoped: `github-actions-runner-devcontainer`, `azure-pipelines-agent-devcontainer`
- Hardware/target scoped: `esp-idf`, `ros2-workspace`, `viper-ic-analog`

These names reveal a pattern: when a template is maintained outside the core set, its ID is usually chosen to be discoverable by someone searching for that exact product or workflow.

---

## 6. Purpose-driven vs. generic templates

### 6.1 Generic templates

Generic templates optimize for breadth. They typically:

- Target a single language, base image, or runtime.
- Expose `options` for version variants rather than creating a new template per version.
- Use short IDs: `python`, `go`, `java`, `debian`.

Example from the official `python` template:

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

([src/python/devcontainer-template.json](https://github.com/devcontainers/templates/tree/main/src/python))

### 6.2 Purpose-driven templates

Purpose-driven templates optimize for a specific outcome. They typically:

- Combine multiple services or tools into one ready-to-use environment.
- Use compound IDs that name the stack: `go-postgres`, `ruby-rails-postgres`, `docker-in-docker`.
- Include extra services in a Docker Compose file rather than a single container.

Example from the official `ruby-rails-postgres` template:

```json
{
  "id": "ruby-rails-postgres",
  "name": "Ruby on Rails & Postgres",
  "description": "Develop Ruby on Rails applications with Postgres. Includes a Rails application container and PostgreSQL server.",
  "platforms": ["Ruby"]
}
```

([src/ruby-rails-postgres/devcontainer-template.json](https://github.com/devcontainers/templates/tree/main/src/ruby-rails-postgres))

### 6.3 Using `options` to avoid template sprawl

The spec explicitly supports the `options` property so that a single generic template can cover many variants. This is the recommended way to avoid a flood of nearly identical templates ([Dev Container Templates reference](https://containers.dev/implementors/templates/)).

When a use case cannot be captured by a few boolean or string options, the convention is to create a separate purpose-driven template instead.

---

## 7. Common naming patterns observed across collections

From the official and community indexes, the following patterns appear consistently:

| Pattern | Examples | Use case |
|---|---|---|
| Base image / OS | `alpine`, `debian`, `ubuntu`, `universal` | Minimal starting environment |
| Single language/runtime | `python`, `go`, `java`, `rust`, `dotnet` | Language-specific development |
| Language variant | `dotnet-fsharp`, `typescript-node` | Same runtime family, different primary language |
| Language + database | `go-postgres`, `java-postgres`, `python-mssql` | Full-stack development with a database |
| Framework + database | `ruby-rails-postgres` | Framework-specific full-stack setup |
| Tooling role | `docker-in-docker`, `docker-outside-of-docker`, `kubernetes-helm` | Operations or infrastructure tooling |
| Product/platform | `azure-functions-python`, `aws-lambda-dotnet`, `sap-cap-typescript-node` | Vendor- or product-specific setup |
| Workflow/job | `github-actions-runner-devcontainer`, `datascience-python-r` | Specific team workflow |

There is no evidence in the spec or official tooling of mandated prefixes such as `lang-`, `stack-`, or `role-`. The community generally prefers self-describing compound names over category prefixes.

---

## 8. Directory and file layout conventions

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

([template-starter README](https://github.com/devcontainers/template-starter), [Dev Container Templates reference](https://containers.dev/implementors/templates/))

The `test` folder mirrors the `src` folder so that every template has an identically named test directory. The `devcontainer-template.json` is the source of truth for generated `README.md` files in many starter workflows.

---

## 9. Multiple devcontainer configurations in one repo

While templates are packaged from `src/<id>/`, a consuming repository can host multiple devcontainer configurations for GitHub Codespaces or VS Code. GitHub's documentation recommends placing alternative configurations in subdirectories under `.devcontainer/`:

```text
.devcontainer/
  devcontainer.json              ← default
  database-dev/devcontainer.json ← alternative
  gui-dev/devcontainer.json      ← alternative
```

([GitHub Docs: Setting up a template repository for GitHub Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/setting-up-your-repository/setting-up-a-template-repository-for-github-codespaces))

This convention is for repository-local configurations, not for published template collections, but it shows the same kebab-case naming habit in subdirectory names.

---

## 10. Recommendations for this repository

Based on the primary sources above:

1. **Use kebab-case for every template ID and directory name.** It is the de facto standard across the official and community indexes.
2. **Make the directory name and `id` identical.** This is the only spec-level naming requirement.
3. **Prefer self-describing compound IDs over category prefixes.** Names like `python-postgres` or `datascience-python-r` are clearer than `lang-python-db-postgres`.
4. **Distinguish generic from purpose-driven templates.** Generic templates should expose `options` for common variants; purpose-driven templates should name the specific stack or workflow.
5. **Mirror directory names in `test/` and keep the namespace aligned with the repo path.** This matches the `src/<id>` and `<owner>/<repo>` conventions used by the official tooling.
6. **Keep template collections separate from feature collections.** The spec requires different namespaces for templates and features ([Template Distribution spec](https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates-distribution.md)).

---

## Sources

- <https://containers.dev/implementors/spec/>
- <https://containers.dev/implementors/templates/>
- <https://containers.dev/implementors/templates-distribution/>
- <https://containers.dev/templates>
- <https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates.md>
- <https://github.com/devcontainers/spec/blob/main/docs/specs/devcontainer-templates-distribution.md>
- <https://github.com/devcontainers/templates/tree/main/src>
- <https://github.com/devcontainers/template-starter>
- <https://github.com/devcontainers/feature-starter>
- <https://github.com/devcontainers/cli/tree/main/src/spec-node/templatesCLI>
- <https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/setting-up-your-repository/setting-up-a-template-repository-for-github-codespaces>
- <https://code.visualstudio.com/docs/devcontainers/create-dev-container>
