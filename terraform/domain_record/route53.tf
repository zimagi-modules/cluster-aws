
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.domain.region
}

resource "aws_route53_record" "main" {
  zone_id = var.domain.zone_id
  name    = var.target
  type    = var.type
  ttl     = var.ttl
  records = var.values

  set_identifier = join("-", var.values)

  weighted_routing_policy {
    weight = 1
  }
}