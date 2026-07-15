#!/bin/sh
set -e
# headless-wayfinder.sh — Invoke /wayfinder skill headlessly.
# Usage: headless-wayfinder.sh [project-root]
# Reads: SPEC.md
# Writes: WAYFINDER.md, wayfinder/map.yaml

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"
WAYFINDER_FILE="${PROJECT_ROOT}/WAYFINDER.md"

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: SPEC.md not found. Run headless-to-spec.sh first."
    exit 1
fi

if [ -f "$WAYFINDER_FILE" ] && [ "${FORCE:-false}" != "true" ]; then
    echo "WAYFINDER.md exists. Set FORCE=true to overwrite."
    exit 0
fi

SPEC_CONTENT="$(cat "$SPEC_FILE")"
SKILL_FILE="${HOME}/.claude/skills/wayfinder/SKILL.md"

write_stub_wayfinder() {
    cat > "$WAYFINDER_FILE" <<'EOF'
# Wayfinder Map

## Destination

See SPEC.md Summary.

## Notes

- Skills: /wayfinder, /grilling, /domain-modeling

## Decisions so far

## Not yet specified

## Out of scope
EOF
    mkdir -p "${PROJECT_ROOT}/wayfinder"
    echo "destination: see SPEC.md" > "${PROJECT_ROOT}/wayfinder/map.yaml"
}

if [ ! -f "$SKILL_FILE" ]; then
    echo "WARNING: wayfinder skill not found. Writing stub WAYFINDER.md."
    write_stub_wayfinder
    exit 0
fi

SKILL_INSTRUCTIONS="$(cat "$SKILL_FILE")"

if command -v claude >/dev/null 2>&1; then
    echo "Invoking /wayfinder headlessly..."
    {
        echo "You are a wayfinder. Follow these instructions exactly:"
        echo ""
        echo "$SKILL_INSTRUCTIONS"
        echo ""
        echo "## SPEC.md Content"
        echo "$SPEC_CONTENT"
        echo ""
        echo "Chart the wayfinder map. Write ONLY the map markdown to stdout. No narration."
    } | claude --print --no-interactive > "$WAYFINDER_FILE" 2>/dev/null || {
        echo "WARNING: Headless /wayfinder failed. Writing stub."
        write_stub_wayfinder
    }
else
    write_stub_wayfinder
fi

echo "WAYFINDER.md written to $WAYFINDER_FILE"
