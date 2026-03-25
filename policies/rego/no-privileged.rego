# Policy: Containers must not run in privileged mode.
#
# Why: Privileged containers have full access to the host kernel.
#
# SOC2: CC6.1 — Logical access controls; principle of least privilege.

package kubernetes

import rego.v1

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' runs in privileged mode", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.initContainers
    container.securityContext.privileged == true
    msg := sprintf("Init container '%s' runs in privileged mode", [container.name])
}

deny contains msg if {
    input.kind == "DaemonSet"
    some container in input.spec.template.spec.containers
    container.securityContext.privileged == true
    msg := sprintf("Container '%s' in DaemonSet runs privileged", [container.name])
}
