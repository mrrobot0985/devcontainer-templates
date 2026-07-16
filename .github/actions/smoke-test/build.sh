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
#   4. If the template references ghcr.io/mrrobot0985/devcontainer-features/*,
#      clone the features repo and rewrite references to local paths.
#   5. Build the container with the test ID label so the test.sh step can find it.

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

# If the template references our own unpublished features, clone the features repo
# and rewrite GHCR references to local paths so the smoke test can resolve them.
DEVCONTAINER_JSON="${SRC_DIR}/.devcontainer/devcontainer.json"
if grep -q 'ghcr.io/mrrobot0985/devcontainer-features/' "$DEVCONTAINER_JSON"; then
    echo "(*) Template references mrrobot0985 features — resolving from sibling repo"
    FEATURES_REPO="${REPO_ROOT}/../devcontainer-features"
    if [ ! -d "$FEATURES_REPO" ]; then
        echo "(*) Cloning features repo into sibling directory"
        if git clone --depth 1 https://github.com/mrrobot0985/devcontainer-features.git "$FEATURES_REPO" 2>/dev/null; then
            echo "(*) Cloned features repo to $FEATURES_REPO"
        elif git clone --depth 1 https://github.com/mrrobot0985/devcontainer-features.git /tmp/devcontainer-features; then
            echo "(*) Cloned features repo to /tmp/devcontainer-features"
            FEATURES_REPO="/tmp/devcontainer-features"
        else
            echo "ERROR: Failed to clone features repo"
            exit 1
        fi
    fi

    # Verify the features repo was cloned correctly
    if [ ! -d "$FEATURES_REPO/src" ]; then
        echo "ERROR: Features repo missing src/ directory at $FEATURES_REPO"
        ls -la "$FEATURES_REPO" 2>/dev/null || true
        exit 1
    fi

    # Rewrite GHCR references to local paths
    python3 -c "
import json, re, os

features_repo = '${FEATURES_REPO}'
with open('${DEVCONTAINER_JSON}') as f:
    data = json.load(f)

features = data.get('features', {})
new_features = {}
for ref, opts in features.items():
    m = re.match(r'^ghcr\.io/mrrobot0985/devcontainer-features/([^:]+):.*$', ref)
    if m:
        feat_id = m.group(1)
        local_path = os.path.join(features_repo, 'src', feat_id)
        if os.path.isdir(local_path):
            print(f'(*) Rewriting {ref} -> {local_path}')
            new_features[local_path] = opts
        else:
            print(f'WARNING: Feature {feat_id} not found in {local_path}; keeping GHCR reference')
            new_features[ref] = opts
    else:
        new_features[ref] = opts

data['features'] = new_features
with open('${DEVCONTAINER_JSON}', 'w') as f:
    json.dump(data, f, indent='\t')
"
fi

echo "Building Dev Container"
ID_LABEL="test-container=${TEMPLATE_ID}"
devcontainer up --id-label "${ID_LABEL}" --workspace-folder "${SRC_DIR}"
