# Policy: Containers must not run as root.
#
# Why: If a container runs as root and an attacker exploits a vulnerability,
# they have root privileges inside the container. Combined with a
# container escape vulnerability, this gives them root on the host.
# Running as non-root limits the blast radius of container compromises.
#
# SOC2: CC6.1 — Principle of least privilege.

package dockerfile

# Check that a USER instruction exists and is not root
deny[msg] {
    not has_non_root_user
    msg := "Dockerfile must include a USER instruction to run as non-root"
}

has_non_root_user {
    input[i].Cmd == "user"
    val := input[i].Value[0]
    val != "root"
    val != "0"
}

# Kubernetes: check runAsNonRoot
package kubernetes

deny[msg] {
    input.kind == "Deployment"
    not input.spec.template.spec.securityContext.runAsNonRoot == true
    container := input.spec.template.spec.containers[_]
    not container.securityContext.runAsNonRoot == true
    msg := sprintf("Container '%s' does not set runAsNonRoot: true", [container.name])
}
