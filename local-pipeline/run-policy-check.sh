#!/bin/bash
# Stage 4 (local): Run OPA/Conftest policy checks against Dockerfile.
#
# Validates that the Dockerfile follows security policies:
# - No :latest tag
# - Non-root user
# - Required labels present
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Checking if conftest is installed..."
if ! command -v conftest &>/dev/null; then
    echo "conftest not found. Running via Docker..."
    docker run --rm \
        -v "$PROJECT_DIR:/project" \
        -w /project \
        openpolicyagent/conftest:latest test \
        app/Dockerfile \
        --policy policies/rego \
        --namespace dockerfile \
        --output table
else
    cd "$PROJECT_DIR"
    conftest test app/Dockerfile \
        --policy policies/rego \
        --namespace dockerfile \
        --output table
fi

echo ""
echo "Policy Check: PASSED"
