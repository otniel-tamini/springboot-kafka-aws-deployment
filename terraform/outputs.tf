# =================================
# VPC OUTPUTS
# =================================
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

# =================================
# EKS OUTPUTS
# =================================
output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "cluster_oidc_issuer_url" {
  description = "The URL on the EKS cluster for the OpenID Connect identity provider"
  value       = module.eks.cluster_oidc_issuer_url
}

# =================================
# DATABASE OUTPUTS
# =================================
output "database_endpoints" {
  description = "RDS instance endpoints"
  value       = module.rds.database_endpoints
  sensitive   = true
}

output "database_ports" {
  description = "RDS instance ports"
  value       = module.rds.database_ports
}

# =================================
# REDIS OUTPUTS
# =================================
output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.redis_endpoint
  sensitive   = true
}

output "redis_port" {
  description = "ElastiCache Redis port"
  value       = module.elasticache.redis_port
}

# =================================
# KAFKA OUTPUTS
# =================================
output "kafka_bootstrap_brokers" {
  description = "MSK bootstrap brokers"
  value       = module.msk.bootstrap_brokers
  sensitive   = true
}

output "kafka_zookeeper_connect_string" {
  description = "MSK Zookeeper connection string"
  value       = module.msk.zookeeper_connect_string
  sensitive   = true
}

# =================================
# SECURITY OUTPUTS
# =================================
output "database_security_group_id" {
  description = "Security group ID for databases"
  value       = module.rds.security_group_id
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = module.elasticache.security_group_id
}

output "kafka_security_group_id" {
  description = "Security group ID for Kafka"
  value       = module.msk.security_group_id
}

# =================================
# USEFUL COMMANDS
# =================================
output "kubectl_config_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

output "application_url" {
  description = "Application access information"
  value = {
    api_gateway_url   = "Access via Load Balancer or Ingress (check kubectl get svc -n default)"
    eureka_dashboard  = "Access via port-forward: kubectl port-forward svc/eureka-server 8761:8761"
    grafana_dashboard = var.enable_monitoring ? "Access via port-forward: kubectl port-forward svc/grafana 3000:3000 -n monitoring" : "Monitoring not enabled"
  }
}

# =================================
# S3 & CLOUDFRONT OUTPUTS
# =================================
output "s3_bucket_name" {
  description = "Nom du bucket S3 frontend"
  value       = module.s3_frontend.bucket_name
}

output "s3_website_endpoint" {
  description = "Endpoint du site web S3"
  value       = module.s3_frontend.website_endpoint
}

output "cloudfront_distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = module.cloudfront_frontend.distribution_id
}

output "cloudfront_domain_name" {
  description = "Domain name de CloudFront"
  value       = module.cloudfront_frontend.domain_name
}

output "cloudfront_url" {
  description = "URL complète du frontend"
  value       = "https://${module.cloudfront_frontend.domain_name}"
}

# =================================
# KUBERNETES OUTPUTS
# =================================
output "kubernetes_namespace" {
  description = "Application namespace"
  value       = module.kubernetes.namespace
}

output "eureka_service_url" {
  description = "Eureka service URL"
  value       = module.kubernetes.eureka_service_url
}
