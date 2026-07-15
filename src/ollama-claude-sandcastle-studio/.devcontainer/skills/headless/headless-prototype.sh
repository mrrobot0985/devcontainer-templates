#!/bin/sh
set -e
# headless-prototype.sh — Invoke /prototype skill headlessly.
# Usage: headless-prototype.sh <question> [project-root]
# Reads: surrounding code context
# Writes: prototype files near the module being prototyped

PROJECT_ROOT="${2:-.}"
QUESTION="${1:-}"

if [ -z "$QUESTION" ]; then
    echo "Usage: headless-prototype.sh <question> [project-root]"
    echo "Example: headless-prototype.sh 'Does this state machine feel right?'"
    exit 1
fi

SKILL_FILE="${HOME}/.claude/skills/prototype/SKILL.md"
if [ ! -f "$SKILL_FILE" ]; then
    echo "WARNING: prototype skill not found at $SKILL_FILE"
    exit 1
fi

SKILL_INSTRUCTIONS="$(cat "$SKILL_FILE")"

if command -v claude >/dev/null 2>&1; then
    echo "Invoking /prototype headlessly for: $QUESTION"
    {
        echo "You are prototyping. Follow these instructions exactly:"
        echo ""
        echo "$SKILL_INSTRUCTIONS"
        echo ""
        echo "## Question to answer"
        echo "$QUESTION"
        echo ""
        echo "Build the prototype. Mark it clearly as throwaway. Make it runnable in one command."
    } | claude --no-interactive || {
        echo "WARNING: Headless /prototype may have failed."
    }
else
    echo "WARNING: claude CLI not found. Cannot prototype."
    exit 1
fi
