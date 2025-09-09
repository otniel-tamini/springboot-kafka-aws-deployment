# =================================
# VARIABLES CLOUDFRONT
# =================================

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "springboot-kafka"
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}

variable "s3_bucket_name" {
  description = "Nom du bucket S3 frontend"
  type        = string
}

variable "s3_bucket_domain_name" {
  description = "Domain name du bucket S3"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN du bucket S3"
  type        = string
}

variable "api_gateway_domain" {
  description = "Domain de l'API Gateway/Load Balancer"
  type        = string
}

variable "domain_aliases" {
  description = "Aliases de domaine pour CloudFront"
  type        = list(string)
  default     = []
}

variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL ACM (optionnel)"
  type        = string
  default     = null
}

variable "price_class" {
  description = "Classe de prix CloudFront"
  type        = string
  default     = "PriceClass_100"  # USA, Canada, Europe
  
  validation {
    condition = contains([
      "PriceClass_All",
      "PriceClass_200", 
      "PriceClass_100"
    ], var.price_class)
    error_message = "Price class must be PriceClass_All, PriceClass_200, or PriceClass_100."
  }
}

variable "logs_bucket_name" {
  description = "Nom du bucket pour les logs CloudFront (optionnel)"
  type        = string
  default     = null
}

variable "auto_invalidate" {
  description = "Activer l'invalidation automatique lors des déploiements"
  type        = bool
  default     = false
}
