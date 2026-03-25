# Policy: Application secrets access.
#
# Grants the application read-only access to its own secrets.
# The app can read database credentials and API keys but cannot
# modify them, list other paths, or access other apps' secrets.
#
# Principle of least privilege: apps get exactly what they need.

# Read application database credentials
path "secret/data/app/database" {
  capabilities = ["read"]
}

# Read application API keys
path "secret/data/app/api" {
  capabilities = ["read"]
}

# Deny access to other applications' secrets
path "secret/data/other-app/*" {
  capabilities = ["deny"]
}

# Deny access to infrastructure secrets
path "secret/data/infra/*" {
  capabilities = ["deny"]
}
