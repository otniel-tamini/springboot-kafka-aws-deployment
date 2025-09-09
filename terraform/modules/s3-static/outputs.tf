# =================================
# OUTPUTS S3 BUCKET PRINCIPAL
# =================================

output "s3_bucket_id" {
  description = "ID du bucket S3 pour les fichiers statiques"
  value       = aws_s3_bucket.static_files.id
}

output "s3_bucket_arn" {
  description = "ARN du bucket S3 pour les fichiers statiques"
  value       = aws_s3_bucket.static_files.arn
}

output "s3_bucket_domain_name" {
  description = "Nom de domaine du bucket S3"
  value       = aws_s3_bucket.static_files.bucket_domain_name
}

output "s3_bucket_regional_domain_name" {
  description = "Nom de domaine régional du bucket S3"
  value       = aws_s3_bucket.static_files.bucket_regional_domain_name
}

output "s3_bucket_website_endpoint" {
  description = "Endpoint du site web S3"
  value       = aws_s3_bucket.static_files.website_endpoint
}

# =================================
# OUTPUTS CLOUDFRONT
# =================================

output "cloudfront_distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = aws_cloudfront_distribution.static_files.id
}

output "cloudfront_distribution_arn" {
  description = "ARN de la distribution CloudFront"
  value       = aws_cloudfront_distribution.static_files.arn
}

output "cloudfront_domain_name" {
  description = "Nom de domaine CloudFront"
  value       = aws_cloudfront_distribution.static_files.domain_name
}

output "cloudfront_hosted_zone_id" {
  description = "ID de la zone hébergée CloudFront"
  value       = aws_cloudfront_distribution.static_files.hosted_zone_id
}

output "cloudfront_status" {
  description = "Statut de la distribution CloudFront"
  value       = aws_cloudfront_distribution.static_files.status
}

# =================================
# OUTPUTS BUCKET LOGS (CONDITIONNEL)
# =================================

output "cloudfront_logs_bucket_id" {
  description = "ID du bucket pour les logs CloudFront"
  value       = var.enable_cloudfront_logs ? aws_s3_bucket.cloudfront_logs[0].id : null
}

output "cloudfront_logs_bucket_arn" {
  description = "ARN du bucket pour les logs CloudFront"
  value       = var.enable_cloudfront_logs ? aws_s3_bucket.cloudfront_logs[0].arn : null
}

# =================================
# OUTPUTS BUCKET UPLOADS (CONDITIONNEL)
# =================================

output "user_uploads_bucket_id" {
  description = "ID du bucket pour les uploads utilisateur"
  value       = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].id : null
}

output "user_uploads_bucket_arn" {
  description = "ARN du bucket pour les uploads utilisateur"
  value       = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].arn : null
}

output "user_uploads_bucket_domain_name" {
  description = "Nom de domaine du bucket uploads"
  value       = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].bucket_domain_name : null
}

# =================================
# OUTPUTS POUR INTÉGRATION CI/CD
# =================================

output "deployment_info" {
  description = "Informations nécessaires pour le déploiement"
  value = {
    bucket_name           = aws_s3_bucket.static_files.bucket
    cloudfront_id         = aws_cloudfront_distribution.static_files.id
    cloudfront_url        = "https://${aws_cloudfront_distribution.static_files.domain_name}"
    invalidation_paths    = ["/*"]
    upload_path_prefix    = ""
  }
}

# =================================
# OUTPUTS POUR ANSIBLE
# =================================

output "ansible_vars" {
  description = "Variables pour l'intégration Ansible"
  value = {
    s3_static_bucket      = aws_s3_bucket.static_files.bucket
    cloudfront_id         = aws_cloudfront_distribution.static_files.id
    cloudfront_domain     = aws_cloudfront_distribution.static_files.domain_name
    s3_region            = aws_s3_bucket.static_files.region
    user_uploads_bucket   = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].bucket : null
  }
}

# =================================
# OUTPUTS POUR FRONTEND CONFIG
# =================================

output "frontend_config" {
  description = "Configuration pour le frontend"
  value = {
    api_base_url          = "https://${aws_cloudfront_distribution.static_files.domain_name}/api"
    static_assets_url     = "https://${aws_cloudfront_distribution.static_files.domain_name}"
    upload_endpoint       = var.enable_user_uploads ? "https://${aws_s3_bucket.user_uploads[0].bucket_regional_domain_name}" : null
    cdn_domain           = aws_cloudfront_distribution.static_files.domain_name
  }
}

# =================================
# OUTPUTS DE SÉCURITÉ
# =================================

output "security_info" {
  description = "Informations de sécurité"
  value = {
    origin_access_control_id = aws_cloudfront_origin_access_control.static_files.id
    bucket_policy_applied    = true
    public_access_blocked    = true
    encryption_enabled       = true
  }
  sensitive = false
}
