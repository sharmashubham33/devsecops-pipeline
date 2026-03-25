# Policy: CI/CD pipeline secrets access.
#
# The CI pipeline needs to read secrets during the deploy stage
# but should never be able to write, update, or delete them.
# This limits the blast radius if CI credentials are compromised.
#
# Also grants metadata access for health checking and listing
# available secret paths (but not reading their values).

# Read application secrets for deployment injection
path "secret/data/app/*" {
  capabilities = ["read"]
}

# List available secret paths (shows keys, not values)
path "secret/metadata/app/*" {
  capabilities = ["list"]
}

# Read PKI certificates for TLS
path "pki/issue/app" {
  capabilities = ["read", "create"]
}

# Deny write access to everything
path "secret/data/*" {
  capabilities = ["deny"]
  # Override: only deny create/update/delete, allow read
  # (Vault evaluates most specific path first)
}

# Deny access to Vault system configuration
path "sys/*" {
  capabilities = ["deny"]
}

# Allow token self-lookup (required for health checks)
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
