# =================================
# TERRAFORM CONFIGURATION
# =================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

# =================================
# PROVIDER CONFIGURATION
# =================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

provider "kubernetes" {
  host                   = try(module.eks.cluster_endpoint, "")
  cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", try(module.eks.cluster_name, "")]
  }
}

provider "helm" {
  kubernetes {
    host                   = try(module.eks.cluster_endpoint, "")
    cluster_ca_certificate = try(base64decode(module.eks.cluster_certificate_authority_data), "")

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", try(module.eks.cluster_name, "")]
    }
  }
}

# =================================
# DATA SOURCES
# =================================
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_caller_identity" "current" {}

# =================================
# MODULES
# =================================

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = data.aws_availability_zones.available.names
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_groups = var.node_groups
}

# RDS Module for databases
module "rds" {
  source = "./modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  databases = var.databases
}

# ElastiCache Redis Module
module "elasticache" {
  source = "./modules/elasticache"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  redis_config = var.redis_config
}

# MSK (Managed Kafka) Module
module "msk" {
  source = "./modules/msk"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  kafka_config = var.kafka_config
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}

# Kubernetes Applications Module
module "kubernetes" {
  source = "./modules/kubernetes"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.eks.cluster_name

  # Infrastructure endpoints
  kafka_bootstrap_servers = module.msk.bootstrap_brokers
  redis_endpoint          = module.elasticache.redis_endpoint
  redis_port              = module.elasticache.redis_port
  database_endpoints      = module.rds.database_endpoints

  # Database passwords
  database_passwords = {
    order_db    = var.databases.order_db.password
    identity_db = var.databases.identity_db.password
    payment_db  = var.databases.payment_db.password
    product_db  = var.databases.product_db.password
  }

  # Microservices configuration
  microservices = var.microservices

  depends_on = [
    module.eks,
    module.rds,
    module.elasticache,
    module.msk,
    module.monitoring
  ]
}

# S3 + CloudFront pour le frontend
module "s3_frontend" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  
  cors_allowed_origins = [
    "https://${module.cloudfront_frontend.domain_name}",
    "http://localhost:3000"  # Pour le développement
  ]
  
  tags = var.common_tags
}

module "cloudfront_frontend" {
  source = "./modules/cloudfront"
  
  project_name           = var.project_name
  environment           = var.environment
  
  # Configuration S3
  s3_bucket_name        = module.s3_frontend.bucket_name
  s3_bucket_domain_name = module.s3_frontend.bucket_domain_name
  s3_bucket_arn         = module.s3_frontend.bucket_arn
  
  # Configuration API (utilise l'ALB du cluster EKS)
  api_gateway_domain    = replace(module.eks.cluster_endpoint, "https://", "")
  
  # Configuration SSL (optionnel)
  domain_aliases        = var.cloudfront_aliases
  ssl_certificate_arn   = var.ssl_certificate_arn
  
  # Configuration avancée
  price_class          = var.cloudfront_price_class
  logs_bucket_name     = var.enable_cloudfront_logs ? "${var.project_name}-${var.environment}-cf-logs" : null
  auto_invalidate      = var.environment != "prod"
}
