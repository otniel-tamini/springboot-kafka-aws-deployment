# =================================
# CONFIGURATION DEMO AWS SIMPLIFIÉE
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

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "demo"
      ManagedBy   = "terraform"
      Budget      = "1-dollar-demo"
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
# VPC CONFIGURATION SIMPLE
# =================================
resource "aws_vpc" "demo" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-demo-vpc"
  }
}

resource "aws_internet_gateway" "demo" {
  vpc_id = aws_vpc.demo.id

  tags = {
    Name = "${var.project_name}-demo-igw"
  }
}

resource "aws_subnet" "demo_public" {
  vpc_id                  = aws_vpc.demo.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-demo-public-subnet"
  }
}

resource "aws_route_table" "demo_public" {
  vpc_id = aws_vpc.demo.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo.id
  }

  tags = {
    Name = "${var.project_name}-demo-public-rt"
  }
}

resource "aws_route_table_association" "demo_public" {
  subnet_id      = aws_subnet.demo_public.id
  route_table_id = aws_route_table.demo_public.id
}

# =================================
# SECURITY GROUP
# =================================
resource "aws_security_group" "demo" {
  name_prefix = "${var.project_name}-demo-"
  vpc_id      = aws_vpc.demo.id

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Spring Boot services
  ingress {
    from_port   = 8080
    to_port     = 9898
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # All outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-demo-sg"
  }
}

# =================================
# KEY PAIR
# =================================
resource "aws_key_pair" "demo" {
  count      = var.ssh_public_key != "" ? 1 : 0
  key_name   = "${var.project_name}-demo-key"
  public_key = var.ssh_public_key
}

# =================================
# EC2 INSTANCE
# =================================
resource "aws_instance" "demo" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.medium"  # Plus puissant pour faire tourner tous les services
  key_name      = var.ssh_public_key != "" ? aws_key_pair.demo[0].key_name : null

  vpc_security_group_ids = [aws_security_group.demo.id]
  subnet_id              = aws_subnet.demo_public.id

  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
  }

  user_data = base64encode(templatefile("${path.module}/user_data_simple.sh", {
    project_name = var.project_name
  }))

  tags = {
    Name = "${var.project_name}-demo-instance"
    Type = "microservices-demo"
  }
}

# =================================
# ELASTIC IP
# =================================
resource "aws_eip" "demo" {
  instance = aws_instance.demo.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-demo-eip"
  }
}
