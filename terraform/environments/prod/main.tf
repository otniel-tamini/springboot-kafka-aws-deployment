# =================================
# PRODUCTION ENVIRONMENT MAIN CONFIG
# =================================

terraform {
  required_version = ">= 1.0"

  # Configure remote state for production
  # backend "s3" {
  #   bucket = "your-terraform-state-bucket"
  #   key    = "environments/prod/terraform.tfstate"
  #   region = "us-west-2"
  # }
}

# Include the main configuration
module "infrastructure" {
  source = "../../"

  # All variables are defined in terraform.tfvars
}

# Output the important values
output "cluster_name" {
  value = module.infrastructure.cluster_name
}

output "cluster_endpoint" {
  value     = module.infrastructure.cluster_endpoint
  sensitive = true
}

output "vpc_id" {
  value = module.infrastructure.vpc_id
}

output "kubectl_config_command" {
  value = module.infrastructure.kubectl_config_command
}
