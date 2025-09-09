# =================================
# VARIABLES DE BASE
# =================================

variable "project_name" {
  description = "Nom du projet"
  type        = string
}

variable "environment" {
  description = "Environnement (dev, staging, prod)"
  type        = string
}

# =================================
# VARIABLES S3
# =================================

variable "enable_versioning" {
  description = "Activer le versioning sur le bucket S3"
  type        = bool
  default     = true
}

variable "enable_lifecycle" {
  description = "Activer les règles de cycle de vie"
  type        = bool
  default     = true
}

variable "cors_allowed_origins" {
  description = "Origines autorisées pour CORS"
  type        = list(string)
  default     = ["*"]
}

# =================================
# VARIABLES CLOUDFRONT
# =================================

variable "enable_cloudfront_logs" {
  description = "Activer les logs CloudFront"
  type        = bool
  default     = false
}

variable "cloudfront_logs_retention_days" {
  description = "Nombre de jours de rétention des logs CloudFront"
  type        = number
  default     = 90
}

variable "default_root_object" {
  description = "Objet racine par défaut"
  type        = string
  default     = "index.html"
}

variable "domain_aliases" {
  description = "Aliases de domaine pour CloudFront"
  type        = list(string)
  default     = []
}

variable "default_cache_ttl" {
  description = "TTL de cache par défaut (en secondes)"
  type        = number
  default     = 86400  # 1 jour
}

variable "max_cache_ttl" {
  description = "TTL de cache maximum (en secondes)"
  type        = number
  default     = 31536000  # 1 an
}

variable "geo_restriction_type" {
  description = "Type de restriction géographique"
  type        = string
  default     = "none"
  validation {
    condition     = contains(["none", "whitelist", "blacklist"], var.geo_restriction_type)
    error_message = "Le type de restriction doit être 'none', 'whitelist' ou 'blacklist'."
  }
}

variable "geo_restriction_locations" {
  description = "Codes pays pour les restrictions géographiques"
  type        = list(string)
  default     = []
}

variable "ssl_certificate_arn" {
  description = "ARN du certificat SSL/TLS ACM"
  type        = string
  default     = null
}

# =================================
# VARIABLES UPLOADS UTILISATEUR
# =================================

variable "enable_user_uploads" {
  description = "Activer le bucket pour les uploads utilisateur"
  type        = bool
  default     = false
}

# =================================
# VARIABLES TAGS
# =================================

variable "additional_tags" {
  description = "Tags supplémentaires à appliquer aux ressources"
  type        = map(string)
  default     = {}
}
