# =================================
# S3 MODULE - VARIABLES
# =================================

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}

variable "enable_alb_logs" {
  description = "Activer les logs ALB dans S3"
  type        = bool
  default     = true
}

variable "enable_user_uploads" {
  description = "Activer le bucket pour les uploads utilisateurs"
  type        = bool
  default     = false
}

variable "frontend_domain" {
  description = "Domaine pour le frontend (utilisé pour les CORS)"
  type        = string
  default     = "*"
}
