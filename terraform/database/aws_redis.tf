
locals {
  identifier = "redis-${var.name}-${var.network.name}"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "aws_elasticache_subnet_group" "main" {
  name       = local.identifier
  subnet_ids = var.subnet_ids
}

resource "aws_elasticache_parameter_group" "main" {
  name   = local.identifier
  family = var.family

  dynamic "parameter" {
    for_each = var.parameters == null ? [] : var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }
}

resource "aws_kms_key" "cluster" {
  count = var.encrypted ? 1 : 0
  deletion_window_in_days = 30
}

resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = local.identifier
  replication_group_description = local.identifier
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = var.security_groups

  engine                        = "redis"
  engine_version                = var.engine_version
  port                          = var.port
  auth_token                    = var.encrypted ? var.user_password : null

  parameter_group_name          = aws_elasticache_parameter_group.main.name

  snapshot_retention_limit      = var.retention_period
  snapshot_window               = var.backup_window
  maintenance_window            = var.maintenance_window

  automatic_failover_enabled    = true
  auto_minor_version_upgrade    = true

  node_type                     = var.instance_type

  at_rest_encryption_enabled    = var.encrypted
  transit_encryption_enabled    = var.encrypted
  kms_key_id                    = var.encrypted ? aws_kms_key.cluster.0.arn : null

  cluster_mode {
    replicas_per_node_group     = var.instances_per_group
    num_node_groups             = var.instance_groups
  }
}

output "host" {
  value = aws_elasticache_replication_group.main.configuration_endpoint_address
}
