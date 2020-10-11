
locals {
  identifier = "${var.name}-${var.network.name}"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

resource "aws_kms_key" "cluster" {
  count = var.encrypted ? 1 : 0
  description             = "database ${local.identifier}"
  deletion_window_in_days = 30
}

resource "aws_rds_cluster_parameter_group" "main" {
  name   = local.identifier
  family = var.family

  dynamic "parameter" {
    for_each = var.cluster_parameters == null ? [] : var.cluster_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
}

resource "aws_rds_cluster" "default" {
  cluster_identifier      = local.identifier
  availability_zones      = var.subnet_ids
  vpc_security_group_ids  = var.security_groups
  port                    = var.port

  engine                  = var.engine
  engine_version          = var.engine_version
  engine_mode             = "serverless"
  storage_encrypted       = var.encrypted
  kms_key_id              = var.encrypted ? aws_kms_key.cluster.0.arn : null

  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name

  database_name           = var.database_name
  master_username         = var.user_name
  master_password         = var.user_password

  backup_retention_period = var.retention_period
  preferred_backup_window = var.backup_window
  preferred_maintenance_window = var.maintenance_window
  final_snapshot_identifier = local.identifier

  enabled_cloudwatch_logs_exports = var.log_level == null ? "error" : var.log_level

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }

  scaling_configuration {
    auto_pause               = var.auto_pause # true
    seconds_until_auto_pause = var.auto_pause_period # 300
    max_capacity             = var.max_capacity # 8
    min_capacity             = var.min_capacity # 1
    timeout_action           = var.timeout_action # RollbackCapacityChange
  }
}

output "host" {
  value = aws_rds_cluster.main.endpoint
}
