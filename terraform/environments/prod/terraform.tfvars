# =================================
# PRODUCTION ENVIRONMENT CONFIGURATION
# =================================

# Environment-specific variables
aws_region   = "us-west-2"
project_name = "springboot-kafka-microservices"
environment  = "prod"

# VPC Configuration
vpc_cidr             = "10.1.0.0/16"
private_subnet_cidrs = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnet_cidrs  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

# EKS Configuration (larger instances for production)
cluster_version = "1.28"
node_groups = {
  main = {
    instance_types = ["t3.large"]
    min_size       = 3
    max_size       = 10
    desired_size   = 5
    capacity_type  = "ON_DEMAND"
    disk_size      = 50
  }
  spot = {
    instance_types = ["t3.medium", "t3.large"]
    min_size       = 2
    max_size       = 8
    desired_size   = 3
    capacity_type  = "SPOT"
    disk_size      = 30
  }
}

# Database Configuration (production-grade instances)
databases = {
  order_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.small"
    allocated_storage = 100
    database_name     = "order_db"
    username          = "root"
    password          = "CHANGE_IN_PRODUCTION"
    port              = 3306
  }
  identity_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.small"
    allocated_storage = 100
    database_name     = "user_db"
    username          = "root"
    password          = "CHANGE_IN_PRODUCTION"
    port              = 3306
  }
  payment_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.small"
    allocated_storage = 100
    database_name     = "payment_db"
    username          = "root"
    password          = "CHANGE_IN_PRODUCTION"
    port              = 3306
  }
  product_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.small"
    allocated_storage = 100
    database_name     = "product_db"
    username          = "root"
    password          = "CHANGE_IN_PRODUCTION"
    port              = 3306
  }
}

# Redis Configuration (production-grade)
redis_config = {
  node_type       = "cache.t3.small"
  num_cache_nodes = 2
  parameter_group = "default.redis7"
  port            = 6379
  engine_version  = "7.0"
}

# Kafka Configuration (production-grade)
kafka_config = {
  kafka_version   = "3.5.1"
  number_of_nodes = 6
  instance_type   = "kafka.m5.large"
  ebs_volume_size = 500
}

# Monitoring
enable_monitoring = true
enable_logging    = true

# Microservices Configuration (production replicas)
microservices = {
  service_registry = {
    image_tag         = "latest"
    replicas          = 3
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 8761
    health_check_path = "/actuator/health"
  }
  api_gateway = {
    image_tag         = "latest"
    replicas          = 3
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 9191
    health_check_path = "/actuator/health"
  }
  order_service = {
    image_tag         = "latest"
    replicas          = 5
    cpu_request       = "500m"
    memory_request    = "1Gi"
    cpu_limit         = "2000m"
    memory_limit      = "2Gi"
    port              = 8080
    health_check_path = "/actuator/health"
  }
  payment_service = {
    image_tag         = "latest"
    replicas          = 3
    cpu_request       = "500m"
    memory_request    = "1Gi"
    cpu_limit         = "2000m"
    memory_limit      = "2Gi"
    port              = 8085
    health_check_path = "/actuator/health"
  }
  product_service = {
    image_tag         = "latest"
    replicas          = 5
    cpu_request       = "500m"
    memory_request    = "1Gi"
    cpu_limit         = "2000m"
    memory_limit      = "2Gi"
    port              = 8084
    health_check_path = "/actuator/health"
  }
  email_service = {
    image_tag         = "latest"
    replicas          = 3
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 8086
    health_check_path = "/actuator/health"
  }
  identity_service = {
    image_tag         = "latest"
    replicas          = 3
    cpu_request       = "500m"
    memory_request    = "1Gi"
    cpu_limit         = "2000m"
    memory_limit      = "2Gi"
    port              = 9898
    health_check_path = "/actuator/health"
  }
}
