#!/bin/sh
set -e
# headless-to-spec.sh — Invoke /to-spec skill headlessly for AFK automation.
# Usage: headless-to-spec.sh [project-root]
# Requires: claude CLI, mattpocock/skills installed in ~/.claude/skills/
# Reads: README.md, existing code, docs/
# Writes: SPEC.md

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"

if [ -f "$SPEC_FILE" ] && [ "${FORCE:-false}" != "true" ]; then
    echo "SPEC.md exists. Set FORCE=true to overwrite."
    exit 0
fi

# Build context from project files
CONTEXT=""
for f in "$PROJECT_ROOT/README.md" "$PROJECT_ROOT/CONTEXT.md" "$PROJECT_ROOT/docs/adr/"*.md; do
    [ -f "$f" ] || continue
    CONTEXT="${CONTEXT}\n## $(basename "$f")\n\n$(cat "$f")\n"
done

# Load Matt Pocock's to-spec skill instructions
SKILL_FILE="${HOME}/.claude/skills/to-spec/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
    echo "WARNING: to-spec skill not found at $SKILL_FILE"
    echo "Run /setup-matt-pocock-skills first."
    exit 1
fi

SKILL_INSTRUCTIONS="$(cat "$SKILL_FILE")"

write_stub_spec() {
    cat > "$SPEC_FILE" <<'EOF'
# SPEC.md

## Summary

TODO: one-paragraph summary

## Goals

- TODO

## Non-Goals

- TODO

## Architecture

TODO

## Milestones

### Milestone 1: Foundation
- [ ] TODO

### Milestone 2: Core Feature
- [ ] TODO

### Milestone 3: Polish
- [ ] TODO

## Risks

- TODO
EOF
}

# Invoke claude headlessly
if command -v claude >/dev/null 2>&1; then
    echo "Invoking /to-spec headlessly..."
    {
        echo "You are a technical specification writer. Follow these instructions exactly:"
        echo ""
        echo "$SKILL_INSTRUCTIONS"
        echo ""
        echo "## Project Context"
        echo "$CONTEXT"
        echo ""
        echo "Write the SPEC.md to stdout. Do not ask questions. Do not interview. Synthesize and output."
    } | claude --print --no-interactive > "$SPEC_FILE" 2>/dev/null || {
        echo "ERROR: Headless /to-spec failed. Falling back to stub."
        write_stub_spec
    }
else
    echo "WARNING: claude CLI not found. Writing stub SPEC.md."
    write_stub_spec
fi

echo "SPEC.md written to $SPEC_FILE"
