# Design Document: End-to-End DevSecOps Pipeline

## Problem Statement

Security scanning happens too late in most teams. Vulnerabilities are found in production, compliance audits are manual and reactive, and there's no chain of custody from commit to deployment. We need security gates that are automated, mandatory, and fast enough that developers don't bypass them.

## Goals

1. Every commit passes through SAST, container scanning, and policy enforcement before it can reach production
2. Container images are cryptographically signed and verifiable
3. Secrets are injected from Vault at deploy time, never stored in code or CI variables
4. Every deployment produces an audit trail that maps directly to SOC2 controls
5. The entire pipeline runs locally for developer testing without cloud credentials

## Non-Goals

- Runtime security (RASP, runtime container protection)
- Penetration testing automation
- Multi-cloud deployment orchestration

## Architecture Decisions

### Why OPA/Conftest over Hard-Coded CI Rules

Writing policy checks as if-statements in YAML is fragile and untestable. OPA policies are:
- **Declarative:** Define what's allowed, not how to check it
- **Testable:** Rego policies have unit tests
- **Portable:** Same policies work in CI, admission controllers, and API gateways
- **Auditable:** Policies are code, reviewed in PRs, versioned in git

The alternative was writing bash checks in the workflow YAML. That works for one or two checks but becomes unmaintainable at 10+ policies.

### Why Cosign Keyless over Traditional GPG Signing

Traditional image signing requires managing long-lived keys. If the key is compromised, every image ever signed with it is suspect. Cosign keyless signing:
- Uses short-lived certificates (10 minutes) from Sigstore's Fulcio CA
- Identity is tied to the CI system's OIDC token (GitHub Actions identity)
- All signatures are logged in Rekor, a public transparency log
- No key management, no key rotation, no key storage

### Why Vault over CI/CD Secret Variables

GitHub Actions secrets work for simple cases, but:
- No audit log of who accessed what secret when
- No secret rotation without CI config changes
- No fine-grained access control (all secrets visible to all workflows)
- No dynamic secrets (database credentials generated on demand)

Vault solves all of these. CI authenticates via JWT, gets a short-lived token scoped to exactly the secrets it needs, and every access is audit-logged.

### Why Trivy over Snyk/Anchore

Trivy is open-source, has the best detection rate in benchmarks, scans both OS packages and application dependencies, and runs as a single binary with no server. Snyk is SaaS-only. Anchore is powerful but complex to operate. For a pipeline gate, Trivy's simplicity and accuracy win.

## Trade-offs and Limitations

| Decision | Trade-off |
|---|---|
| Blocking on CRITICAL/HIGH CVEs | May block deploys for CVEs with no fix available — need exception process |
| Keyless Cosign | Requires internet access to Sigstore services — doesn't work air-gapped |
| SonarQube Community | No branch analysis, no PR decoration — upgrade to Developer Edition for those |
| Vault dev mode | Not HA, no auto-unseal — production needs Raft storage + KMS unseal |
