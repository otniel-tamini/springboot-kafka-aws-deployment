# =================================
# MSK (MANAGED STREAMING FOR KAFKA) MODULE
# =================================

# Security Group for MSK
resource "aws_security_group" "msk" {
  name        = "${var.project_name}-${var.environment}-msk-sg"
  description = "Security group for MSK Kafka cluster"
  vpc_id      = var.vpc_id

  ingress {
    description = "Kafka PLAINTEXT"
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Kafka TLS"
    from_port   = 9094
    to_port     = 9094
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  ingress {
    description = "Zookeeper"
    from_port   = 2181
    to_port     = 2181
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-msk-sg"
  }
}

# Data source for VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# CloudWatch Log Group for MSK
resource "aws_cloudwatch_log_group" "msk" {
  name              = "/aws/msk/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-msk-logs"
  }
}

# MSK Configuration
resource "aws_msk_configuration" "main" {
  kafka_versions = [var.kafka_config.kafka_version]
  name           = "${var.project_name}-${var.environment}-msk-config"

  server_properties = <<PROPERTIES
auto.create.topics.enable=true
default.replication.factor=2
min.insync.replicas=1
num.partitions=3
log.retention.hours=168
log.segment.bytes=1073741824
PROPERTIES
}

# MSK Cluster
resource "aws_msk_cluster" "main" {
  cluster_name           = "${var.project_name}-${var.environment}-kafka"
  kafka_version          = var.kafka_config.kafka_version
  number_of_broker_nodes = var.kafka_config.number_of_nodes

  broker_node_group_info {
    instance_type   = var.kafka_config.instance_type
    client_subnets  = var.private_subnet_ids
    security_groups = [aws_security_group.msk.id]
    
    storage_info {
      ebs_storage_info {
        volume_size = var.kafka_config.ebs_volume_size
      }
    }
  }

  configuration_info {
    arn      = aws_msk_configuration.main.arn
    revision = aws_msk_configuration.main.latest_revision
  }

  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
      in_cluster    = true
    }
  }

  logging_info {
    broker_logs {
      cloudwatch_logs {
        enabled   = true
        log_group = aws_cloudwatch_log_group.msk.name
      }
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-kafka"
    Type = "streaming"
  }
}

# KMS Key for MSK encryption
resource "aws_kms_key" "msk" {
  description             = "KMS key for MSK encryption"
  deletion_window_in_days = 7

  tags = {
    Name = "${var.project_name}-${var.environment}-msk-key"
  }
}

resource "aws_kms_alias" "msk" {
  name          = "alias/${var.project_name}-${var.environment}-msk"
  target_key_id = aws_kms_key.msk.key_id
}
