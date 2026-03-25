# HashiCorp Vault server configuration for local demo.
#
# This runs Vault in dev mode with file storage.
# In production, you'd use:
# - Integrated storage (Raft) or Consul for HA
# - Auto-unseal with AWS KMS / Azure Key Vault / GCP Cloud KMS
# - TLS certificates from a trusted CA
# - Audit logging enabled

storage "file" {
  path = "/vault/data"
}

listener "tcp" {
  address     = "0.0.0.0:8200"
  tls_disable = true  # Demo only — production requires TLS
}

# Enable audit logging to file
# In production, also send to a SIEM (Splunk, ELK, etc.)
audit {
  type = "file"
  options {
    file_path = "/vault/logs/audit.log"
  }
}

api_addr     = "http://0.0.0.0:8200"
cluster_addr = "https://0.0.0.0:8201"

ui = true

# Max lease TTL - secrets expire after this duration
max_lease_ttl     = "768h"  # 32 days
default_lease_ttl = "24h"
