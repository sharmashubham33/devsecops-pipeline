#!/bin/bash
# Initialize Vault for local demo.
#
# This script:
# 1. Waits for Vault to be ready
# 2. Enables the KV secrets engine
# 3. Seeds demo secrets
# 4. Creates policies
# 5. Creates AppRole for CI pipeline
#
# Usage: ./vault/init-vault.sh

set -euo pipefail

VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-root}"
export VAULT_ADDR VAULT_TOKEN

echo "Waiting for Vault to be ready..."
for i in $(seq 1 30); do
    if vault status &>/dev/null; then
        echo "Vault is ready."
        break
    fi
    sleep 1
done

echo ""
echo "=== Enabling KV secrets engine ==="
vault secrets enable -path=secret -version=2 kv 2>/dev/null || echo "KV engine already enabled"

echo ""
echo "=== Seeding demo secrets ==="
# These are demo values — never commit real secrets
vault kv put secret/app/database \
    DB_HOST="db.internal.example.com" \
    DB_PORT="5432" \
    DB_NAME="orders_production" \
    DB_USER="app_service" \
    DB_PASSWORD="demo-password-rotate-in-production"

vault kv put secret/app/api \
    API_KEY="demo-api-key-not-real" \
    WEBHOOK_SECRET="demo-webhook-secret-not-real" \
    STRIPE_KEY="sk_test_demo_not_real"

echo "Secrets seeded successfully."

echo ""
echo "=== Creating policies ==="
vault policy write app-secrets vault/policies/app-secrets.hcl
vault policy write ci-read-only vault/policies/ci-read-only.hcl

echo ""
echo "=== Creating AppRole for CI ==="
vault auth enable approle 2>/dev/null || echo "AppRole already enabled"

vault write auth/approle/role/ci-deploy \
    policies="ci-read-only" \
    secret_id_ttl="720h" \
    token_ttl="1h" \
    token_max_ttl="4h"

echo ""
echo "=== Setup complete ==="
echo ""
echo "Vault UI: $VAULT_ADDR/ui"
echo "Token: $VAULT_TOKEN (dev mode only)"
echo ""
echo "Test reading a secret:"
echo "  vault kv get secret/app/database"
