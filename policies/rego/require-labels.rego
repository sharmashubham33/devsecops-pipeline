# Policy: Container images must have required OCI labels.
#
# Why: Labels provide metadata for container scanning tools, registries,
# and compliance auditors. Without them, you can't answer "what is
# this image, who owns it, and where's the source code?" when
# investigating an incident at 3 AM.
#
# SOC2: CC7.1 — Monitoring and detection require identifiable artifacts.

package dockerfile

required_labels := {
    "org.opencontainers.image.title",
    "org.opencontainers.image.description",
    "org.opencontainers.image.source",
}

get_labels[label] {
    input[i].Cmd == "label"
    label := input[i].Value[0]
}

deny[msg] {
    label := required_labels[_]
    not label_exists(label)
    msg := sprintf("Missing required label: %s", [label])
}

label_exists(label) {
    input[i].Cmd == "label"
    some j
    input[i].Value[j] == label
}

# Check LABEL instruction exists with key=value format
label_exists(label) {
    input[i].Cmd == "label"
    val := concat(" ", input[i].Value)
    contains(val, label)
}
