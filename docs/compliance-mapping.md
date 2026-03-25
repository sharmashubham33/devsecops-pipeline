# SOC2 Compliance Mapping

This document maps each pipeline stage to the SOC2 Trust Services Criteria it satisfies. During an audit, this is the document you hand the auditor to show how your engineering controls meet compliance requirements.

## Control Mapping Matrix

| SOC2 Control | Description | Pipeline Stage | Implementation |
|---|---|---|---|
| **CC6.1** | Logical access controls | Policy Check, Deploy | OPA policies enforce least privilege (no root, no privileged). Vault policies restrict secret access by role. |
| **CC6.2** | Credentials management | Deploy (Vault) | No hardcoded secrets. All credentials stored in Vault with 1h TTL tokens. Audit log tracks every access. |
| **CC6.6** | System boundaries | Policy Check | OPA policies enforce resource limits and network policies. Container images use minimal base (distroless). |
| **CC7.1** | Monitoring and detection | CI (SAST), Container Scan | SonarQube detects code vulnerabilities. Trivy detects CVEs. gosec detects Go-specific security issues. |
| **CC7.2** | Vulnerability management | Container Scan, SBOM | Trivy blocks deployment on CRITICAL/HIGH CVEs. SBOM enables rapid vulnerability triage when new CVEs are announced. |
| **CC8.1** | Change management | All stages | Every change goes through PR review + automated pipeline. Audit trail records who deployed what, when, and what checks passed. |
| **CC3.1** | Risk assessment | SBOM, Container Scan | SBOM provides complete dependency inventory. Trivy scan results quantify vulnerability risk per deployment. |
| **A1.1** | Availability | Policy Check | Resource limits prevent noisy neighbor problems. Non-root prevents privilege escalation that could take down the node. |
| **A1.2** | Recovery procedures | Deploy (audit trail) | Audit trail records previous image SHA for rollback. Vault secret versioning enables credential rollback. |

## Evidence Collection

For each audit cycle, the following artifacts are automatically generated:

| Artifact | Location | Retention | Purpose |
|---|---|---|---|
| Test coverage report | GitHub Actions artifacts | 90 days | Proves code is tested before deployment |
| SonarQube scan report | SonarQube server | Indefinite | Proves SAST scanning is active |
| Trivy scan results | GitHub Actions artifacts | 90 days | Proves container vulnerability scanning |
| SBOM (SPDX) | GitHub Actions artifacts | 90 days | Proves dependency inventory exists |
| Cosign signature | Rekor transparency log | Indefinite | Proves image integrity |
| Vault audit log | Vault server | Configurable | Proves secret access is logged |
| Deploy audit trail | GitHub Actions artifacts | 90 days | Proves deployment was authorized |

## Auditor FAQ

**Q: How do you prevent unauthorized code from reaching production?**

A: Every deployment requires passing through 5 automated gates (tests, SAST, CVE scan, policy check, signature verification). The deploy workflow runs in a protected GitHub environment that requires all previous checks to pass. The Cosign signature verification at deploy time independently confirms the image was built by our pipeline.

**Q: How do you manage secrets?**

A: All secrets are stored in HashiCorp Vault. The CI pipeline authenticates via JWT (GitHub OIDC) and receives a token scoped to read-only access on application secrets. Tokens have a 1-hour TTL. Every secret access is recorded in Vault's audit log with the accessor identity and timestamp.

**Q: How quickly can you determine if you're affected by a new CVE?**

A: We generate SBOMs for every deployed image. When a new CVE is announced, we search the SBOM artifacts for the affected package. This typically takes minutes, not days.

**Q: How do you prevent image tampering between build and deploy?**

A: Images are signed with Cosign immediately after building. At deploy time, the signature is verified against the Sigstore transparency log. If the image was modified after signing, verification fails and deployment is blocked.
