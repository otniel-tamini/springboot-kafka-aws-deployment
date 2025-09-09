# =================================
# FREE TIER DEV VARIABLES
# =================================
variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"  # us-east-1 has more free tier benefits
}

variable "project_name" {
  description = "The name of the project"
  type        = string
  default     = "springboot-kafka-dev"
}

variable "db_password" {
  description = "Password for the MySQL database"
  type        = string
  sensitive   = true
  default     = "DevPassword123!"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access"
  type        = string
  # Generate with: ssh-keygen -t rsa -b 2048 -f ~/.ssh/aws-dev-key
  # Then use: cat ~/.ssh/aws-dev-key.pub
}

# =================================
# MICROSERVICES CONFIGURATION
# =================================
variable "docker_images" {
  description = "Docker images for microservices"
  type = map(string)
  default = {
    service_registry = "your-dockerhub/service-registry:dev"
    api_gateway     = "your-dockerhub/api-gateway:dev"
    order_service   = "your-dockerhub/order-service:dev"
    payment_service = "your-dockerhub/payment-service:dev"
    product_service = "your-dockerhub/product-service:dev"
    email_service   = "your-dockerhub/email-service:dev"
    identity_service = "your-dockerhub/identity-service:dev"
  }
}

variable "enable_monitoring" {
  description = "Enable basic monitoring (Prometheus)"
  type        = bool
  default     = false  # Disabled for cost savings
}
