# Terraform configuration for DevSecOps pipeline infrastructure.
#
# This provisions the supporting infrastructure needed to run
# the pipeline in a cloud environment:
# - HashiCorp Vault server for secrets management
# - Container registry for image storage
#
# In a real setup, this would be applied to AWS/GCP/Azure.
# For this demo, it targets local Docker resources.

terraform {
  required_version = ">= 1.5"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }

  # In production, use remote state:
  # backend "s3" {
  #   bucket = "terraform-state-devsecops"
  #   key    = "pipeline/terraform.tfstate"
  #   region = "us-east-1"
  #   encrypt = true
  #   dynamodb_table = "terraform-locks"
  # }
}

provider "docker" {}

module "vault" {
  source = "./modules/vault"

  vault_version = var.vault_version
  vault_port    = var.vault_port
}

module "registry" {
  source = "./modules/registry"

  registry_version = var.registry_version
  registry_port    = var.registry_port
}

output "vault_address" {
  value       = module.vault.vault_address
  description = "Vault server URL"
}

output "registry_address" {
  value       = module.registry.registry_address
  description = "Container registry URL"
}
