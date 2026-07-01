#!/bin/bash
# Local CI gate for devcontainer-templates — run before pushing.
#
# Prerequisites:
#   - Docker running
#   - act installed (https://github.com/nektos/act#installation)
#   - jq installed
#
# Limitations:
#   - test-pr.yaml uses dorny/paths-filter which needs real PR context;
#     use manual smoke tests (build.sh/test.sh) instead.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS=0
FAIL=0

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASS+=1))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAIL+=1))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
}

echo "========================================"
echo "  Local CI Gate"
echo "  Repo: $(basename "$REPO_ROOT")"
echo "========================================"
echo ""

# --- Check prerequisites ---
if ! command -v act > /dev/null 2>&1; then
    fail "act is not installed. Install from https://github.com/nektos/act"
    exit 1
fi

if ! command -v docker > /dev/null 2>&1; then
    fail "docker is not installed"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    fail "docker daemon is not running"
    exit 1
fi

if ! command -v jq > /dev/null 2>&1; then
    fail "jq is not installed"
    exit 1
fi

pass "prerequisites (act, docker, jq)"

# --- Validate devcontainer-template.json files ---
echo ""
echo "--- Validating devcontainer-template.json files ---"
for json_file in src/*/devcontainer-template.json; do
    template_id=$(jq -r '.id' "$json_file")
    if jq empty "$json_file" > /dev/null 2>&1; then
        pass "json valid: $template_id"
    else
        fail "json invalid: $template_id"
        continue
    fi

    # Check that all templateOption placeholders have matching options
    template_dir="$(dirname "$json_file")"
    # shellcheck disable=SC2044
    for file in $(find "$template_dir" -type f); do
        if grep -oP '\$\{templateOption:\K[^}]+' "$file" 2>/dev/null | while read -r option; do
            if ! jq -e ".options | has(\"$option\")" "$json_file" > /dev/null 2>&1; then
                fail "templateOption '$option' in $file has no matching option in $template_id"
                return 1
            fi
        done; then
            : # all options matched
        fi
    done
done

# --- Shellcheck on bootstrap.sh files ---
echo ""
echo "--- Running shellcheck on bootstrap.sh files ---"
for script in src/*/.devcontainer/bootstrap.sh; do
    if [ -f "$script" ]; then
        if shellcheck "$script"; then
            pass "shellcheck $(basename "$(dirname "$(dirname "$script")")")"
        else
            fail "shellcheck $(basename "$(dirname "$(dirname "$script")")")"
        fi
    fi
done

# --- Summary ---
echo ""
echo "========================================"
echo "  Results: $PASS passed, $FAIL failed"
echo "========================================"

if [ "$FAIL" -gt 0 ]; then
    echo -e "${RED}Gate FAILED.${NC} Fix issues before pushing."
    exit 1
else
    echo -e "${GREEN}Gate PASSED.${NC} Safe to push."
    exit 0
fi
