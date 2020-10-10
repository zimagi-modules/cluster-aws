
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.network.region
}

resource "aws_s3_bucket" "main" {
  bucket = format("nlb-%s-%s", var.name, var.network.name)
  force_destroy = true
  acl = "private"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSLogDeliveryWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${format("nlb-%s-%s", var.name, var.network.name)}/lb/AWSLogs/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${format("nlb-%s-%s", var.name, var.network.name)}"
    }
  ]
}
POLICY

  tags = {
    Name = join(":", ["zimagi", var.network.name, var.name])
  }
}

resource "aws_lb" "main" {
  load_balancer_type = "network"
  name = var.name
  internal = var.internal

  subnets = var.subnet_ids
  security_groups = var.security_groups

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
