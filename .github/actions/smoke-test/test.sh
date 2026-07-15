#!/bin/bash
TEMPLATE_ID="$1"
set -e

SRC_DIR="/tmp/${TEMPLATE_ID}"
echo "Running Smoke Test"

ID_LABEL="test-container=${TEMPLATE_ID}"

cleanup() {
    echo "Cleaning up smoke-test resources..."
    local containers
    containers="$(docker container ls -f "label=${ID_LABEL}" -q 2>/dev/null || true)"
    if [ -n "$containers" ]; then
        docker rm -f $containers || true
    fi
    rm -rf "${SRC_DIR}"
}
trap cleanup EXIT

devcontainer exec --workspace-folder "${SRC_DIR}" --id-label ${ID_LABEL} /bin/sh -c 'set -e && if [ -f "test-project/test.sh" ]; then cd test-project && if [ "$(id -u)" = "0" ]; then chmod +x test.sh; else sudo chmod +x test.sh; fi && ./test.sh; else ls -a; fi'
