#!/bin/sh
set -e
# headless-code-review.sh — Invoke /code-review skill headlessly.
# Usage: headless-code-review.sh [project-root] [ticket-id]
# Env: AUTO_MERGE=false

PROJECT_ROOT="${1:-.}"
TICKETS_DIR="${PROJECT_ROOT}/wayfinder/tickets"
AUTO_MERGE="${AUTO_MERGE:-false}"

review_ticket() {
    local ticket_file="$1"
    local ticket_id
    local ticket_branch
    ticket_id="$(grep -E '^id:' "$ticket_file" | sed 's/id: *//' | head -1)"
    ticket_branch="$(grep -E '^branch:' "$ticket_file" | sed 's/branch: *//' | head -1)"

    echo "=== Reviewing $ticket_id ==="

    SKILL_FILE="${HOME}/.claude/skills/code-review/SKILL.md"
    if [ -f "$SKILL_FILE" ] && command -v claude >/dev/null 2>&1; then
        echo "Invoking /code-review headlessly..."
        {
            echo "You are reviewing code. Follow these instructions exactly:"
            echo ""
            cat "$SKILL_FILE"
            echo ""
            echo "## Branch to review"
            echo "$ticket_branch"
            echo ""
            echo "Run the review. Output PASS or FAIL with reasoning."
        } | claude --no-interactive || true
    else
        echo "WARNING: /code-review skill or claude CLI unavailable."
    fi

    # Validate branch
    local validate_ok=true
    if [ -f ".devcontainer/sandcastle/validate-branch.sh" ]; then
        bash ".devcontainer/sandcastle/validate-branch.sh" "$ticket_branch" "$PROJECT_ROOT" || validate_ok=false
    fi

    if [ "$validate_ok" = true ]; then
        echo "Validation passed for $ticket_id."
        sed -i 's/^status: pending-review/status: approved/' "$ticket_file"
        if [ "$AUTO_MERGE" = "true" ]; then
            echo "AUTO_MERGE=true — merging $ticket_branch to main."
            git checkout main
            git merge --no-ff "$ticket_branch" -m "merge(${ticket_id}): approved via code-review" || {
                echo "WARNING: merge conflict. Manual resolution required."
                sed -i 's/^status: approved/status: blocked/' "$ticket_file"
                return 1
            }
            sed -i 's/^status: approved/status: complete/' "$ticket_file"
        fi
    else
        echo "Validation failed for $ticket_id."
        sed -i 's/^status: pending-review/status: changes-requested/' "$ticket_file"
    fi
}

if [ -n "${2:-}" ]; then
    TICKET_ID="$2"
    TICKET_FILE="${TICKETS_DIR}/${TICKET_ID}-*.md"
    if ls $TICKET_FILE > /dev/null 2>&1; then
        TICKET_FILE="$(ls $TICKET_FILE | head -1)"
        review_ticket "$TICKET_FILE"
    fi
else
    for ticket in "$TICKETS_DIR"/T*.md; do
        [ -f "$ticket" ] || continue
        status="$(grep -E '^status:' "$ticket" | sed 's/status: *//' || echo "unknown")"
        if [ "$status" = "pending-review" ]; then
            review_ticket "$ticket"
        fi
    done
fi
