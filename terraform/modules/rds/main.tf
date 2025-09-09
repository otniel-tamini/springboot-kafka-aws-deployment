# =================================
# RDS MODULE
# =================================

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-db-subnet-group"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Security group for RDS databases"
  vpc_id      = var.vpc_id

  ingress {
    description = "MySQL/Aurora"
    from_port   = 3306
    to_port     = 3306
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
    Name = "${var.project_name}-${var.environment}-rds-sg"
  }
}

# Data source for VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# RDS Parameter Group
resource "aws_db_parameter_group" "mysql" {
  family = "mysql8.0"
  name   = "${var.project_name}-${var.environment}-mysql-params"

  parameter {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  }

  parameter {
    name  = "max_connections"
    value = "200"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-mysql-params"
  }
}

# RDS Instances
resource "aws_db_instance" "databases" {
  for_each = var.databases

  identifier = "${var.project_name}-${var.environment}-${replace(each.key, "_", "-")}"

  # Engine configuration
  engine         = each.value.engine
  engine_version = each.value.engine_version
  instance_class = each.value.instance_class

  # Storage configuration
  allocated_storage     = each.value.allocated_storage
  max_allocated_storage = each.value.allocated_storage * 2
  storage_type          = "gp2"
  storage_encrypted     = true

  # Database configuration
  db_name  = each.value.database_name
  username = each.value.username
  password = each.value.password
  port     = each.value.port

  # Network configuration
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  publicly_accessible    = false

  # Parameter group
  parameter_group_name = aws_db_parameter_group.mysql.name

  # Backup configuration
  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn

  # Performance Insights
  performance_insights_enabled = true

  # Other settings
  skip_final_snapshot        = true
  deletion_protection        = false
  auto_minor_version_upgrade = true

  tags = {
    Name = "${var.project_name}-${var.environment}-${each.key}"
    Type = "database"
  }
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
