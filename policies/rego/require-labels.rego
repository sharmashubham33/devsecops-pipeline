# Policy: Container images must have required OCI labels.
#
# Why: Labels provide metadata for scanning tools, registries, and auditors.
#
# SOC2: CC7.1 — Monitoring and detection require identifiable artifacts.

package dockerfile

import rego.v1

required_labels := {
    "org.opencontainers.image.title",
    "org.opencontainers.image.description",
    "org.opencontainers.image.source",
}

deny contains msg if {
    some label in required_labels
    not label_exists(label)
    msg := sprintf("Missing required label: %s", [label])
}

label_exists(label) if {
    some i
    input[i].Cmd == "label"
    val := concat(" ", input[i].Value)
    contains(val, label)
}
