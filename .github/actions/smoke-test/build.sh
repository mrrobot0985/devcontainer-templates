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
#   4. Strip postCreateCommand / onCreateCommand to avoid heavy bootstrap in CI.
#   5. Build the container with the test ID label so the test.sh step can find it.
#
# Note: Templates referencing unpublished mrrobot0985 features are skipped
#       until those features are published to GHCR.

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

# CI runners lack GPUs; strip --gpus=all from runArgs so the container can start.
# Only strip heavy lifecycle bootstraps for domain stacks (k3d / Spark downloads).
# Keep postCreate for agent templates so agent install bootstraps can run when needed.
HEAVY_LIFECYCLE_TEMPLATES="cloud-native-k8s data-engineering-spark"
if [ "${CI:-}" = "true" ]; then
    echo "(*) CI detected — stripping --gpus=all for smoke test"
    STRIP_HEAVY=0
    for heavy in ${HEAVY_LIFECYCLE_TEMPLATES}; do
        if [ "${TEMPLATE_ID}" = "${heavy}" ]; then
            STRIP_HEAVY=1
            break
        fi
    done
    python3 -c "
import json
with open('${SRC_DIR}/.devcontainer/devcontainer.json') as f:
    data = json.load(f)

run_args = data.get('runArgs', [])
data['runArgs'] = [a for a in run_args if a != '--gpus=all']

if ${STRIP_HEAVY}:
    for key in ('postCreateCommand', 'onCreateCommand', 'postStartCommand'):
        if key in data:
            print(f'(*) Stripping {key} for heavy domain template ${TEMPLATE_ID}')
            del data[key]

with open('${SRC_DIR}/.devcontainer/devcontainer.json', 'w') as f:
    json.dump(data, f, indent='\t')
"
fi

DEVCONTAINER_JSON="${SRC_DIR}/.devcontainer/devcontainer.json"

echo "Building Dev Container"
ID_LABEL="test-container=${TEMPLATE_ID}"
set +e
devcontainer up --id-label "${ID_LABEL}" --workspace-folder "${SRC_DIR}"
UP_RC=$?
set -e
if [ "${UP_RC}" -ne 0 ]; then
    echo "ERROR: devcontainer up failed for ${TEMPLATE_ID} (exit ${UP_RC})"
    echo "This is a real failure — owned GHCR features must resolve and build."
    exit "${UP_RC}"
fi

# Smoke matrix trigger note: owned GHCR features must build (no false SKIP).

# fail-fast=false: one template failure must not cancel Layer B/D proof matrix.
