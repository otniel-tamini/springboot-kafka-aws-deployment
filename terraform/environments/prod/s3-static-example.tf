# =================================
# EXEMPLE D'UTILISATION DU MODULE S3-STATIC
# =================================

# Utilisation dans un environnement de production
module "s3_static_prod" {
  source = "../modules/s3-static"

  # Configuration de base
  project_name = "ecommerce-platform"
  environment  = "prod"

  # Configuration S3
  enable_versioning = true
  enable_lifecycle  = true
  cors_allowed_origins = [
    "https://ecommerce-platform.com",
    "https://www.ecommerce-platform.com",
    "https://api.ecommerce-platform.com"
  ]

  # Configuration CloudFront
  enable_cloudfront_logs = true
  default_cache_ttl      = 86400     # 1 jour
  max_cache_ttl          = 31536000  # 1 an
  
  # Domaine personnalisé
  domain_aliases = ["static.ecommerce-platform.com"]
  ssl_certificate_arn = var.ssl_certificate_arn

  # Bucket pour uploads utilisateur
  enable_user_uploads = true

  # Restrictions géographiques (EU uniquement)
  geo_restriction_type = "whitelist"
  geo_restriction_locations = [
    "FR", "DE", "IT", "ES", "BE", "NL", "CH", "AT"
  ]

  # Tags supplémentaires
  additional_tags = {
    CostCenter = "frontend"
    Owner      = "platform-team"
    Backup     = "daily"
  }
}

# =================================
# OUTPUTS POUR INTÉGRATION
# =================================

# Pour Ansible
output "s3_static_ansible_vars" {
  description = "Variables S3 pour Ansible"
  value = module.s3_static_prod.ansible_vars
}

# Pour la configuration frontend
output "frontend_static_config" {
  description = "Configuration pour le frontend"
  value = module.s3_static_prod.frontend_config
}

# Pour le CI/CD
output "deployment_configuration" {
  description = "Configuration pour le déploiement"
  value = module.s3_static_prod.deployment_info
}

# =================================
# EXEMPLE POUR DÉVELOPPEMENT
# =================================

module "s3_static_dev" {
  source = "../modules/s3-static"

  project_name = "ecommerce-platform"
  environment  = "dev"

  # Configuration simplifiée pour dev
  enable_versioning      = false
  enable_lifecycle       = false
  enable_cloudfront_logs = false
  enable_user_uploads    = false

  # CORS ouvert pour dev
  cors_allowed_origins = ["*"]

  # Cache plus court pour dev
  default_cache_ttl = 300  # 5 minutes
  max_cache_ttl     = 3600 # 1 heure
}

# =================================
# EXEMPLE POUR STAGING
# =================================

module "s3_static_staging" {
  source = "../modules/s3-static"

  project_name = "ecommerce-platform"
  environment  = "staging"

  # Configuration intermédiaire
  enable_versioning = true
  enable_lifecycle  = false
  enable_cloudfront_logs = false
  
  cors_allowed_origins = [
    "https://staging.ecommerce-platform.com",
    "https://api-staging.ecommerce-platform.com"
  ]

  # Logs CloudFront avec rétention courte
  cloudfront_logs_retention_days = 30

  # Uploads pour tests
  enable_user_uploads = true
}
