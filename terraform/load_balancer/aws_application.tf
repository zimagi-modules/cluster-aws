
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.network.region
}

data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket" "main" {
  bucket = format("alb-%s-%s", var.name, var.network.name)
  force_destroy = true
  acl = "private"
  policy = <<POLICY
{
  "Id": "Policy",
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${format("alb-%s-%s", var.name, var.network.name)}/lb/*",
      "Principal": {
        "AWS": [
          "${data.aws_elb_service_account.main.arn}"
        ]
      }
    }
  ]
}
POLICY

  tags = {
    Name = join(":", ["zimagi", var.network.name, var.name])
  }
}

resource "aws_lb" "main" {
  load_balancer_type = "application"
  name = var.name
  internal = var.internal
  idle_timeout = var.idle_timeout

  subnets = var.subnet_ids
  security_groups = var.security_groups

  enable_http2 = true
  enable_cross_zone_load_balancing = true

  access_logs {
    bucket  = aws_s3_bucket.main.bucket
    prefix = "lb"
    enabled = true
  }

  tags = {
    Name = join(":", ["zimagi", var.network.name, var.name])
  }
}
output "lb_id" {
  value = aws_lb.main.id
}
output "lb_arn" {
  value = aws_lb.main.arn
}
output "lb_dns_name" {
  value = aws_lb.main.dns_name
}