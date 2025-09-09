variable "project_name" {
  description = "The name of the project"
  type        = string
}

variable "environment" {
  description = "The deployment environment"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets"
  type        = list(string)
}

variable "redis_config" {
  description = "Configuration for ElastiCache Redis"
  type = object({
    node_type       = string
    num_cache_nodes = number
    parameter_group = string
    port            = number
    engine_version  = string
  })
}
