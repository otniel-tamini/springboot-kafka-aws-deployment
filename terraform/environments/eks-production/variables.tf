# =================================
# VARIABLES - Configuration EKS Production
# =================================

variable "aws_region" {
  description = "AWS region pour le déploiement"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "springboot-microservices"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
  default     = "production"
}

# =================================
# NETWORK CONFIGURATION
# =================================
variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks pour les subnets privés"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks pour les subnets publics"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# =================================
# EKS CONFIGURATION
# =================================
variable "cluster_version" {
  description = "Version Kubernetes pour EKS"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Configuration des node groups EKS"
  type = map(object({
    instance_types = list(string)
    min_size       = number
    max_size       = number
    desired_size   = number
    capacity_type  = string
    disk_size      = number
  }))
  default = {
    # Node group principal pour les microservices
    microservices = {
      instance_types = ["t3.large"]
      desired_size   = 3
      max_size       = 6
      min_size       = 3
      disk_size      = 50
      capacity_type  = "ON_DEMAND"
    }
    
    # Node group pour les services d'infrastructure
    infrastructure = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      max_size       = 4
      min_size       = 2
      disk_size      = 30
      capacity_type  = "ON_DEMAND"
    }
    
    # Node group pour le monitoring (optionnel mais recommandé)
    monitoring = {
      instance_types = ["t3.medium"]
      desired_size   = 1
      max_size       = 2
      min_size       = 1
      disk_size      = 40
      capacity_type  = "SPOT"  # Économie pour monitoring
    }
  }
}

# =================================
# DATABASE CONFIGURATION
# =================================
variable "databases" {
  description = "Configuration des bases de données RDS"
  type = map(object({
    engine            = string
    engine_version    = string
    instance_class    = string
    allocated_storage = number
    database_name     = string
    username          = string
    password          = string
    port              = number
  }))
  default = {
    order_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.medium"
      allocated_storage = 100
      database_name     = "order_service_db"
      username          = "order_admin"
      password          = "OrderSecurePassword123!"
      port              = 3306
    }
    
    identity_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.medium"
      allocated_storage = 50
      database_name     = "identity_service_db"
      username          = "identity_admin"
      password          = "IdentitySecurePassword123!"
      port              = 3306
    }
    
    payment_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.medium"
      allocated_storage = 50
      database_name     = "payment_service_db"
      username          = "payment_admin"
      password          = "PaymentSecurePassword123!"
      port              = 3306
    }
    
    product_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.medium"
      allocated_storage = 100
      database_name     = "product_service_db"
      username          = "product_admin"
      password          = "ProductSecurePassword123!"
      port              = 3306
    }
  }
}

# =================================
# REDIS CONFIGURATION
# =================================
variable "redis_config" {
  description = "Configuration ElastiCache Redis"
  type = object({
    node_type       = string
    num_cache_nodes = number
    parameter_group = string
    port            = number
    engine_version  = string
  })
  default = {
    node_type       = "cache.t3.medium"
    num_cache_nodes = 1  # Redis ne supporte qu'un seul nœud
    parameter_group = "default.redis7"
    port            = 6379
    engine_version  = "7.0"
  }
}

# =================================
# KAFKA CONFIGURATION
# =================================
variable "kafka_config" {
  description = "Configuration Amazon MSK"
  type = object({
    kafka_version   = string
    number_of_nodes = number
    instance_type   = string
    ebs_volume_size = number
  })
  default = {
    kafka_version   = "3.7.x"  # Version supportée
    number_of_nodes = 3
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 100
  }
}
