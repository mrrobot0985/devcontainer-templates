#!/bin/bash
# Render a devcontainer template by substituting templateOption placeholders.
#
# Usage:
#   render-template.sh <template-id> <destination-dir>
#
# Steps:
#   1. Copy src/<template-id> to <destination-dir>
#   2. Replace ${templateOption:<key>} placeholders with defaults from devcontainer-template.json
#   3. Copy test/<template-id>/* and test/test-utils/* into <destination-dir>/test-project

set -euo pipefail

TEMPLATE_ID="${1:-}"
DEST_DIR="${2:-}"

if [ -z "$TEMPLATE_ID" ] || [ -z "$DEST_DIR" ]; then
    echo "Usage: $(basename "$0") <template-id> <destination-dir>"
    exit 1
fi

SRC_DIR="src/${TEMPLATE_ID}"

if [ ! -d "$SRC_DIR" ]; then
    echo "ERROR: Template source directory '$SRC_DIR' not found"
    exit 1
fi

# Ensure dotglob is on so hidden files are copied consistently
shopt -s dotglob

# Clean up any previous run
rm -rf "$DEST_DIR"

# Copy template
cp -R "$SRC_DIR" "$DEST_DIR"

# Substitute template options with their defaults
pushd "$DEST_DIR" > /dev/null

OPTIONS=$(jq -r '.options | keys[]' devcontainer-template.json 2>/dev/null || true)

if [ -n "$OPTIONS" ]; then
    echo "(!) Configuring template options for '${TEMPLATE_ID}'"
    for OPTION in $OPTIONS; do
        # shellcheck disable=SC2016
        OPTION_KEY='\${templateOption:'"$OPTION"'}'
        OPTION_VALUE=$(jq -r ".options | .${OPTION} | .default" devcontainer-template.json)

        if [ "$OPTION_VALUE" = "" ] || [ "$OPTION_VALUE" = "null" ]; then
            echo "Template '${TEMPLATE_ID}' is missing a default value for option '${OPTION}'"
            popd > /dev/null
            exit 1
        fi

        echo "(!) Replacing '${OPTION_KEY}' with '${OPTION_VALUE}'"
        OPTION_VALUE_ESCAPED=$(sed -e 's/[]\/\/$*.^[]/\\&/g' <<<"${OPTION_VALUE}")
        find ./ -type f -print0 | xargs -0 sed -i "s/${OPTION_KEY}/${OPTION_VALUE_ESCAPED}/g"
    done
fi

popd > /dev/null

# Copy test files if they exist
TEST_DIR="test/${TEMPLATE_ID}"
if [ -d "${TEST_DIR}" ]; then
    echo "(*) Copying test folder"
    DEST_TEST_DIR="${DEST_DIR}/test-project"
    mkdir -p "${DEST_TEST_DIR}"
    cp -Rp "${TEST_DIR}"/* "${DEST_TEST_DIR}"
    if [ -d "test/test-utils" ]; then
        cp -Rp test/test-utils/* "${DEST_TEST_DIR}"
    fi
fi

echo "(*) Template rendered to '${DEST_DIR}'"
