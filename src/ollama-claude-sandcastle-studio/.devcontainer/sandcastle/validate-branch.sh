#!/bin/bash
set -euo pipefail

# validate-branch.sh — Branch-type bound validation for sandcastle.
#
# Usage: validate-branch.sh <branch-name> <workspace-path>
#
# Validates:
#   - Branch naming convention (feat/*, fix/*, chore/*, docs/*, ci/*, refactor/*, test/*)
#   - Conventional commits on the branch vs origin/main
#   - Per-branch type requirements (feat needs spec, fix needs tests, etc.)

BRANCH="${1:-}"
WORKSPACE="${2:-$(pwd)}"

if [ -z "$BRANCH" ]; then
    echo "Usage: validate-branch.sh <branch-name> [<workspace-path>]"
    exit 1
fi

cd "$WORKSPACE"

# Detect branch type
BRANCH_TYPE="unknown"
if echo "$BRANCH" | grep -qE '^feat/'; then
    BRANCH_TYPE="feat"
elif echo "$BRANCH" | grep -qE '^fix/'; then
    BRANCH_TYPE="fix"
elif echo "$BRANCH" | grep -qE '^chore/'; then
    BRANCH_TYPE="chore"
elif echo "$BRANCH" | grep -qE '^docs/'; then
    BRANCH_TYPE="docs"
elif echo "$BRANCH" | grep -qE '^ci/'; then
    BRANCH_TYPE="ci"
elif echo "$BRANCH" | grep -qE '^refactor/'; then
    BRANCH_TYPE="refactor"
elif echo "$BRANCH" | grep -qE '^test/'; then
    BRANCH_TYPE="test"
fi

if [ "$BRANCH_TYPE" = "unknown" ]; then
    echo "ERROR: Branch '$BRANCH' does not follow conventional naming."
    echo "Expected: feat/*, fix/*, chore/*, docs/*, ci/*, refactor/*, test/*"
    exit 1
fi

echo "Branch: $BRANCH"
echo "Type:   $BRANCH_TYPE"
echo ""

# Validate commit messages
BAD_COMMITS=""
if git rev-parse --verify origin/main >/devdev/null 2>&1; then
    BAD_COMMITS="$(git log origin/main..HEAD --pretty=format:"%s" | grep -vE '^(feat|fix|docs|style|refactor|test|chore|ci|build|perf)(\(.+\))?!?: .+' | grep -v '^Merge' | grep -v '^v[0-9]+\.' | head -20 || true)"
else
    echo "WARNING: origin/main not found. Skipping commit message validation."
fi

if [ -n "$BAD_COMMITS" ]; then
    echo "ERROR: Non-conventional commits found:"
    echo "$BAD_COMMITS"
    exit 1
fi
echo "Commits follow conventional format."
echo ""

# Per-branch type gates
case "$BRANCH_TYPE" in
    feat)
        echo "Validating feat/* requirements..."
        if [ ! -f "SPEC.md" ] && [ ! -f "PROTOTYPE.md" ] && [ ! -d "docs/adr" ]; then
            echo "WARNING: feat/* branches should include a SPEC.md, PROTOTYPE.md, or docs/adr/ decision record."
        fi
        ;;
    fix)
        echo "Validating fix/* requirements..."
        if ! git diff origin/main..HEAD --name-only 2>/dev/null | grep -qE '(test|spec)'; then
            echo "WARNING: fix/* branches should include a regression test or updated test coverage."
        fi
        ;;
    docs)
        echo "Validating docs/* requirements..."
        DOC_FILES="$(git diff origin/main..HEAD --name-only 2>/dev/null | grep -cE '\.(md|rst|txt)$' || echo 0)"
        if [ "$DOC_FILES" -eq 0 ]; then
            echo "WARNING: docs/* branches should modify documentation files."
        fi
        ;;
    *)
        echo "No extra requirements for $BRANCH_TYPE/* branches."
        ;;
esac

echo ""
echo "Branch validation passed for $BRANCH_TYPE/$BRANCH."
