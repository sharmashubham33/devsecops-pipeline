#!/bin/bash
# Stage 5 (local): Generate SBOM with Syft.
#
# Creates a Software Bill of Materials listing every package
# in the container image. Output in both SPDX and CycloneDX formats.
set -euo pipefail

IMAGE_NAME="${1:-devsecops-demo:local}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Generating SBOM for: $IMAGE_NAME"
echo ""

if ! command -v syft &>/dev/null; then
    echo "syft not found. Running via Docker..."
    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v "$PROJECT_DIR/examples:/output" \
        anchore/syft:latest \
        "$IMAGE_NAME" \
        -o spdx-json=/output/sbom-live.spdx.json

    docker run --rm \
        -v /var/run/docker.sock:/var/run/docker.sock \
        anchore/syft:latest \
        "$IMAGE_NAME" \
        -o table
else
    cd "$PROJECT_DIR"
    syft "$IMAGE_NAME" -o spdx-json=examples/sbom-live.spdx.json
    syft "$IMAGE_NAME" -o table
fi

echo ""
echo "SBOM saved to examples/sbom-live.spdx.json"
echo "SBOM Generation: PASSED"
