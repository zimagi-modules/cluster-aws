
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

resource "aws_elasticache_replication_group" "main" {
  replication_group_id          = local.identifier
  replication_group_description = local.identifier
  subnet_group_name             = aws_elasticache_subnet_group.main.name
  security_group_ids            = var.security_groups

  engine                        = "redis"
  engine_version                = var.engine_version
  port                          = var.port

  parameter_group_name          = var.parameter_group_name

  snapshot_retention_limit      = var.retention_period
  snapshot_window               = var.backup_window
  maintenance_window            = var.maintenance_window

  automatic_failover_enabled    = true
  auto_minor_version_upgrade    = false

  node_type                     = var.instance_type

  cluster_mode {
    replicas_per_node_group     = var.instances_per_group
    num_node_groups             = var.instance_groups
  }
}

output "host" {
  value = aws_elasticache_replication_group.main.configuration_endpoint_address
}
