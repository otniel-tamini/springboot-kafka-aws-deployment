variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kafka_bootstrap_servers" {
  description = "Kafka bootstrap servers"
  type        = string
}

variable "redis_endpoint" {
  description = "Redis endpoint"
  type        = string
}

variable "redis_port" {
  description = "Redis port"
  type        = number
}

variable "database_endpoints" {
  description = "Database endpoints"
  type        = map(string)
}

variable "database_passwords" {
  description = "Database passwords"
  type        = map(string)
  sensitive   = true
}

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
}
