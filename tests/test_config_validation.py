"""Validate all configuration files in the DevSecOps pipeline."""

import json
import os
import pytest
import yaml

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_yaml(path):
    with open(os.path.join(PROJECT_ROOT, path), "r") as f:
        return yaml.safe_load(f)


def load_json(path):
    with open(os.path.join(PROJECT_ROOT, path), "r") as f:
        return json.load(f)


def read_file(path):
    with open(os.path.join(PROJECT_ROOT, path), "r") as f:
        return f.read()


class TestGitHubActionsWorkflows:
    """Validate all GitHub Actions workflow files parse correctly."""

    @pytest.mark.parametrize("workflow", [
        "ci.yml",
        "container-security.yml",
        "policy-check.yml",
        "sbom-generate.yml",
        "deploy.yml",
    ])
    def test_workflow_parses(self, workflow):
        config = load_yaml(f".github/workflows/{workflow}")
        assert "name" in config
        # PyYAML parses YAML key `on` as boolean True
        assert True in config or "on" in config
        assert "jobs" in config

    def test_ci_workflow_has_test_job(self):
        config = load_yaml(".github/workflows/ci.yml")
        assert "test" in config["jobs"]
        assert "lint" in config["jobs"]

    def test_deploy_workflow_has_vault_step(self):
        config = load_yaml(".github/workflows/deploy.yml")
        deploy_steps = config["jobs"]["deploy"]["steps"]
        step_names = [s.get("name", "") for s in deploy_steps]
        assert any("vault" in name.lower() or "Vault" in name for name in step_names)

    def test_all_workflows_have_permissions(self):
        """Workflows should declare minimum required permissions."""
        for workflow in os.listdir(os.path.join(PROJECT_ROOT, ".github/workflows")):
            config = load_yaml(f".github/workflows/{workflow}")
            assert "permissions" in config or any(
                "permissions" in job for job in config.get("jobs", {}).values()
            ), f"{workflow} missing permissions declaration"


class TestDockerCompose:
    def test_docker_compose_parses(self):
        config = load_yaml("docker-compose.yml")
        assert "services" in config

    def test_required_services_defined(self):
        config = load_yaml("docker-compose.yml")
        for svc in ["app", "sonarqube", "vault"]:
            assert svc in config["services"], f"Missing service: {svc}"


class TestOPAPolicies:
    """Verify all Rego policy files exist and are non-empty."""

    @pytest.mark.parametrize("policy", [
        "no-latest-tag.rego",
        "require-labels.rego",
        "no-privileged.rego",
        "resource-limits.rego",
        "no-root-user.rego",
    ])
    def test_policy_exists_and_nonempty(self, policy):
        path = os.path.join(PROJECT_ROOT, "policies/rego", policy)
        assert os.path.exists(path), f"Policy file missing: {policy}"
        content = open(path).read()
        assert len(content) > 50, f"Policy file too small: {policy}"
        assert "deny" in content or "violation" in content, f"Policy has no deny/violation rules: {policy}"

    def test_conftest_config_exists(self):
        config = load_yaml("policies/conftest.yml")
        assert "policy" in config


class TestVaultConfig:
    def test_vault_config_exists(self):
        content = read_file("vault/vault-config.hcl")
        assert "storage" in content
        assert "listener" in content

    def test_vault_policies_exist(self):
        for policy in ["app-secrets.hcl", "ci-read-only.hcl"]:
            path = os.path.join(PROJECT_ROOT, "vault/policies", policy)
            assert os.path.exists(path)
            content = open(path).read()
            assert "path" in content
            assert "capabilities" in content

    def test_vault_init_script_exists(self):
        content = read_file("vault/init-vault.sh")
        assert "vault" in content
        assert "kv put" in content


class TestTerraform:
    def test_main_tf_parses(self):
        content = read_file("terraform/main.tf")
        assert "terraform" in content
        assert "module" in content

    def test_variables_defined(self):
        content = read_file("terraform/variables.tf")
        assert "variable" in content
        assert "vault_version" in content

    def test_modules_exist(self):
        for module in ["vault", "registry"]:
            path = os.path.join(PROJECT_ROOT, "terraform/modules", module, "main.tf")
            assert os.path.exists(path), f"Terraform module missing: {module}"


class TestExampleOutputs:
    def test_trivy_output_valid_json(self):
        data = load_json("examples/trivy-scan-output.json")
        assert "Results" in data

    def test_sonarqube_report_valid_json(self):
        data = load_json("examples/sonarqube-report.json")
        assert "qualityGate" in data
        assert data["qualityGate"]["status"] == "OK"

    def test_sbom_valid_spdx(self):
        data = load_json("examples/sbom-example.spdx.json")
        assert data["spdxVersion"] == "SPDX-2.3"
        assert "packages" in data


class TestDockerfile:
    def test_dockerfile_uses_pinned_versions(self):
        content = read_file("app/Dockerfile")
        # Check FROM lines only, not comments
        from_lines = [l for l in content.splitlines() if l.strip().startswith("FROM")]
        for line in from_lines:
            assert ":latest" not in line, f"FROM uses :latest tag: {line}"

    def test_dockerfile_has_user_instruction(self):
        content = read_file("app/Dockerfile")
        assert "USER" in content
        assert "nonroot" in content

    def test_dockerfile_has_labels(self):
        content = read_file("app/Dockerfile")
        assert "org.opencontainers.image.title" in content

    def test_dockerfile_uses_multistage(self):
        content = read_file("app/Dockerfile")
        assert content.count("FROM") >= 2, "Should use multi-stage build"


class TestNoHardcodedSecrets:
    def test_no_secrets_in_source(self):
        """Scan all non-example source files for potential secrets."""
        secret_patterns = ["sk_live_", "pk_live_", "AKIA", "-----BEGIN RSA"]
        for root, dirs, files in os.walk(PROJECT_ROOT):
            # Skip examples, tests, and git directories
            if "examples" in root or ".git" in root or "tests" in root:
                continue
            for f in files:
                if f.endswith((".go", ".py", ".yml", ".yaml", ".tf", ".hcl")):
                    path = os.path.join(root, f)
                    content = open(path).read()
                    for pattern in secret_patterns:
                        assert pattern not in content, f"Possible secret in {path}: {pattern}"

    def test_no_real_vault_tokens(self):
        """Ensure only 'root' dev token is used."""
        for root, dirs, files in os.walk(PROJECT_ROOT):
            if ".git" in root:
                continue
            for f in files:
                if f.endswith((".sh", ".yml", ".yaml", ".hcl")):
                    path = os.path.join(root, f)
                    content = open(path).read()
                    assert "hvs." not in content, f"Real Vault token found in {path}"


class TestLocalPipelineScripts:
    @pytest.mark.parametrize("script", [
        "run-full-pipeline.sh",
        "run-lint-test.sh",
        "run-trivy.sh",
        "run-policy-check.sh",
        "run-sbom.sh",
        "run-cosign.sh",
    ])
    def test_script_exists_and_has_shebang(self, script):
        path = os.path.join(PROJECT_ROOT, "local-pipeline", script)
        assert os.path.exists(path), f"Script missing: {script}"
        content = open(path).read()
        assert content.startswith("#!/bin/bash"), f"Missing shebang in {script}"
        assert "set -" in content, f"Missing strict mode in {script}"
