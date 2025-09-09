# =================================
# S3 MODULE - STATIC ASSETS & FRONTEND
# =================================

# S3 Bucket pour les fichiers statiques du frontend
resource "aws_s3_bucket" "frontend_static" {
  bucket = "${var.project_name}-${var.environment}-frontend-static"

  tags = {
    Name        = "${var.project_name}-${var.environment}-frontend-static"
    Environment = var.environment
    Purpose     = "Frontend Static Assets"
  }
}

# Configuration du versioning
resource "aws_s3_bucket_versioning" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Configuration du chiffrement
resource "aws_s3_bucket_server_side_encryption_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Configuration des accès publics
resource "aws_s3_bucket_public_access_block" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# Policy pour permettre l'accès public en lecture
resource "aws_s3_bucket_policy" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id
  depends_on = [aws_s3_bucket_public_access_block.frontend_static]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend_static.arn}/*"
      }
    ]
  })
}

# Configuration du site web statique
resource "aws_s3_bucket_website_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

  # Règles de routage pour React Router
  routing_rule {
    condition {
      http_error_code_returned_equals = 404
    }
    redirect {
      replace_key_with = "index.html"
    }
  }
}

# Configuration CORS pour les appels API
resource "aws_s3_bucket_cors_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Configuration du lifecycle pour optimiser les coûts
resource "aws_s3_bucket_lifecycle_configuration" "frontend_static" {
  bucket = aws_s3_bucket.frontend_static.id

  rule {
    id     = "cleanup_old_versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    noncurrent_version_transition {
      noncurrent_days = 7
      storage_class   = "STANDARD_IA"
    }
  }

  rule {
    id     = "cleanup_incomplete_uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }
}

# S3 Bucket pour les logs ALB (optionnel)
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-alb-logs"

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-logs"
    Environment = var.environment
    Purpose     = "ALB Access Logs"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  rule {
    id     = "delete_old_logs"
    status = "Enabled"

    expiration {
      days = 90
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 60
      storage_class = "GLACIER"
    }
  }
}

# Policy pour permettre à ALB d'écrire les logs
resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_alb_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_elb_service_account" "main" {}

# S3 Bucket pour les uploads utilisateurs (optionnel)
resource "aws_s3_bucket" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-user-uploads"

  tags = {
    Name        = "${var.project_name}-${var.environment}-user-uploads"
    Environment = var.environment
    Purpose     = "User File Uploads"
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

resource "aws_s3_bucket_lifecycle_configuration" "user_uploads" {
  count  = var.enable_user_uploads ? 1 : 0
  bucket = aws_s3_bucket.user_uploads[0].id

  rule {
    id     = "cleanup_old_uploads"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }
  }
}
