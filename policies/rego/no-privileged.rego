# Policy: Containers must not run in privileged mode.
#
# Why: Privileged containers have full access to the host kernel.
# A container escape from a privileged container gives the attacker
# root access to the host machine and every other container on it.
# This is the #1 container security misconfiguration.
#
# SOC2: CC6.1 — Logical access controls; principle of least privilege.

package kubernetes

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' runs in privileged mode. Remove securityContext.privileged or set to false", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.initContainers[_]
    container.securityContext.privileged == true
    msg := sprintf("Init container '%s' runs in privileged mode", [container.name])
}

# Also catch DaemonSets and StatefulSets
deny[msg] {
    input.kind == "DaemonSet"
    container := input.spec.template.spec.containers[_]
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' in DaemonSet runs privileged", [container.name])
}
