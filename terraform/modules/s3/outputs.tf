# =================================
# S3 MODULE - OUTPUTS
# =================================

output "frontend_bucket_name" {
  description = "Nom du bucket S3 pour le frontend"
  value       = aws_s3_bucket.frontend_static.bucket
}

output "frontend_bucket_arn" {
  description = "ARN du bucket S3 pour le frontend"
  value       = aws_s3_bucket.frontend_static.arn
}

output "frontend_website_endpoint" {
  description = "Endpoint du site web S3"
  value       = aws_s3_bucket_website_configuration.frontend_static.website_endpoint
}

output "frontend_website_domain" {
  description = "Domaine du site web S3"
  value       = aws_s3_bucket_website_configuration.frontend_static.website_domain
}

output "alb_logs_bucket_name" {
  description = "Nom du bucket pour les logs ALB"
  value       = var.enable_alb_logs ? aws_s3_bucket.alb_logs[0].bucket : null
}

output "alb_logs_bucket_arn" {
  description = "ARN du bucket pour les logs ALB"
  value       = var.enable_alb_logs ? aws_s3_bucket.alb_logs[0].arn : null
}

output "user_uploads_bucket_name" {
  description = "Nom du bucket pour les uploads utilisateurs"
  value       = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].bucket : null
}

output "user_uploads_bucket_arn" {
  description = "ARN du bucket pour les uploads utilisateurs"
  value       = var.enable_user_uploads ? aws_s3_bucket.user_uploads[0].arn : null
}
