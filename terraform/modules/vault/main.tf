# Vault module — provisions a HashiCorp Vault server.
#
# In production on AWS, you'd use:
# - ECS/EKS for the Vault cluster
# - KMS for auto-unseal
# - DynamoDB for HA storage
# - ACM for TLS certificates
# - CloudWatch for audit log shipping

variable "vault_version" {
  type    = string
  default = "1.17.6"
}

variable "vault_port" {
  type    = number
  default = 8200
}

resource "docker_image" "vault" {
  name = "hashicorp/vault:${var.vault_version}"
}

resource "docker_container" "vault" {
  name  = "devsecops-vault"
  image = docker_image.vault.image_id

  ports {
    internal = 8200
    external = var.vault_port
  }

  env = [
    "VAULT_DEV_ROOT_TOKEN_ID=root",
    "VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200",
  ]

  capabilities {
    add = ["IPC_LOCK"]
  }

  # Health check
  healthcheck {
    test         = ["CMD", "vault", "status"]
    interval     = "10s"
    timeout      = "5s"
    retries      = 3
    start_period = "10s"
  }
}

output "vault_address" {
  value = "http://localhost:${var.vault_port}"
}

output "container_id" {
  value = docker_container.vault.id
}
