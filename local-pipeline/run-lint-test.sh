#!/bin/bash
# Stage 1 (local): Run linter and unit tests.
set -euo pipefail

cd "$(dirname "$0")/../app"

echo "Running Go vet..."
go vet ./...

echo ""
echo "Running unit tests with coverage..."
go test -v -race -coverprofile=coverage.out ./...

echo ""
echo "Coverage summary:"
go tool cover -func=coverage.out

echo ""
COVERAGE=$(go tool cover -func=coverage.out | grep total | awk '{print $3}' | sed 's/%//')
echo "Total coverage: ${COVERAGE}%"

# Check threshold
if (( $(echo "$COVERAGE < 80" | bc -l 2>/dev/null || echo 0) )); then
    echo "WARNING: Coverage below 80% threshold"
fi

echo ""
echo "Lint & Test: PASSED"
