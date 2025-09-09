# =================================
# DEV CONFIGURATION - Budget $200/mois
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
      Environment = "dev-budget"
      ManagedBy   = "terraform"
      Budget      = "200-usd-monthly"
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

# VPC Module - Configuration optimisée
module "vpc" {
  source = "../../modules/vpc"

  project_name         = var.project_name
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  availability_zones   = slice(data.aws_availability_zones.available.names, 0, 2)  # Seulement 2 AZ pour économiser
  private_subnet_cidrs = var.private_subnet_cidrs
  public_subnet_cidrs  = var.public_subnet_cidrs
}

# EKS Module - Configuration économique
module "eks" {
  source = "../../modules/eks"

  project_name    = var.project_name
  environment     = var.environment
  cluster_version = var.cluster_version

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_groups = var.node_groups
}

# RDS Module - Configuration simplifiée
module "rds" {
  source = "../../modules/rds"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  # Convertir la config en format attendu par le module existant
  databases = {
    shared_db = {
      engine            = var.database_config.engine
      engine_version    = var.database_config.engine_version
      instance_class    = var.database_config.instance_class
      allocated_storage = var.database_config.allocated_storage
      database_name     = var.database_config.database_name
      username          = var.database_config.username
      password          = var.database_config.password
      port              = var.database_config.port
    }
  }
}

# ElastiCache Redis Module - Configuration minimale
module "elasticache" {
  source = "../../modules/elasticache"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  redis_config = var.redis_config
}

# MSK Module - Configuration économique
module "msk" {
  source = "../../modules/msk"

  project_name = var.project_name
  environment  = var.environment

  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids

  kafka_config = var.kafka_config
}

# Monitoring Module - Configuration basique
module "monitoring" {
  source = "../../modules/monitoring"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}

# Kubernetes Applications Module
module "kubernetes" {
  source = "../../modules/kubernetes"

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
    shared_db = var.database_config.password
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
