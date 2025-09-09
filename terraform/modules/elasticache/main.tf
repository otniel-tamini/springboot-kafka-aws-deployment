# =================================
# ELASTICACHE MODULE
# =================================

# ElastiCache Subnet Group
resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-${var.environment}-redis-subnet-group"
  }
}

# Security Group for ElastiCache
resource "aws_security_group" "redis" {
  name        = "${var.project_name}-${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = var.vpc_id

  ingress {
    description = "Redis"
    from_port   = var.redis_config.port
    to_port     = var.redis_config.port
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
    Name = "${var.project_name}-${var.environment}-redis-sg"
  }
}

# Data source for VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}

# ElastiCache Redis Cluster
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "${var.project_name}-${var.environment}-redis"
  engine               = "redis"
  node_type            = var.redis_config.node_type
  num_cache_nodes      = 1  # Redis ne supporte qu'un seul nœud
  parameter_group_name = var.redis_config.parameter_group
  port                 = var.redis_config.port
  engine_version       = var.redis_config.engine_version

  subnet_group_name = aws_elasticache_subnet_group.main.name

  tags = {
    Name = "${var.project_name}-${var.environment}-redis"
    Type = "cache"
  }
}
