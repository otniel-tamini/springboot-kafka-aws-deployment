# =================================
# DEV BUDGET VALUES - ~$200/mois
# =================================
aws_region = "us-west-2"

project_name = "springboot-kafka-dev"
environment  = "dev-budget"

# =================================
# VPC CONFIGURATION
# =================================
vpc_cidr             = "10.0.0.0/16"
private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]        # 2 AZ seulement
public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24"]    # 2 AZ seulement

# =================================
# EKS CONFIGURATION - Optimisée budget
# =================================
cluster_version = "1.28"

node_groups = {
  main = {
    instance_types = ["t3.small"]          # Plus petit et économique
    min_size       = 1                     # Minimum pour autoscaling
    max_size       = 3                     # Maximum contrôlé
    desired_size   = 2                     # 2 nœuds pour commencer
    capacity_type  = "SPOT"                # SPOT pour économiser 70%
    disk_size      = 20                    # Taille minimale
  }
}

# =================================
# DATABASE CONFIGURATION - Partagée
# =================================
database_config = {
  engine            = "mysql"
  engine_version    = "8.0"
  instance_class    = "db.t3.micro"       # Instance minimale
  allocated_storage = 20                  # 20GB seulement
  database_name     = "shared_dev_db"     # Base unique partagée
  username          = "root"
  password          = "DevSecurePass123!" # Mot de passe sécurisé
  port              = 3306
  backup_retention  = 1                   # 1 jour pour dev
  multi_az          = false               # Pas de multi-AZ pour dev
}

# =================================
# REDIS CONFIGURATION - Minimale
# =================================
redis_config = {
  node_type       = "cache.t3.micro"      # Plus petite instance
  num_cache_nodes = 1                     # 1 seul nœud
  parameter_group = "default.redis7"
  port            = 6379
  engine_version  = "7.0"
}

# =================================
# KAFKA CONFIGURATION - Économique
# =================================
kafka_config = {
  kafka_version   = "3.5.1"
  number_of_nodes = 2                     # 2 brokers au lieu de 3
  instance_type   = "kafka.t3.small"     # Instance plus petite
  ebs_volume_size = 50                    # Stockage réduit
}

# =================================
# MONITORING CONFIGURATION - Basique
# =================================
monitoring_config = {
  enable_prometheus = true                 # Monitoring basique
  enable_grafana    = true                 # Dashboard simple
  enable_logging    = false                # Pas de logging centralisé (coût)
  retention_days    = 7                    # Rétention courte
}

# =================================
# MICROSERVICES CONFIGURATION - Dev optimisée
# =================================
microservices = {
  service_registry = {
    image_tag         = "latest"
    replicas          = 1                  # 1 réplique pour dev
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"            # Limites raisonnables
    memory_limit      = "384Mi"
    port              = 8761
    health_check_path = "/actuator/health"
  }
  
  api_gateway = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"
    memory_limit      = "384Mi"
    port              = 9191
    health_check_path = "/actuator/health"
  }
  
  order_service = {
    image_tag         = "latest"
    replicas          = 1                  # 1 réplique au lieu de 3
    cpu_request       = "150m"
    memory_request    = "384Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 8080
    health_check_path = "/actuator/health"
  }
  
  payment_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "150m"
    memory_request    = "384Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 8085
    health_check_path = "/actuator/health"
  }
  
  product_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "150m"
    memory_request    = "384Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 8084
    health_check_path = "/actuator/health"
  }
  
  email_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "100m"
    memory_request    = "256Mi"
    cpu_limit         = "300m"
    memory_limit      = "384Mi"
    port              = 8086
    health_check_path = "/actuator/health"
  }
  
  identity_service = {
    image_tag         = "latest"
    replicas          = 1
    cpu_request       = "150m"
    memory_request    = "384Mi"
    cpu_limit         = "500m"
    memory_limit      = "512Mi"
    port              = 9898
    health_check_path = "/actuator/health"
  }
}

# =================================
# COST OPTIMIZATION FLAGS
# =================================
enable_nat_gateway        = false         # Économise $45/mois
use_spot_instances        = true          # Économise 70% sur EC2
enable_detailed_monitoring = false        # Économise sur CloudWatch
