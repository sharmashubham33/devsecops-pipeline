.PHONY: up down build test lint scan sign policy sbom pipeline vault-init health clean

# ============================================================
# Core commands
# ============================================================

up: ## Start local infrastructure (SonarQube, Vault, OPA)
	docker compose up -d
	@echo ""
	@echo "Infrastructure starting..."
	@echo "  App:        http://localhost:8080/health"
	@echo "  SonarQube:  http://localhost:9000  (admin/admin)"
	@echo "  Vault:      http://localhost:8200  (token: root)"
	@echo "  OPA:        http://localhost:8181"
	@echo ""
	@echo "Run 'make vault-init' to seed Vault with demo secrets"

down: ## Stop everything
	docker compose down

build: ## Build the application container
	docker build -t devsecops-demo:local ./app
	@echo "Image built: devsecops-demo:local"

# ============================================================
# Pipeline stages (run individually or all at once)
# ============================================================

test: ## Stage 1a: Run unit tests
	cd app && go test -v -race -coverprofile=coverage.out ./...
	cd app && go tool cover -func=coverage.out

lint: ## Stage 1b: Run linter
	cd app && go vet ./...
	@echo "Lint passed"

scan: build ## Stage 2: Trivy container vulnerability scan
	bash local-pipeline/run-trivy.sh

policy: ## Stage 3: OPA/Conftest policy check
	bash local-pipeline/run-policy-check.sh

sbom: build ## Stage 4: Generate SBOM
	bash local-pipeline/run-sbom.sh

sign: build ## Stage 5: Cosign image signing demo
	bash local-pipeline/run-cosign.sh

pipeline: ## Run full pipeline (all stages)
	bash local-pipeline/run-full-pipeline.sh

# ============================================================
# Vault
# ============================================================

vault-init: ## Initialize Vault with demo secrets and policies
	bash vault/init-vault.sh

vault-read: ## Read a secret from Vault (demo)
	VAULT_ADDR=http://localhost:8200 VAULT_TOKEN=root vault kv get secret/app/database

# ============================================================
# Terraform
# ============================================================

tf-init: ## Initialize Terraform
	cd terraform && terraform init

tf-plan: ## Plan infrastructure changes
	cd terraform && terraform plan

tf-apply: ## Apply infrastructure changes
	cd terraform && terraform apply -auto-approve

tf-destroy: ## Destroy infrastructure
	cd terraform && terraform destroy -auto-approve

# ============================================================
# Health & Cleanup
# ============================================================

health: ## Check health of all services
	@echo "App:"; curl -sf http://localhost:8080/health 2>/dev/null | python3 -m json.tool || echo "  DOWN"
	@echo "SonarQube:"; curl -sf http://localhost:9000/api/system/health 2>/dev/null | python3 -m json.tool || echo "  DOWN (takes ~60s to start)"
	@echo "Vault:"; curl -sf http://localhost:8200/v1/sys/health 2>/dev/null | python3 -m json.tool || echo "  DOWN"

clean: ## Stop everything, remove volumes and build artifacts
	docker compose down -v
	rm -f app/coverage.out
	@echo "Cleaned"

# ============================================================
# Validation
# ============================================================

validate: ## Validate all configs and policies
	python3 -m pytest tests/ -v

# ============================================================
# Help
# ============================================================

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help
