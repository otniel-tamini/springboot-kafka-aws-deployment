# =================================
# OUTPUTS CLOUDFRONT
# =================================

output "distribution_id" {
  description = "ID de la distribution CloudFront"
  value       = aws_cloudfront_distribution.frontend.id
}

output "distribution_arn" {
  description = "ARN de la distribution CloudFront"
  value       = aws_cloudfront_distribution.frontend.arn
}

output "domain_name" {
  description = "Domain name de la distribution CloudFront"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "hosted_zone_id" {
  description = "Hosted Zone ID CloudFront pour Route53"
  value       = aws_cloudfront_distribution.frontend.hosted_zone_id
}

output "origin_access_identity_id" {
  description = "ID de l'Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.frontend.id
}

output "origin_access_identity_arn" {
  description = "ARN de l'Origin Access Identity"
  value       = aws_cloudfront_origin_access_identity.frontend.iam_arn
}

output "distribution_status" {
  description = "Status de la distribution CloudFront"
  value       = aws_cloudfront_distribution.frontend.status
}

output "etag" {
  description = "ETag de la distribution"
  value       = aws_cloudfront_distribution.frontend.etag
}
