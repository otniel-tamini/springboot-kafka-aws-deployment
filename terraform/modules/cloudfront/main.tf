# =================================
# CLOUDFRONT MODULE - CDN POUR FRONTEND
# =================================

# Distribution CloudFront pour le frontend
resource "aws_cloudfront_distribution" "frontend" {
  comment = "${var.project_name} ${var.environment} Frontend Distribution"
  
  # Origin S3
  origin {
    domain_name = var.s3_bucket_domain_name
    origin_id   = "S3-${var.s3_bucket_name}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.frontend.cloudfront_access_identity_path
    }
  }

  # Origin API Gateway pour les appels API
  origin {
    domain_name = var.api_gateway_domain
    origin_id   = "API-Gateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = var.domain_aliases

  # Comportement par défaut pour les fichiers statiques
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    compress = true
  }

  # Comportement pour les appels API
  ordered_cache_behavior {
    path_pattern     = "/api/*"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "API-Gateway"

    forwarded_values {
      query_string = true
      headers      = ["Authorization", "Content-Type", "Accept"]
      cookies {
        forward = "all"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0  # Ne pas cacher les réponses API
    max_ttl                = 0

    compress = true
  }

  # Comportement pour les fichiers JS/CSS avec cache long
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${var.s3_bucket_name}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 31536000  # 1 an
    default_ttl            = 31536000
    max_ttl                = 31536000

    compress = true
  }

  # Pages d'erreur personnalisées
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Restrictions géographiques
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Configuration SSL
  viewer_certificate {
    cloudfront_default_certificate = var.ssl_certificate_arn == null
    acm_certificate_arn            = var.ssl_certificate_arn
    ssl_support_method             = var.ssl_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.ssl_certificate_arn != null ? "TLSv1.2_2021" : null
  }

  # Configuration des logs
  logging_config {
    include_cookies = false
    bucket          = var.logs_bucket_name != null ? "${var.logs_bucket_name}.s3.amazonaws.com" : null
    prefix          = "cloudfront-logs/"
  }

  # Prix class
  price_class = var.price_class

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Environment = var.environment
    Purpose     = "Frontend CDN"
  }
}

# Origin Access Identity pour sécuriser l'accès S3
resource "aws_cloudfront_origin_access_identity" "frontend" {
  comment = "${var.project_name} ${var.environment} OAI"
}

# Policy S3 pour autoriser CloudFront
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = var.s3_bucket_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontAccess"
        Effect = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.frontend.iam_arn
        }
        Action   = "s3:GetObject"
        Resource = "${var.s3_bucket_arn}/*"
      }
    ]
  })
}

# Invalidation automatique pour les déploiements
resource "aws_cloudfront_invalidation" "frontend" {
  count               = var.auto_invalidate ? 1 : 0
  distribution_id     = aws_cloudfront_distribution.frontend.id
  
  paths = [
    "/index.html",
    "/static/js/*",
    "/static/css/*"
  ]
}
