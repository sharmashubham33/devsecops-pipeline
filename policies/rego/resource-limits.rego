# Policy: All containers must specify CPU and memory limits.
#
# Why: Without resource limits, a single container can consume all
# available memory or CPU on a node, causing other containers to
# be OOM-killed or starved. This is called the "noisy neighbor" problem.
# Resource limits are also required for Kubernetes QoS class assignment.
#
# SOC2: A1.1 — System availability and capacity management.

package kubernetes

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.memory
    msg := sprintf("Container '%s' has no memory limit. Set resources.limits.memory", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.limits.cpu
    msg := sprintf("Container '%s' has no CPU limit. Set resources.limits.cpu", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.memory
    msg := sprintf("Container '%s' has no memory request. Set resources.requests.memory", [container.name])
}

deny[msg] {
    input.kind == "Deployment"
    container := input.spec.template.spec.containers[_]
    not container.resources.requests.cpu
    msg := sprintf("Container '%s' has no CPU request. Set resources.requests.cpu", [container.name])
}
