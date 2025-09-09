# =================================
# CONFIGURATION S3 + CLOUDFRONT
# =================================

# Appel du module S3
module "s3_frontend" {
  source = "../modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  
  cors_allowed_origins = [
    "https://${module.cloudfront_frontend.domain_name}",
    "http://localhost:3000"  # Pour le développement
  ]
  
  tags = var.common_tags
}

# Appel du module CloudFront
module "cloudfront_frontend" {
  source = "../modules/cloudfront"
  
  project_name           = var.project_name
  environment           = var.environment
  
  # Configuration S3
  s3_bucket_name        = module.s3_frontend.bucket_name
  s3_bucket_domain_name = module.s3_frontend.bucket_domain_name
  s3_bucket_arn         = module.s3_frontend.bucket_arn
  
  # Configuration API
  api_gateway_domain    = module.eks.cluster_endpoint
  
  # Configuration SSL (optionnel)
  domain_aliases        = var.cloudfront_aliases
  ssl_certificate_arn   = var.ssl_certificate_arn
  
  # Configuration avancée
  price_class          = var.cloudfront_price_class
  logs_bucket_name     = var.enable_cloudfront_logs ? "${var.project_name}-${var.environment}-cf-logs" : null
  auto_invalidate      = var.environment != "prod"
}

# Bucket pour les logs CloudFront (optionnel)
resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-cf-logs"
  
  tags = merge(var.common_tags, {
    Name    = "${var.project_name}-${var.environment}-cf-logs"
    Purpose = "CloudFront Logs"
  })
}

resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    id     = "log_retention"
    status = "Enabled"

    expiration {
      days = 90  # Supprimer les logs après 90 jours
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}
