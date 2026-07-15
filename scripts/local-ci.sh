#!/bin/bash
# Local CI gate for devcontainer-templates — run before pushing.
#
# Prerequisites:
#   - bash >= 4
#   - python3, jq, shellcheck
#   - node >= 20 (for sync check)
#   - Docker + devcontainer CLI (optional, for smoke tests)
#
# This script runs the same static checks as the CI lint job. Smoke tests are
# run only when Docker is available.

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
    echo -e "${GREEN}[PASS]${NC}: $1"
    ((PASS+=1))
}

fail() {
    echo -e "${RED}[FAIL]${NC}: $1"
    ((FAIL+=1))
}

warn() {
    echo -e "${YELLOW}[WARN]${NC}: $1"
}

echo "========================================"
echo "  Local CI Gate"
echo "  Repo: $(basename "$REPO_ROOT")"
echo "========================================"
echo ""

# --- Check required prerequisites ---
required_missing=0
require_cmd() {
    if ! command -v "$1" > /dev/null 2>&1; then
        fail "$1 is not installed"
        required_missing=1
    fi
}

require_cmd python3
require_cmd jq
require_cmd shellcheck
require_cmd node

if [ "$required_missing" -ne 0 ]; then
    echo ""
    echo "Install the missing tools and rerun."
    exit 1
fi

pass "prerequisites (python3, jq, shellcheck, node)"

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
    options_valid=1
    while IFS= read -r -d '' file; do
        while IFS= read -r option; do
            if ! jq -e ".options | has(\"$option\")" "$json_file" > /dev/null 2>&1; then
                fail "templateOption '$option' in $file has no matching option in $template_id"
                options_valid=0
            fi
        done < <(grep -oP '\$\{templateOption:\K[^}]+' "$file" 2>/dev/null || true)
    done < <(find "$template_dir" -type f -print0)

    if [ "$options_valid" -eq 1 ]; then
        pass "templateOption placeholders: $template_id"
    fi
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

# --- Python static check (ruff) ---
echo ""
echo "--- Running ruff on Python files ---"
if command -v ruff > /dev/null 2>&1; then
    if ruff check scripts/ test/; then
        pass "ruff check"
    else
        fail "ruff check"
    fi
else
    warn "ruff not installed; skipping Python lint"
fi

# --- README generation check ---
echo ""
echo "--- Checking generated template READMEs ---"
if python3 scripts/generate-template-readmes.py --check; then
    pass "template READMEs are up to date"
else
    fail "template READMEs are missing or would change. Run: python3 scripts/generate-template-readmes.py"
fi

# --- Registry sync check ---
echo ""
echo "--- Checking template registry sync ---"
if npx tsx scripts/sync-template-registry.ts; then
    pass "template registry is in sync"
else
    fail "template registry is out of sync. Run: npx tsx scripts/sync-template-registry.ts --write"
fi

# --- Markdown formatting check ---
echo ""
echo "--- Checking markdown formatting ---"
if command -v uv >/dev/null 2>&1; then
    if uvx --with mdformat-gfm mdformat --check docs/ packages/create-devcontainer/README.md .github/CONTRIBUTING.md .github/CODE_OF_CONDUCT.md .github/SECURITY.md; then
        pass "mdformat check"
    else
        fail "mdformat check"
    fi
elif command -v mdformat >/dev/null 2>&1; then
    if mdformat --check docs/ packages/create-devcontainer/README.md .github/CONTRIBUTING.md .github/CODE_OF_CONDUCT.md .github/SECURITY.md; then
        pass "mdformat check"
    else
        fail "mdformat check"
    fi
else
    warn "uv or mdformat not installed; skipping markdown format check"
fi

# --- Python unit tests ---
echo ""
echo "--- Running Python unit tests ---"
if command -v pytest > /dev/null 2>&1; then
    if pytest test/; then
        pass "pytest"
    else
        fail "pytest"
    fi
else
    warn "pytest not installed; run 'pip install pytest' or rely on CI for unit tests"
fi

# --- Optional smoke tests when Docker is available ---
echo ""
echo "--- Optional smoke tests ---"
if command -v docker > /dev/null 2>&1 && docker info > /dev/null 2>&1 && command -v devcontainer > /dev/null 2>&1; then
    for template_id in ollama-claude-cli ollama-claude-cli-studio; do
        if [ -d "src/$template_id" ]; then
            echo "Running smoke test for $template_id..."
            if ./.github/actions/smoke-test/build.sh "$template_id" && ./.github/actions/smoke-test/test.sh "$template_id"; then
                pass "smoke test: $template_id"
            else
                fail "smoke test: $template_id"
            fi
        fi
    done
else
    warn "Docker or devcontainer CLI not available; skipping smoke tests"
fi

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
