# Policy: Containers must not run as root.
#
# Why: Root in container + container escape = root on host.
# Running as non-root limits blast radius.
#
# SOC2: CC6.1 — Principle of least privilege.

package dockerfile

import rego.v1

deny contains msg if {
    not has_non_root_user
    msg := "Dockerfile must include a USER instruction to run as non-root"
}

has_non_root_user if {
    some i
    input[i].Cmd == "user"
    val := input[i].Value[0]
    val != "root"
    val != "0"
}
