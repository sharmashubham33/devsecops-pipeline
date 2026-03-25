# Demo Walkthrough

## Prerequisites

- Docker and Docker Compose installed
- Go 1.22+ installed (for local tests)
- Ports 8080, 8200, 9000 available

## Step 1: Start Local Infrastructure

```bash
make up
```

Wait ~60 seconds for SonarQube to initialize (it's a heavy Java app).

```bash
make health
```

## Step 2: Run the Application

```bash
# Test the app directly
curl http://localhost:8080/health

# Create an order
curl -X POST http://localhost:8080/orders \
  -H "Content-Type: application/json" \
  -d '{"customer_id": "CUST-001", "items": [{"sku": "SKU-001", "name": "Widget", "quantity": 2, "price": 9.99}], "total": 19.98}'
```

## Step 3: Run Unit Tests

```bash
make test
```

You should see 7/7 tests passing with 85%+ coverage.

## Step 4: Run the Full Pipeline

```bash
make pipeline
```

This runs all stages in sequence:
1. Lint + Test
2. Docker Build
3. Trivy Scan
4. Policy Check
5. SBOM Generation
6. Cosign Demo

Watch each stage pass or fail with clear output.

## Step 5: Initialize Vault

```bash
make vault-init
```

This seeds Vault with demo secrets and creates the access policies. Then read a secret:

```bash
make vault-read
```

## Step 6: Explore the Pipeline Artifacts

Look at the example outputs in `examples/`:
- `trivy-scan-output.json` — What a clean Trivy scan looks like
- `sonarqube-report.json` — SonarQube analysis results
- `sbom-example.spdx.json` — Software Bill of Materials
- `audit-trail-example.md` — SOC2-compliant deployment record
- `policy-violation-output.txt` — What happens when policies are violated

## Step 7: Show Policy Enforcement

The most impressive demo: show what happens when policies fail vs pass.

Point to `examples/policy-violation-output.txt` and explain: "When a developer submits a Dockerfile with `:latest` tag or no USER instruction, this is what they see. The pipeline blocks the deploy and tells them exactly what to fix."

Then show our Dockerfile passes: "Our Dockerfile uses pinned versions, distroless base, non-root user, and all required labels."

## Step 8: Walk Through GitHub Actions

Open `.github/workflows/` and walk through each file. Explain that these are real, runnable workflows — someone can fork this repo and they'll work.

## Step 9: Clean Up

```bash
make clean
```
