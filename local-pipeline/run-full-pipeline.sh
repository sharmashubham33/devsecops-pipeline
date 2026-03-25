#!/bin/bash
# Run the full DevSecOps pipeline locally.
# Replicates every GitHub Actions stage without needing a remote runner.
#
# Usage: ./local-pipeline/run-full-pipeline.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="devsecops-demo:local"
PASS=0
FAIL=0

green() { echo -e "\033[32m$1\033[0m"; }
red() { echo -e "\033[31m$1\033[0m"; }
header() { echo -e "\n\033[1;36m==== $1 ====\033[0m\n"; }

record_result() {
    if [ $1 -eq 0 ]; then
        green "  PASSED: $2"
        PASS=$((PASS + 1))
    else
        red "  FAILED: $2"
        FAIL=$((FAIL + 1))
    fi
}

cd "$PROJECT_DIR"

header "Stage 1: Lint & Test"
bash "$SCRIPT_DIR/run-lint-test.sh"
record_result $? "Lint & Tests"

header "Stage 2: Build Container"
docker build -t "$IMAGE_NAME" ./app
record_result $? "Docker Build"

header "Stage 3: Trivy Container Scan"
bash "$SCRIPT_DIR/run-trivy.sh"
record_result $? "Trivy Scan"

header "Stage 4: OPA Policy Check"
bash "$SCRIPT_DIR/run-policy-check.sh"
record_result $? "Policy Check"

header "Stage 5: SBOM Generation"
bash "$SCRIPT_DIR/run-sbom.sh"
record_result $? "SBOM Generation"

header "Stage 6: Image Signing (Cosign)"
bash "$SCRIPT_DIR/run-cosign.sh"
record_result $? "Cosign Sign"

# --- Summary ---
echo ""
header "Pipeline Summary"
green "  Passed: $PASS"
if [ $FAIL -gt 0 ]; then
    red "  Failed: $FAIL"
    echo ""
    red "Pipeline FAILED — deploy blocked."
    exit 1
else
    echo ""
    green "All stages passed. Image is ready for deployment."
fi
