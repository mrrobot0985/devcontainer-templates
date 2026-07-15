#!/bin/sh
set -e
# headless-implement.sh — Invoke /implement skill headlessly for AFK tickets.
# Usage: headless-implement.sh [project-root] [ticket-id]
# Reads: wayfinder/tickets/*.md
# Outputs: git branch with commits

PROJECT_ROOT="${1:-.}"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"
MAX_TICKETS="${MAX_TICKETS_PER_CYCLE:-3}"

run_implement() {
    local ticket_file="$1"
    local ticket_id
    local ticket_title
    local ticket_branch
    ticket_id="$(grep -E '^id:' "$ticket_file" | sed 's/id: *//' | head -1)"
    ticket_title="$(grep -E '^title:' "$ticket_file" | sed 's/title: *//' | head -1)"
    ticket_branch="$(grep -E '^branch:' "$ticket_file" | sed 's/branch: *//' | head -1)"

    echo "=== Implementing $ticket_id: $ticket_title ==="

    sed -i 's/^status: open/status: in-progress/' "$ticket_file"
    git checkout -b "$ticket_branch" 2>/dev/null || git checkout "$ticket_branch"

    SKILL_FILE="${HOME}/.claude/skills/implement/SKILL.md"
    if [ -f "$SKILL_FILE" ] && command -v claude >/dev/null 2>&1; then
        echo "Invoking /implement headlessly..."
        {
            echo "You are implementing a ticket. Follow these instructions exactly:"
            echo ""
            cat "$SKILL_FILE"
            echo ""
            echo "## Ticket"
            cat "$ticket_file"
            echo ""
            echo "Implement this ticket. Make changes to the codebase. Commit when done."
        } | claude --no-interactive || {
            echo "WARNING: Headless /implement may have failed. Check working tree."
        }
    else
        echo "WARNING: /implement skill or claude CLI unavailable. Manual execution required."
        sed -i 's/^status: in-progress/status: blocked/' "$ticket_file"
        return 1
    fi

    # Commit any changes
    if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
        git add -A
        git commit -m "feat(${ticket_id}): ${ticket_title}" || true
    fi

    sed -i 's/^status: in-progress/status: pending-review/' "$ticket_file"
    echo "$ticket_id moved to pending-review."
}

if [ -n "${2:-}" ]; then
    # Single ticket mode
    ticket_id="$2"
    ticket_file="${TICKETS_DIR}/${ticket_id}-*.md"
    if ls $ticket_file > /dev/null 2>&1; then
        ticket_file="$(ls $ticket_file | head -1)"
        run_implement "$ticket_file"
    else
        echo "ERROR: Ticket $ticket_id not found"
        exit 1
    fi
else
    # Auto-select open AFK tickets
    count=0
    for ticket in "$TICKETS_DIR"/T*.md; do
        [ -f "$ticket" ] || continue
        status="$(grep -E '^status:' "$ticket" | sed 's/status: *//' || echo "unknown")"
        type="$(grep -E '^type:' "$ticket" | sed 's/type: *//' || echo "unknown")"
        if [ "$status" = "open" ] && [ "$type" = "afk" ]; then
            blocked_by="$(grep -E '^blockedBy:' "$ticket" | sed 's/blockedBy: *//' | tr -d '[]' || echo "")"
            blocked=false
            for dep in $(echo "$blocked_by" | tr ',' ' '); do
                [ -z "$dep" ] && continue
                dep_file="${TICKETS_DIR}/${dep}-*.md"
                if ls $dep_file > /dev/null 2>&1; then
                    dep_file="$(ls $dep_file | head -1)"
                    dep_status="$(grep -E '^status:' "$dep_file" | sed 's/status: *//' || echo "unknown")"
                    if [ "$dep_status" != "complete" ] && [ "$dep_status" != "pending-review" ]; then
                        blocked=true
                        break
                    fi
                fi
            done
            if [ "$blocked" = "false" ]; then
                run_implement "$ticket"
                count=$((count + 1))
                if [ "$count" -ge "$MAX_TICKETS" ]; then
                    echo "Reached MAX_TICKETS_PER_CYCLE ($MAX_TICKETS). Stopping."
                    break
                fi
            fi
        fi
    done
    if [ "$count" -eq 0 ]; then
        echo "No unblocked open AFK tickets found."
    fi
fi
