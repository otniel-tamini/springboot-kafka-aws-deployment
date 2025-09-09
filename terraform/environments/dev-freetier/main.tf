# =================================
# DEV FREE TIER CONFIGURATION
# =================================
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# =================================
# PROVIDER CONFIGURATION
# =================================
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev-freetier"
      ManagedBy   = "terraform"
      CostCenter  = "development"
    }
  }
}

# =================================
# DATA SOURCES
# =================================
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# =================================
# VPC CONFIGURATION (FREE)
# =================================
resource "aws_vpc" "dev_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-dev-vpc"
  }
}

resource "aws_internet_gateway" "dev_igw" {
  vpc_id = aws_vpc.dev_vpc.id

  tags = {
    Name = "${var.project_name}-dev-igw"
  }
}

resource "aws_subnet" "dev_public" {
  vpc_id                  = aws_vpc.dev_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-dev-public"
  }
}

resource "aws_subnet" "dev_private" {
  vpc_id            = aws_vpc.dev_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-dev-private"
  }
}

resource "aws_route_table" "dev_public" {
  vpc_id = aws_vpc.dev_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_igw.id
  }

  tags = {
    Name = "${var.project_name}-dev-public-rt"
  }
}

resource "aws_route_table_association" "dev_public" {
  subnet_id      = aws_subnet.dev_public.id
  route_table_id = aws_route_table.dev_public.id
}

# =================================
# SECURITY GROUPS
# =================================
resource "aws_security_group" "dev_app" {
  name_description = "${var.project_name}-dev-app"
  vpc_id          = aws_vpc.dev_vpc.id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access for applications
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application ports
  ingress {
    from_port   = 8080
    to_port     = 9191
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Kafka port
  ingress {
    from_port   = 9092
    to_port     = 9092
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Redis port
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # MySQL port
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-dev-app-sg"
  }
}

resource "aws_security_group" "dev_rds" {
  name_description = "${var.project_name}-dev-rds"
  vpc_id          = aws_vpc.dev_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.dev_app.id]
  }

  tags = {
    Name = "${var.project_name}-dev-rds-sg"
  }
}

# =================================
# RDS SUBNET GROUP
# =================================
resource "aws_db_subnet_group" "dev_rds" {
  name       = "${var.project_name}-dev-rds-subnet-group"
  subnet_ids = [aws_subnet.dev_public.id, aws_subnet.dev_private.id]

  tags = {
    Name = "${var.project_name}-dev-rds-subnet-group"
  }
}

# =================================
# RDS DATABASE (FREE TIER)
# =================================
resource "aws_db_instance" "dev_mysql" {
  identifier = "${var.project_name}-dev-mysql"

  # FREE TIER CONFIGURATION
  allocated_storage     = 20  # Max free tier
  max_allocated_storage = 20  # Prevent auto-scaling
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"  # FREE TIER

  # Database configuration
  db_name  = "main_db"
  username = "root"
  password = var.db_password

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.dev_rds.name
  vpc_security_group_ids = [aws_security_group.dev_rds.id]
  publicly_accessible    = false

  # Backup configuration (minimal for dev)
  backup_retention_period = 0  # No backups for dev
  skip_final_snapshot     = true

  tags = {
    Name = "${var.project_name}-dev-mysql"
  }
}

# =================================
# EC2 INSTANCE (FREE TIER)
# =================================
resource "aws_key_pair" "dev_key" {
  key_name   = "${var.project_name}-dev-key"
  public_key = var.ssh_public_key
}

resource "aws_instance" "dev_app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"  # FREE TIER
  key_name      = aws_key_pair.dev_key.key_name

  vpc_security_group_ids = [aws_security_group.dev_app.id]
  subnet_id              = aws_subnet.dev_public.id

  # User data to install Docker and Docker Compose
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    db_host     = aws_db_instance.dev_mysql.endpoint
    db_password = var.db_password
  }))

  tags = {
    Name = "${var.project_name}-dev-app"
  }
}

# =================================
# ELASTIC IP (FREE TIER - 1 IP)
# =================================
resource "aws_eip" "dev_app" {
  instance = aws_instance.dev_app.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-dev-app-eip"
  }
}
