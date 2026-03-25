# Policy: All containers must specify CPU and memory limits.
#
# Why: Without resource limits, a single container can consume all
# available resources on a node (noisy neighbor problem).
#
# SOC2: A1.1 — System availability and capacity management.

package kubernetes

import rego.v1

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.limits.memory
    msg := sprintf("Container '%s' has no memory limit", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' has no CPU limit", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.requests.memory
    msg := sprintf("Container '%s' has no memory request", [container.name])
}

deny contains msg if {
    input.kind == "Deployment"
    some container in input.spec.template.spec.containers
    not container.resources.requests.cpu
    msg := sprintf("Container '%s' has no CPU request", [container.name])
}
