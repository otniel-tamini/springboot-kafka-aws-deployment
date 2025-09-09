# =================================
# S3 BUCKET POUR FICHIERS STATIQUES
# =================================

# Bucket S3 principal pour les fichiers statiques
resource "aws_s3_bucket" "static_files" {
  bucket = "${var.project_name}-${var.environment}-static-files"

  tags = {
    Name        = "${var.project_name}-${var.environment}-static-files"
    Environment = var.environment
    Purpose     = "static-files"
  }
}

# Configuration du versioning
resource "aws_s3_bucket_versioning" "static_files" {
  bucket = aws_s3_bucket.static_files.id
  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Configuration du chiffrement
resource "aws_s3_bucket_server_side_encryption_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Bloquer l'accès public (géré via CloudFront)
resource "aws_s3_bucket_public_access_block" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configuration du cycle de vie
resource "aws_s3_bucket_lifecycle_configuration" "static_files" {
  count  = var.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.static_files.id

  rule {
    id     = "static_files_lifecycle"
    status = "Enabled"

    # Transition vers IA après 30 jours
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    # Transition vers Glacier après 90 jours
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    # Supprimer les anciennes versions après 365 jours
    noncurrent_version_expiration {
      noncurrent_days = 365
    }

    # Supprimer les uploads multipart incomplets après 7 jours
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# CORS pour permettre l'accès depuis le frontend
resource "aws_s3_bucket_cors_configuration" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# =================================
# BUCKET POUR LOGS CLOUDFRONT
# =================================

resource "aws_s3_bucket" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-cloudfront-logs"

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront-logs"
    Environment = var.environment
    Purpose     = "cloudfront-logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle pour les logs CloudFront
resource "aws_s3_bucket_lifecycle_configuration" "cloudfront_logs" {
  count  = var.enable_cloudfront_logs ? 1 : 0
  bucket = aws_s3_bucket.cloudfront_logs[0].id

  rule {
    id     = "cloudfront_logs_lifecycle"
    status = "Enabled"

    # Supprimer les logs après 90 jours
    expiration {
      days = var.cloudfront_logs_retention_days
    }

    # Transition vers IA après 30 jours
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
}

# =================================
# CLOUDFRONT DISTRIBUTION
# =================================

# Origin Access Control pour CloudFront
resource "aws_cloudfront_origin_access_control" "static_files" {
  name                              = "${var.project_name}-${var.environment}-oac"
  description                       = "OAC for static files bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Distribution CloudFront
resource "aws_cloudfront_distribution" "static_files" {
  origin {
    domain_name              = aws_s3_bucket.static_files.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.static_files.id
    origin_id                = "S3-${aws_s3_bucket.static_files.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Distribution for ${var.project_name} static files"
  default_root_object = var.default_root_object

  # Configuration des logs
  dynamic "logging_config" {
    for_each = var.enable_cloudfront_logs ? [1] : []
    content {
      include_cookies = false
      bucket          = aws_s3_bucket.cloudfront_logs[0].bucket_domain_name
      prefix          = "cloudfront-logs/"
    }
  }

  # Aliases de domaine (optionnel)
  aliases = var.domain_aliases

  # Cache behavior par défaut
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_files.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = var.default_cache_ttl
    max_ttl                = var.max_cache_ttl

    compress = true
  }

  # Cache behavior spécifique pour les assets statiques
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_files.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 31536000  # 1 an
    default_ttl            = 31536000  # 1 an
    max_ttl                = 31536000  # 1 an
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Cache behavior pour les fichiers avec hash (immutables)
  ordered_cache_behavior {
    path_pattern     = "*.*.js"
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.static_files.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl                = 31536000  # 1 an
    default_ttl            = 31536000  # 1 an
    max_ttl                = 31536000  # 1 an
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  # Restrictions géographiques
  restrictions {
    geo_restriction {
      restriction_type = var.geo_restriction_type
      locations        = var.geo_restriction_locations
    }
  }

  # Configuration SSL
  viewer_certificate {
    cloudfront_default_certificate = var.ssl_certificate_arn == null
    acm_certificate_arn           = var.ssl_certificate_arn
    ssl_support_method            = var.ssl_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version      = var.ssl_certificate_arn != null ? "TLSv1.2_2021" : null
  }

  # Pages d'erreur personnalisées
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"  # Pour React Router
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"  # Pour React Router
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cloudfront"
    Environment = var.environment
  }
}

# Politique S3 pour CloudFront
resource "aws_s3_bucket_policy" "static_files" {
  bucket = aws_s3_bucket.static_files.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.static_files.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.static_files.arn
          }
        }
      }
    ]
  })
}

# =================================
# BUCKET POUR UPLOADS UTILISATEUR (optionnel)
# =================================

resource "aws_s3_bucket" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-user-uploads"

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-uploads"
    Environment = var.environment
    Purpose     = "user-uploads"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = aws_s3_bucket.user_uploads[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = aws_s3_bucket.user_uploads[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# CORS pour uploads depuis le frontend
resource "aws_s3_bucket_cors_configuration" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = aws_s3_bucket.user_uploads[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE"]
    allowed_origins = var.cors_allowed_origins
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}
