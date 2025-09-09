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
}
