provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

resource "aws_subnet" "subnet_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_a_cidr
  availability_zone = var.az_a
}

resource "aws_subnet" "subnet_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.subnet_b_cidr
  availability_zone = var.az_b
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_policy]
}

resource "aws_eks_fargate_profile" "main" {
  cluster_name = aws_eks_cluster.main.name
  fargate_profile_name = "${var.cluster_name}-fargate"
  pod_execution_role_arn = aws_iam_role.fargate_role.arn

  selector {
    namespace = "default"
  }

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = [aws_subnet.subnet_a.id, aws_subnet.subnet_b.id]

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  depends_on = [aws_eks_cluster.main]
}

module "monitoring" {
  source = "./monitoring"
}

output "cluster_endpoint" {
  value = aws_eks_cluster.main.endpoint
}

output "cluster_name" {
  value = aws_eks_cluster.main.name
}