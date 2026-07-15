#!/bin/bash
set -euo pipefail

# ralph-loop.sh — Sandcastle-native ralph loop for AFK ticket execution.
#
# Usage: ralph-loop.sh <ticket-id> <branch> <iteration>
#
# Reads task state from .ralph/state/<ticket-id>.json, runs the sandcastle
# runner inside a Docker container, verifies, commits, and updates state.

TICKET_ID="${1:-}"
BRANCH="${2:-main}"
ITERATION="${3:-1}"
WORKSPACE="$(pwd)"
STATE_DIR="$WORKSPACE/.ralph/state"
LOG_DIR="$WORKSPACE/.ralph/logs"

if [ -z "$TICKET_ID" ]; then
    echo "Usage: ralph-loop.sh <ticket-id> [<branch>] [<iteration>]"
    exit 1
fi

STATE_FILE="$STATE_DIR/${TICKET_ID}.json"
LOG_FILE="$LOG_DIR/${TICKET_ID}-iter${ITERATION}.log"

mkdir -p "$STATE_DIR" "$LOG_DIR"

if [ ! -f "$STATE_FILE" ]; then
    echo "ERROR: State file not found: $STATE_FILE"
    exit 1
fi

TASK="$(jq -r '.task' "$STATE_FILE" 2>/dev/null || echo "unknown")"
STATUS="$(jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "open")"

echo "=== Ralph Loop Iteration $ITERATION for $TICKET_ID ==="
echo "Task:   $TASK"
echo "Status: $STATUS"
echo ""

if [ "$STATUS" = "complete" ]; then
    echo "Ticket $TICKET_ID is already complete. Skipping."
    exit 0
fi

if [ "$STATUS" = "blocked" ]; then
    echo "Ticket $TICKET_ID is blocked. Needs human intervention."
    exit 2
fi

# Run the sandcastle runner
if command -v node >/dev/null 2>&1 && [ -f ".devcontainer/sandcastle/runner.mjs" ]; then
    node .devcontainer/sandcastle/runner.mjs \
        --ticket "$TICKET_ID" \
        --task "$TASK" \
        --iteration "$ITERATION" \
        --workspace "$WORKSPACE" > "$LOG_FILE" 2>&1
else
    echo "No sandcastle runner available. Task would be: $TASK"
    echo "Mark this ticket for manual execution."
    jq --arg iter "$ITERATION" '.iteration = ($iter | tonumber) | .status = "blocked" | .reason = "No runner available"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    exit 1
fi

# Verify
VERIFY_OK=true
if [ -f "package.json" ] && command -v npm >/dev/null 2>&1; then
    npm test --if-present >/dev/null 2>&1 || VERIFY_OK=false
    npm run lint --if-present >/dev/null 2>&1 || true
fi

if [ -f "pytest.ini" ] || [ -f "setup.cfg" ] || [ -f "pyproject.toml" ]; then
    if command -v pytest >/dev/null 2>&1; then
        pytest >/dev/null 2>&1 || VERIFY_OK=false
    fi
fi

# Commit iteration
if [ -n "$(git status --porcelain 2>/dev/null || true)" ]; then
    git config user.name "Ralph Loop" 2>/dev/null || true
    git config user.email "ralph@localhost" 2>/dev/null || true
    git add -A
    git commit -m "ralph(${TICKET_ID}): iteration ${ITERATION} complete" 2>/dev/null || true
    git tag -f "ralph-${TICKET_ID}-iter${ITERATION}" 2>/dev/null || true
fi

# Update state
if [ "$VERIFY_OK" = true ]; then
    jq --arg iter "$ITERATION" '.iteration = ($iter | tonumber) | .status = "pending-review" | del(.reason)' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "Ticket $TICKET_ID updated to pending-review."
else
    jq --arg iter "$ITERATION" '.iteration = ($iter | tonumber) | .status = "blocked" | .reason = "Verification failed"' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
    echo "Ticket $TICKET_ID blocked: verification failed."
    exit 2
fi

echo "=== Ralph loop complete ==="
