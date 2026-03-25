# Policy: Container images must use specific version tags, not :latest.
#
# Why: The :latest tag is mutable. If you deploy :latest today, the image
# content can change tomorrow without any code change.
#
# SOC2: CC8.1 — Change management requires trackable, versioned artifacts.

package dockerfile

import rego.v1

deny contains msg if {
    some i
    input[i].Cmd == "from"
    val := input[i].Value[0]
    contains(val, ":latest")
    msg := sprintf("FROM uses :latest tag at line %d. Use a specific version tag (e.g., golang:1.22-alpine)", [i + 1])
}

deny contains msg if {
    some i
    input[i].Cmd == "from"
    val := input[i].Value[0]
    not contains(val, ":")
    not contains(val, "@sha256")
    val != "scratch"
    msg := sprintf("FROM has no version tag at line %d. Pin to a specific version", [i + 1])
}
