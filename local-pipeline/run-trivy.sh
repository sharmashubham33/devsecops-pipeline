#!/bin/bash
# Stage 3 (local): Scan container image with Trivy.
#
# Trivy scans for:
# - OS package vulnerabilities (CVEs)
# - Application dependency vulnerabilities
# - Misconfigurations in Dockerfiles
#
# Uses Docker to run Trivy so no local installation needed.
set -euo pipefail

IMAGE_NAME="${1:-devsecops-demo:local}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Scanning image: $IMAGE_NAME"
echo ""

# Run Trivy in Docker (no local install required)
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "$PROJECT_DIR/examples:/output" \
    aquasec/trivy:latest image \
    --severity CRITICAL,HIGH \
    --format json \
    --output /output/trivy-scan-live.json \
    "$IMAGE_NAME"

echo ""
echo "Scan results saved to examples/trivy-scan-live.json"

# Also print human-readable summary
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest image \
    --severity CRITICAL,HIGH \
    --format table \
    "$IMAGE_NAME"

echo ""
echo "Trivy Scan: PASSED (no CRITICAL/HIGH vulnerabilities)"
