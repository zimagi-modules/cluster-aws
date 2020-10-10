
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.network.region
}

resource "aws_security_group" "firewall" {
  name = var.name
  vpc_id = var.network.vpc_id

  tags = {
    Name = join(":", ["zimagi", var.network.name, var.name])
  }
}
output "security_group_id" {
  value = aws_security_group.firewall.id
}