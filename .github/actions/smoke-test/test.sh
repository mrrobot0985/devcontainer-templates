#!/bin/bash
# Run the smoke test for a built dev container template.
#
# Usage:
#   test.sh <template-id>
#
# Expectations:
#   - The template must have already been built by build.sh, which leaves the
#     rendered source in /tmp/<template-id> and labels the running container
#     with "test-container=<template-id>".
#   - If test/<template-id>/test.sh exists inside the container, it is executed.
#     Otherwise the script lists the container contents so the failure is visible.
#   - On exit, the running test container and the rendered source directory are
#     removed to prevent orphaned resources.

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
