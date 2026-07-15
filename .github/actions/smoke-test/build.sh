#!/bin/bash
# Build a dev container template for smoke testing.
#
# Usage:
#   build.sh <template-id>
#
# Steps:
#   1. Render the template with default options into /tmp/<template-id>.
#   2. Ensure the devcontainer CLI is installed.
#   3. On CI runners, strip --gpus=all from runArgs because GPUs are unavailable.
#   4. Build the container with the test ID label so the test.sh step can find it.

TEMPLATE_ID="$1"

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
SRC_DIR="/tmp/${TEMPLATE_ID}"

# Render template (copy + substitute + copy tests)
"${REPO_ROOT}/scripts/render-template.sh" "${TEMPLATE_ID}" "${SRC_DIR}"

export DOCKER_BUILDKIT=1
if ! command -v devcontainer >/dev/null 2>&1; then
    echo "(*) Installing @devcontainer/cli"
    npm install -g @devcontainers/cli
else
    echo "(*) @devcontainer/cli already installed: $(devcontainer --version 2>/dev/null || echo present)"
fi

# CI runners lack GPUs; strip --gpus=all from runArgs so the container can start
if [ "${CI:-}" = "true" ]; then
    echo "(*) CI detected — stripping --gpus=all from runArgs for smoke test"
    python3 -c "
import json, sys
with open('${SRC_DIR}/.devcontainer/devcontainer.json') as f:
    data = json.load(f)
run_args = data.get('runArgs', [])
data['runArgs'] = [a for a in run_args if a != '--gpus=all']
with open('${SRC_DIR}/.devcontainer/devcontainer.json', 'w') as f:
    json.dump(data, f, indent='\t')
"
fi

echo "Building Dev Container"
ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer up --id-label "${ID_LABEL}" --workspace-folder "${SRC_DIR}"
