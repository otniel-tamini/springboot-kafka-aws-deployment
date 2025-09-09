# =================================
# CONFIGURATION DEMO 3H - Variables optimisées
# =================================
aws_region = "us-west-2"

project_name = "springboot-kafka-demo"
environment  = "demo"

# =================================
# VPC CONFIGURATION - Minimale pour démo
# =================================
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]

# =================================
# EKS CONFIGURATION - Optimisée démo rapide
# =================================
cluster_version = "1.28"

node_groups = {
  demo = {
    instance_types = ["t3.small"]          # Économique
    min_size       = 1                     # Minimum
    max_size       = 2                     # Max contrôlé
    desired_size   = 1                     # 1 nœud pour commencer vite
    capacity_type  = "SPOT"                # SPOT pour économiser
    disk_size      = 20                    # Minimal
  }
}

# =================================
# DATABASE CONFIGURATION - Minimale
# =================================
database_config = {
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"       # Plus petite instance
  allocated_storage = 20                  # Minimum
  database_name     = "demo_db"
  username          = "root"
  password          = "DemoPass123!"      # Simple pour démo
  port              = 3306
  backup_retention  = 0                   # Pas de backup pour démo
  multi_az          = false               # Single AZ pour démo
}

# =================================
# REDIS CONFIGURATION - Minimale
# =================================
redis_config = {
  node_type       = "cache.t3.micro"      # Plus petite
  num_cache_nodes = 1                     # 1 seul
  parameter_group = "default.redis7"
  port            = 6379
  engine_version  = "7.0"
}

# =================================
# KAFKA CONFIGURATION - Minimale pour démo
# =================================
kafka_config = {
  kafka_version   = "3.5.1"
  number_of_nodes = 2                     # 2 brokers minimum
  instance_type   = "kafka.t3.small"     # Plus petit
  ebs_volume_size = 10                    # Minimal pour démo
}

# =================================
# MONITORING CONFIGURATION - Basique
# =================================
monitoring_config = {
  enable_prometheus = true                 # Pour la démo
  enable_grafana    = false                # Désactivé pour économiser
  enable_logging    = false                # Pas besoin pour démo
  retention_days    = 1                    # Minimum
}

# =================================
# MICROSERVICES CONFIGURATION - Optimisée démo
# =================================
microservices = {
  service_registry = {
    image_tag         = "latest"
    replicas          = 1                  # 1 réplique
    cpu_request       = "50m"              # Minimal
    memory_request    = "128Mi"            # Minimal
    cpu_limit         = "200m"             # Limité
    memory_limit      = "256Mi"            # Limité
    port              = 8761
    health_check_path = "/actuator/health"
  }
  
  api_gateway = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "50m"
    memory_request    = "128Mi"
    cpu_limit         = "200m"
    memory_limit      = "256Mi"
    port              = 9191
    health_check_path = "/actuator/health"
  }
  
  order_service = {
    image_tag         = "latest"
    replicas          = 1                  # 1 pour démo
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"
    memory_limit      = "384Mi"
    port              = 8080
    health_check_path = "/actuator/health"
  }
  
  payment_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"
    memory_limit      = "384Mi"
    port              = 8085
    health_check_path = "/actuator/health"
  }
  
  product_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"
    memory_limit      = "384Mi"
    port              = 8084
    health_check_path = "/actuator/health"
  }
}

# =================================
# OPTIMISATIONS DÉMO
# =================================
enable_nat_gateway        = false         # Économie max
use_spot_instances        = true          # SPOT obligatoire
enable_detailed_monitoring = false        # Pas besoin pour démo
