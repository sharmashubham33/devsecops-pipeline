# Failure Scenarios

What happens when each pipeline gate fails? Understanding failures is as important as understanding the happy path.

## Scenario 1: Trivy Finds a Critical CVE

**What happens:**
```
CRITICAL: CVE-2024-XXXX in libssl 3.0.2 (fixed in 3.0.15)
Pipeline: FAILED at Stage 2 (Container Security)
Deploy: BLOCKED
```

**Developer action:**
1. Update the base image to a patched version
2. If no patch exists, evaluate the CVE: Is the vulnerable component actually used?
3. If the CVE is a false positive or not exploitable in our context, file an exception with justification

**Exception process:**
- Developer adds `--ignore-unfixed` for CVEs with no available fix
- Exception is documented in `.trivyignore` with the CVE ID and expiry date
- Security team reviews exceptions monthly

## Scenario 2: OPA Policy Rejects the Dockerfile

**What happens:**
```
FAIL - Dockerfile must include a USER instruction to run as non-root
Pipeline: FAILED at Stage 3 (Policy Check)
Deploy: BLOCKED
```

**Developer action:**
1. Read the error message — it tells you exactly what's wrong
2. Fix the Dockerfile (add `USER nonroot:nonroot`)
3. Push the fix

**No exception process:** These policies are non-negotiable. Running as root is never acceptable.

## Scenario 3: SonarQube Quality Gate Fails

**What happens:**
```
Quality Gate: FAILED
- Code coverage on new code: 45% (threshold: 80%)
- New security hotspots: 3 (threshold: 0)
Pipeline: FAILED at Stage 1 (CI)
```

**Developer action:**
1. Write tests for the uncovered code
2. Review and resolve security hotspots (mark as Safe, Not Applicable, or fix)
3. Push the fixes

## Scenario 4: Cosign Signature Verification Fails at Deploy

**What happens:**
```
Error: no matching signatures found
Pipeline: FAILED at Stage 6 (Deploy)
Deploy: BLOCKED
```

**This is serious.** Signature verification failure means either:
1. The image was modified after signing (possible supply chain attack)
2. The signing step was skipped or failed silently
3. The registry returned a different image than what was signed

**Response:**
1. Do NOT deploy the image
2. Check the container-security workflow — did signing succeed?
3. Pull the image by digest and compare checksums
4. If tampering is suspected, escalate to security team

## Scenario 5: Vault is Unreachable During Deploy

**What happens:**
```
Error: connection refused to vault:8200
Pipeline: FAILED at Stage 6 (Deploy)
Deploy: BLOCKED
```

**Developer action:**
1. This is an infrastructure issue, not a code issue
2. Check Vault server health: `vault status`
3. If Vault is sealed, unseal it (requires unseal keys)
4. If Vault is down, the deployment cannot proceed — secrets cannot be retrieved

**Design rationale:** We intentionally fail closed. If we can't retrieve secrets securely, we don't deploy. The alternative (caching secrets or having fallback credentials) creates security risks that are worse than a delayed deployment.

## Scenario 6: Emergency Deploy (All Gates Must Be Bypassed)

**This should almost never happen.** But when it does (active security incident, data loss):

1. Use `workflow_dispatch` with manual approval from security lead
2. Document the justification in the PR description
3. Run the full pipeline against the emergency fix within 24 hours
4. File a postmortem explaining why the bypass was necessary
5. Review and update the pipeline to prevent the root cause
