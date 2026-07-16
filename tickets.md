# Tickets: Devcontainer Templates v1.0.0 Polish

Remaining work to get all 8 templates and CI passing cleanly before v1.0.0 release.

Work the **frontier**: any ticket whose blockers are all done. For a purely linear chain that means top to bottom.

## Verify bootstrap scripts for all 8 templates

**What to build:** Audit each template's `.devcontainer/bootstrap.sh` for completeness: check that expected tools are installed, any volume mounts are referenced, and the script exits zero. Add missing bootstrap scripts where absent. Validate with shellcheck.

**Blocked by:** None — can start immediately.

- [ ] Every template has a `.devcontainer/bootstrap.sh`
- [ ] All bootstrap scripts pass shellcheck
- [ ] Bootstrap scripts handle missing dependencies gracefully

## Validate templateOption defaults and placeholders

**What to build:** Run the `scripts/validate-templates.py` script and the `templateOption` placeholder check from the CI lint job against all 8 templates. Fix any missing defaults or orphaned placeholder references.

**Blocked by:** None — can start immediately.

- [ ] All `templateOption:*` placeholders have matching option definitions
- [ ] All options have valid default values
- [ ] `validate-templates.py` exits zero

## Regenerate READMEs and verify registry sync

**What to build:** Run `scripts/generate-template-readmes.py` and `scripts/sync-template-registry.ts` to ensure template READMEs and the registry JSON are in sync with the source files. Commit any diffs.

**Blocked by:** Verify bootstrap scripts for all 8 templates.

- [ ] `generate-template-readmes.py` produces no diffs
- [ ] `sync-template-registry.ts` produces no diffs
- [ ] All template READMEs have correct version badges and option tables

## Smoke test CI path-filter changes

**What to build:** Open a PR that touches one of the newly-added filter paths (`multi-ai-cli`, `cloud-native-k8s`, or `data-engineering-spark`) and verify the `detect-changes` job correctly identifies the changed template and runs its smoke test. Fix any workflow issues.

**Blocked by:** Regenerate READMEs and verify registry sync.

- [ ] `detect-changes` job outputs the correct template list
- [ ] Smoke test builds and runs for the changed template
- [ ] All template tests complete successfully in CI

## Tag and release v1.0.0 for all templates

**What to build:** Create a Git tag in the format `<template-id>-v1.0.0` for each of the 8 templates, push them to trigger the release workflow, and verify packages are published to GHCR. Set each published package to public visibility.

**Blocked by:** Smoke test CI path-filter changes.

- [ ] All 8 templates have `v1.0.0` tags pushed
- [ ] Release workflow completes for all tags
- [ ] Packages appear in GHCR with correct metadata
- [ ] All packages are set to public visibility
