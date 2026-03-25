variable "vault_version" {
  description = "HashiCorp Vault Docker image version"
  type        = string
  default     = "1.17.6"
}

variable "vault_port" {
  description = "Port to expose Vault on"
  type        = number
  default     = 8200
}

variable "registry_version" {
  description = "Docker Registry image version"
  type        = string
  default     = "2"
}

variable "registry_port" {
  description = "Port to expose the container registry on"
  type        = number
  default     = 5000
}
