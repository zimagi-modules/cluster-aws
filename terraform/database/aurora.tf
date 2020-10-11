
locals {
  identifier = "${var.name}-${var.network.name}"
}

provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = var.region
}

data "aws_iam_policy_document" "monitoring_rds_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "rds_enhanced_monitoring" {
  count              = var.enhanced_monitoring ? 1 : 0
  name               = "rds-enhanced-monitoring-${var.name}"
  assume_role_policy = data.aws_iam_policy_document.monitoring_rds_assume_role.json
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  count      = var.enhanced_monitoring ? 1 : 0
  role       = aws_iam_role.rds_enhanced_monitoring.0.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

resource "aws_kms_key" "cluster" {
  count = var.encrypted ? 1 : 0
  description             = "aurora ${local.identifier}"
  deletion_window_in_days = 30
}

resource "aws_db_subnet_group" "main" {
  name       = local.identifier
  subnet_ids = var.subnet_ids
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

resource "aws_rds_cluster" "main" {
  cluster_identifier      = local.identifier
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = var.security_groups
  port                    = var.port

  engine                  = var.engine
  engine_version          = var.engine_version
  engine_mode             = var.engine_mode
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

  enabled_cloudwatch_logs_exports = var.log_level == null ? ["error"] : [var.log_level]

  timeouts {
    create = var.create_timeout
    update = var.update_timeout
    delete = var.delete_timeout
  }
}

resource "aws_db_parameter_group" "main" {
  name   = local.identifier
  family = var.family

  dynamic "parameter" {
    for_each = var.instance_parameters == null ? [] : var.instance_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", null)
    }
  }
}

resource "aws_rds_cluster_instance" "cluster_instances" {
  count                   = var.instance_count
  identifier              = "${local.identifier}-${count.index}"
  cluster_identifier      = aws_rds_cluster.main.id
  engine                  = aws_rds_cluster.main.engine
  engine_version          = aws_rds_cluster.main.engine_version

  instance_class          = var.instance_type
  publicly_accessible     = false

  db_subnet_group_name    = aws_db_subnet_group.main.name
  db_parameter_group_name = aws_db_parameter_group.main.name

  monitoring_role_arn     = var.enhanced_monitoring ? aws_iam_role.rds_enhanced_monitoring.0.arn : null
  monitoring_interval     = var.monitoring_interval
}

output "host" {
  value = aws_rds_cluster.main.endpoint
}
