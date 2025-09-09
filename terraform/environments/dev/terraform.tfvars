# =================================
# DEVELOPMENT ENVIRONMENT CONFIGURATION
# =================================

# Environment-specific variables
aws_region   = "us-west-2"
project_name = "springboot-kafka-microservices"
environment  = "dev"

# VPC Configuration
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

# EKS Configuration
cluster_version = "1.28"
node_groups = {
  main = {
    instance_types = ["t3.medium"]
    min_size       = 1
    max_size       = 3
    desired_size   = 2
    capacity_type  = "ON_DEMAND"
    disk_size      = 20
  }
}

# Database Configuration (smaller instances for dev)
databases = {
  order_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    database_name     = "order_db"
    username          = "root"
    password          = "dev_password_123"
    port              = 3306
  }
  identity_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    database_name     = "user_db"
    username          = "root"
    password          = "dev_password_123"
    port              = 3306
  }
  payment_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    database_name     = "payment_db"
    username          = "root"
    password          = "dev_password_123"
    port              = 3306
  }
  product_db = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"
    allocated_storage = 20
    database_name     = "product_db"
    username          = "root"
    password          = "dev_password_123"
    port              = 3306
  }
}

# Redis Configuration
redis_config = {
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  parameter_group = "default.redis7"
  port            = 6379
  engine_version  = "7.0"
}

# Kafka Configuration
kafka_config = {
  kafka_version   = "3.5.1"
  number_of_nodes = 3
  instance_type   = "kafka.t3.small"
  ebs_volume_size = 100
}

# Monitoring
enable_monitoring = true
enable_logging    = true

# Microservices Configuration
microservices = {
  service_registry = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 8761
    health_check_path = "/actuator/health"
  }
  api_gateway = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 9191
    health_check_path = "/actuator/health"
  }
  order_service = {
    image_tag         = "latest"
    replicas          = 2
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 8080
    health_check_path = "/actuator/health"
  }
  payment_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 8085
    health_check_path = "/actuator/health"
  }
  product_service = {
    image_tag         = "latest"
    replicas          = 2
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 8084
    health_check_path = "/actuator/health"
  }
  email_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 8086
    health_check_path = "/actuator/health"
  }
  identity_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "200m"
    memory_request    = "512Mi"
    cpu_limit         = "1000m"
    memory_limit      = "1Gi"
    port              = 9898
    health_check_path = "/actuator/health"
  }
}
