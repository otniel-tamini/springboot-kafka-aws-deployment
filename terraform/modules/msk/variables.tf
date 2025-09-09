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

variable "kafka_config" {
  description = "Configuration for MSK (Managed Streaming for Kafka)"
  type = object({
    kafka_version   = string
    number_of_nodes = number
    instance_type   = string
    ebs_volume_size = number
  })
}
