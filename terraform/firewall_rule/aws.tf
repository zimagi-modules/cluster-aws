
provider "aws" {
    access_key = var.access_key
    secret_key = var.secret_key
    region = var.firewall.network.region
}

resource "aws_security_group_rule" "firewall_link" {
    count = var.rule_type == "link" ? 1 : 0
    security_group_id = var.firewall.security_group_id
    type = var.mode
    from_port = var.from_port
    to_port = var.to_port
    protocol = var.protocol == "all" ? "-1" : var.protocol
    self = var.self_only ? var.self_only : null
    source_security_group_id = var.self_only ? null : var.source_firewall_id
    description = join(":", ["zimagi", var.firewall.network.name, var.firewall.name, var.name])
}
resource "aws_security_group_rule" "firewall_cidr" {
    count = var.rule_type == "link" ? 0 : 1
    security_group_id = var.firewall.security_group_id
    type = var.mode
    from_port = var.from_port
    to_port = var.to_port
    protocol = var.protocol == "all" ? "-1" : var.protocol
    cidr_blocks = var.cidrs
    description = join(":", ["zimagi", var.firewall.network.name, var.firewall.name, var.name])
}

output "rule_id" {
  value = var.rule_type == "link" ? join(",",aws_security_group_rule.firewall_link.*.id) : join(",",aws_security_group_rule.firewall_cidr.*.id)
}