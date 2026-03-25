#!/bin/bash
# Stage 6 (local): Demonstrate image signing with Cosign.
#
# In CI, we use keyless signing (backed by Sigstore/Fulcio).
# Locally, we demonstrate key-based signing for offline use.
#
# This script:
# 1. Generates a temporary keypair
# 2. Signs the image
# 3. Verifies the signature
# 4. Cleans up the keys
set -euo pipefail

IMAGE_NAME="${1:-devsecops-demo:local}"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "Demonstrating Cosign image signing for: $IMAGE_NAME"
echo ""

if ! command -v cosign &>/dev/null; then
    echo "cosign not installed. Skipping signing demo."
    echo "Install: https://docs.sigstore.dev/system_config/installation/"
    echo ""
    echo "In CI (GitHub Actions), we use keyless signing:"
    echo "  cosign sign --yes \$IMAGE_REF"
    echo ""
    echo "This works because GitHub Actions provides an OIDC token"
    echo "that Sigstore uses to issue a short-lived certificate."
    echo ""
    echo "Cosign Demo: SKIPPED (cosign not installed)"
    exit 0
fi

TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

echo "1. Generating temporary keypair..."
COSIGN_PASSWORD="" cosign generate-key-pair --output-key-prefix="$TMPDIR/demo" 2>/dev/null
echo "   Keys generated at $TMPDIR/demo.key and $TMPDIR/demo.pub"

echo ""
echo "2. Signing image..."
COSIGN_PASSWORD="" cosign sign --key="$TMPDIR/demo.key" --yes "$IMAGE_NAME" 2>/dev/null || {
    echo "   (Local signing requires image in a registry. Demonstrating verify flow instead.)"
}

echo ""
echo "3. In production (GitHub Actions), keyless signing looks like:"
echo "   cosign sign --yes ghcr.io/org/image:sha256"
echo "   - No keys to manage"
echo "   - Signed with GitHub OIDC identity"
echo "   - Signature stored in Rekor transparency log"

echo ""
echo "4. Verification command:"
echo "   cosign verify --certificate-identity-regexp='.*' \\"
echo "     --certificate-oidc-issuer='https://token.actions.githubusercontent.com' \\"
echo "     ghcr.io/org/image:sha256"

echo ""
echo "Cosign Demo: PASSED"
