
locals {
  identifier = "${var.name}-${var.network.name}"
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

resource "aws_elasticache_cluster" "main" {
  cluster_id               = local.identifier
  subnet_group_name        = aws_elasticache_subnet_group.main.name
  az_mode                  = var.instance_count > 1 ? "cross-az" : "single-az"
  security_group_ids       = var.security_groups

  engine                   = "memcached"
  engine_version           = var.engine_version
  port                     = var.port

  parameter_group_name     = aws_elasticache_parameter_group.main.name

  snapshot_retention_limit = var.retention_period
  snapshot_window          = var.backup_window
  maintenance_window       = var.maintenance_window
  snapshot_name            = local.identifier

  num_cache_nodes          = var.instance_count
  node_type                = var.instance_type
}

output "host" {
  value = aws_elasticache_cluster.main.cluster_address
}
