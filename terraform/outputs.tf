output "vault_url" {
  value       = "http://localhost:${var.vault_port}"
  description = "URL to access Vault UI"
}

output "registry_url" {
  value       = "localhost:${var.registry_port}"
  description = "URL to push/pull container images"
}

output "pipeline_config" {
  value = {
    vault_address    = "http://localhost:${var.vault_port}"
    registry_address = "localhost:${var.registry_port}"
    cosign_enabled   = true
    trivy_severity   = "CRITICAL,HIGH"
    sbom_format      = "spdx-json"
  }
  description = "Configuration values for the CI/CD pipeline"
}
