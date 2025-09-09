# =================================
# DEV BUDGET VARIABLES - $200/mois
# =================================
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "springboot-kafka-dev"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "dev-budget"
}

# =================================
# VPC VARIABLES - Configuration économique
# =================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (2 AZ seulement)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (2 AZ seulement)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

# =================================
# EKS VARIABLES - Configuration économique
# =================================
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Configuration for EKS node groups - optimisée budget"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
    disk_size      = number
  }))
  default = {
    main = {
      instance_types = ["t3.small"]    # Plus petit que t3.medium
      min_size       = 1               # Minimum réduit
      max_size       = 3               # Maximum réduit
      desired_size   = 2               # 2 nœuds au lieu de 3
      capacity_type  = "SPOT"          # SPOT instances pour économiser 70%
      disk_size      = 20              # Taille disque minimale
    }
  }
}

# =================================
# DATABASE VARIABLES - Configuration partagée
# =================================
variable "database_config" {
  description = "Configuration for shared RDS database"
  type = object({
    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    database_name     = string
    username          = string
    password          = string
    port              = number
    backup_retention  = number
    multi_az          = bool
  })
  default = {
    engine            = "mysql"
    engine_version    = "8.0"
    instance_class    = "db.t3.micro"      # Plus petite instance
    allocated_storage = 20                 # Stockage minimal
    database_name     = "shared_dev_db"
    username          = "root"
    password          = "DevPassword123!"
    port              = 3306
    backup_retention  = 1                  # 1 jour seulement pour dev
    multi_az          = false              # Pas de multi-AZ pour dev
  }
}

# =================================
# REDIS VARIABLES - Configuration minimale
# =================================
variable "redis_config" {
  description = "Configuration for ElastiCache Redis - budget optimisé"
  type = object({
    node_type       = string
    num_cache_nodes = number
    parameter_group = string
    port            = number
    engine_version  = string
  })
  default = {
    node_type       = "cache.t3.micro"     # Plus petite instance
    num_cache_nodes = 1                    # 1 seul nœud
    parameter_group = "default.redis7"
    port            = 6379
    engine_version  = "7.0"
  }
}

# =================================
# KAFKA VARIABLES - Configuration économique
# =================================
variable "kafka_config" {
  description = "Configuration for MSK - optimisée budget"
  type = object({
    kafka_version   = string
    number_of_nodes = number
    instance_type   = string
    ebs_volume_size = number
  })
  default = {
    kafka_version   = "3.5.1"
    number_of_nodes = 2                    # 2 nœuds au lieu de 3
    instance_type   = "kafka.t3.small"    # Plus petite instance
    ebs_volume_size = 50                   # Stockage réduit
  }
}

# =================================
# MONITORING VARIABLES - Configuration basique
# =================================
variable "monitoring_config" {
  description = "Configuration for monitoring stack"
  type = object({
    enable_prometheus = bool
    enable_grafana    = bool
    enable_logging    = bool
    retention_days    = number
  })
  default = {
    enable_prometheus = true
    enable_grafana    = true
    enable_logging    = false              # Pas de logging centralisé pour économiser
    retention_days    = 7                  # Rétention courte
  }
}

# =================================
# MICROSERVICES VARIABLES - Configuration développement
# =================================
variable "microservices" {
  description = "Configuration for microservices - optimisée budget"
  type = map(object({
    image_tag         = string
    replicas          = number
    cpu_request       = string
    memory_request    = string
    cpu_limit         = string
    memory_limit      = string
    port              = number
    health_check_path = string
  }))
  default = {
    service_registry = {
      image_tag         = "latest"
      replicas          = 1                # 1 seule réplique pour dev
      cpu_request       = "100m"
      memory_request    = "256Mi"
      cpu_limit         = "300m"          # Limites réduites
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
      replicas          = 1                # 1 réplique au lieu de 3
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
}

# =================================
# COST OPTIMIZATION FLAGS
# =================================
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway (coûte ~$45/mois)"
  type        = bool
  default     = false                      # Désactivé pour économiser
}

variable "use_spot_instances" {
  description = "Use SPOT instances for node groups (économise 70%)"
  type        = bool
  default     = true
}

variable "enable_detailed_monitoring" {
  description = "Enable detailed CloudWatch monitoring"
  type        = bool
  default     = false                      # Désactivé pour économiser
}
