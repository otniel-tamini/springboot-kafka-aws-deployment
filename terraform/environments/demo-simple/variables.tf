variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "springboot-demo"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 access (optional)"
  type        = string
  default     = ""
}
