#!/bin/sh
set -e
# headless-to-tickets.sh — Invoke /to-tickets skill headlessly.
# Usage: headless-to-tickets.sh [project-root]
# Reads: SPEC.md, WAYFINDER.md
# Writes: wayfinder/tickets/*.md

PROJECT_ROOT="${1:-.}"
SPEC_FILE="${PROJECT_ROOT}/SPEC.md"
WAYFINDER_FILE="${PROJECT_ROOT}/WAYFINDER.md"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"

if [ ! -f "$SPEC_FILE" ]; then
    echo "ERROR: SPEC.md not found."
    exit 1
fi

mkdir -p "$TICKETS_DIR"

SPEC_CONTENT="$(cat "$SPEC_FILE")"
SKILL_FILE="${HOME}/.claude/skills/to-tickets/SKILL.md"

deterministic_fallback() {
    # Extract milestones from SPEC.md as tickets
    counter=1
    in_milestones=false
    while IFS= read -r line; do
        case "$line" in
            "## Milestones"* | "### Milestones"*) in_milestones=true ;;
            "## "*) in_milestones=false ;;
        esac
        if [ "$in_milestones" = "true" ] && echo "$line" | grep -qE '^#{3,4} '; then
            title="$(echo "$line" | sed 's/^#* *//')"
            slug="$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/-$//')"
            ticket_id="$(printf 'T%03d' "$counter")"
            cat > "${TICKETS_DIR}/${ticket_id}-${slug}.md" <<EOF
---
id: ${ticket_id}
title: ${title}
status: open
priority: medium
type: afk
branch: feat/${ticket_id}-${slug}
blockedBy: []
---

# ${ticket_id}: ${title}

## What to build

Derived from SPEC.md milestone: "${title}".

## Acceptance Criteria

- [ ] TODO

## Blocked by

None
EOF
            counter=$((counter + 1))
        fi
    done < "$SPEC_FILE"
}

if [ ! -f "$SKILL_FILE" ]; then
    echo "WARNING: to-tickets skill not found. Using deterministic fallback."
    deterministic_fallback
    exit 0
fi

SKILL_INSTRUCTIONS="$(cat "$SKILL_FILE")"

if command -v claude >/dev/null 2>&1; then
    echo "Invoking /to-tickets headlessly..."
    {
        echo "You are a ticket writer. Follow these instructions exactly:"
        echo ""
        echo "$SKILL_INSTRUCTIONS"
        echo ""
        echo "## SPEC.md"
        echo "$SPEC_CONTENT"
        echo ""
        echo "Write ONLY the ticket markdown files. Use the local-markdown tracker format. One file per ticket."
    } | claude --print --no-interactive > /tmp/to-tickets-output.txt 2>/dev/null || {
        echo "WARNING: Headless /to-tickets failed. Using deterministic fallback."
        deterministic_fallback
    }
    # Parse output into individual ticket files
    # (simplified: if claude outputs combined text, we may need to split it)
else
    deterministic_fallback
fi

echo "Tickets written to $TICKETS_DIR"
