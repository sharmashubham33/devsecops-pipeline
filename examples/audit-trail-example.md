# SOC2 Audit Trail — Deployment Record

## Deployment Event

| Field | Value |
|---|---|
| **Timestamp** | 2024-01-15T14:23:47Z |
| **Environment** | production |
| **Image** | ghcr.io/org/devsecops-demo:sha-a1b2c3d |
| **Actor** | john.doe (via GitHub Actions) |
| **Commit** | a1b2c3d4e5f6789 |
| **PR** | #42 — "Add order validation" |
| **Workflow Run** | #1847 |
| **Approval** | Auto-approved (all gates passed) |

## Security Checks Passed

| Check | Status | Tool | Evidence |
|---|---|---|---|
| Unit Tests | PASSED | go test | 85.7% coverage, 7/7 tests passed |
| SAST Scan | PASSED | SonarQube | 0 bugs, 0 vulnerabilities, Quality Gate OK |
| Go Security | PASSED | gosec | No issues found |
| Container Scan | PASSED | Trivy | 0 CRITICAL, 0 HIGH CVEs |
| Image Signed | PASSED | Cosign | Keyless signature via Sigstore |
| Signature Verified | PASSED | Cosign | Certificate chain validated |
| Policy Check | PASSED | Conftest/OPA | 5/5 policies satisfied |
| SBOM Generated | PASSED | Syft | SPDX 2.3 format, 2 packages |
| Secrets from Vault | PASSED | Vault | 4 secrets injected via JWT auth |

## SOC2 Control Mapping

| Control | Requirement | How This Deployment Satisfies It |
|---|---|---|
| CC6.1 | Logical access controls | Image signed with verifiable identity; Vault secrets use least-privilege policies |
| CC6.2 | Credentials management | No hardcoded secrets; all injected from Vault at deploy time with 1h TTL |
| CC7.1 | System monitoring | Container labeled with OCI metadata; SBOM tracks all dependencies |
| CC7.2 | Vulnerability management | Trivy scanned for CVEs; SonarQube scanned for code vulnerabilities |
| CC8.1 | Change management | PR-based workflow; all changes reviewed; automated tests gate deployment |
| A1.1 | Availability planning | Resource limits enforced by OPA policy; non-root user prevents privilege escalation |

## Evidence Artifacts

All artifacts are stored as GitHub Actions artifacts with 90-day retention:
- `trivy-scan-results.json` — Full vulnerability scan output
- `sbom-spdx.json` — Software Bill of Materials
- `coverage.out` — Test coverage report
- `audit-entry.json` — Machine-readable audit record

## Rollback Plan

If issues are detected post-deployment:
1. `kubectl rollout undo deployment/app -n production`
2. Previous image is signed and verified — safe to roll back to
3. Vault secrets are version-controlled — previous version available via `vault kv rollback`
