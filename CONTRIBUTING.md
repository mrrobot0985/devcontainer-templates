# Contributing

Thanks for helping improve this template collection.

## Getting started

1. Fork the repository.
1. Clone your fork and run `git config core.hooksPath .githooks`.
1. Make your changes in a branch named `<type>/<description>` (e.g. `feat/add-template-option`).

## Development

- Use `uv` for Python tooling where applicable.
- Keep changes focused on a single template or workflow at a time.
- Run the local smoke test before pushing:
  ```bash
  ./.github/actions/smoke-test/build.sh private-claude-code
  ./.github/actions/smoke-test/test.sh private-claude-code
  ```
- Validate template JSON and shell scripts with `./scripts/local-ci.sh`.

## Submitting changes

1. Write clear, conventional commit messages (`feat:`, `fix:`, `docs:`, etc.).
1. Open a pull request using the provided template.
1. Ensure all CI checks pass.

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
