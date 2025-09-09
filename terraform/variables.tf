# =================================
# GENERAL VARIABLES
# =================================
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "springboot-kafka-microservices"
}

variable "environment" {
  description = "The deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# =================================
# VPC VARIABLES
# =================================
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

# =================================
# EKS VARIABLES
# =================================
variable "cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.28"
}

variable "node_groups" {
  description = "Configuration for EKS node groups"
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
      instance_types = ["t3.medium"]
      min_size       = 2
      max_size       = 6
      desired_size   = 3
      capacity_type  = "ON_DEMAND"
      disk_size      = 20
    }
  }
}

# =================================
# DATABASE VARIABLES
# =================================
variable "databases" {
  description = "Configuration for RDS databases"
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
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      database_name     = "order_db"
      username          = "root"
      password          = "root123"
      port              = 3306
    }
    identity_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      database_name     = "user_db"
      username          = "root"
      password          = "root123"
      port              = 3306
    }
    payment_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      database_name     = "payment_db"
      username          = "root"
      password          = "root123"
      port              = 3306
    }
    product_db = {
      engine            = "mysql"
      engine_version    = "8.0"
      instance_class    = "db.t3.micro"
      allocated_storage = 20
      database_name     = "product_db"
      username          = "root"
      password          = "root123"
      port              = 3306
    }
  }
}

# =================================
# REDIS VARIABLES
# =================================
variable "redis_config" {
  description = "Configuration for ElastiCache Redis"
  type = object({
    node_type       = string
    num_cache_nodes = number
    parameter_group = string
    port            = number
    engine_version  = string
  })
  default = {
    node_type       = "cache.t3.micro"
    num_cache_nodes = 1
    parameter_group = "default.redis7"
    port            = 6379
    engine_version  = "7.0"
  }
}

# =================================
# KAFKA VARIABLES
# =================================
variable "kafka_config" {
  description = "Configuration for MSK (Managed Streaming for Kafka)"
  type = object({
    kafka_version   = string
    number_of_nodes = number
    instance_type   = string
    ebs_volume_size = number
  })
  default = {
    kafka_version   = "3.5.1"
    number_of_nodes = 3
    instance_type   = "kafka.t3.small"
    ebs_volume_size = 100
  }
}

# =================================
# MONITORING VARIABLES
# =================================
variable "enable_monitoring" {
  description = "Enable monitoring stack (Prometheus, Grafana, etc.)"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable centralized logging"
  type        = bool
  default     = true
}

# =================================
# MICROSERVICES VARIABLES
# =================================
variable "microservices" {
  description = "Configuration for microservices"
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
      replicas          = 2
      cpu_request       = "100m"
      memory_request    = "256Mi"
      cpu_limit         = "500m"
      memory_limit      = "512Mi"
      port              = 8761
      health_check_path = "/actuator/health"
    }
    api_gateway = {
      image_tag         = "latest"
      replicas          = 2
      cpu_request       = "100m"
      memory_request    = "256Mi"
      cpu_limit         = "500m"
      memory_limit      = "512Mi"
      port              = 9191
      health_check_path = "/actuator/health"
    }
    order_service = {
      image_tag         = "latest"
      replicas          = 3
      cpu_request       = "200m"
      memory_request    = "512Mi"
      cpu_limit         = "1000m"
      memory_limit      = "1Gi"
      port              = 8080
      health_check_path = "/actuator/health"
    }
    payment_service = {
      image_tag         = "latest"
      replicas          = 2
      cpu_request       = "200m"
      memory_request    = "512Mi"
      cpu_limit         = "1000m"
      memory_limit      = "1Gi"
      port              = 8085
      health_check_path = "/actuator/health"
    }
    product_service = {
      image_tag         = "latest"
      replicas          = 3
      cpu_request       = "200m"
      memory_request    = "512Mi"
      cpu_limit         = "1000m"
      memory_limit      = "1Gi"
      port              = 8084
      health_check_path = "/actuator/health"
    }
    email_service = {
      image_tag         = "latest"
      replicas          = 2
      cpu_request       = "100m"
      memory_request    = "256Mi"
      cpu_limit         = "500m"
      memory_limit      = "512Mi"
      port              = 8086
      health_check_path = "/actuator/health"
    }
    identity_service = {
      image_tag         = "latest"
      replicas          = 2
      cpu_request       = "200m"
      memory_request    = "512Mi"
      cpu_limit         = "1000m"
      memory_limit      = "1Gi"
      port              = 9898
      health_check_path = "/actuator/health"
    }
  }
}

# =================================
# S3 & CLOUDFRONT VARIABLES
# =================================
variable "cloudfront_aliases" {
  description = "Aliases de domaine pour CloudFront"
  type        = list(string)
  default     = []
}

variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL ACM (optionnel)"
  type        = string
  default     = null
}

variable "cloudfront_price_class" {
  description = "Classe de prix CloudFront"
  type        = string
  default     = "PriceClass_100"
}

variable "enable_cloudfront_logs" {
  description = "Activer les logs CloudFront"
  type        = bool
  default     = false
}

# =================================
# COMMON TAGS
# =================================
variable "common_tags" {
  description = "Tags communs à appliquer à toutes les ressources"
  type        = map(string)
  default = {
    Project     = "springboot-kafka-microservices"
    ManagedBy   = "Terraform"
    Owner       = "DevOps Team"
  }
}

# =================================
# PAYPAL VARIABLES (Optional)
# =================================
variable "paypal_client_id" {
  description = "PayPal Client ID"
  type        = string
  default     = ""
  sensitive   = true
}

variable "paypal_client_secret" {
  description = "PayPal Client Secret"
  type        = string
  default     = ""
  sensitive   = true
}

variable "paypal_base_url" {
  description = "PayPal Base URL"
  type        = string
  default     = "https://api.sandbox.paypal.com"
}
