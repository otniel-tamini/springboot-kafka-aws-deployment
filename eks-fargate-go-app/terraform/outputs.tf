output "eks_cluster_endpoint" {
  value = aws_eks_cluster.my_cluster.endpoint
}

output "eks_cluster_name" {
  value = aws_eks_cluster.my_cluster.name
}

output "eks_cluster_version" {
  value = aws_eks_cluster.my_cluster.version
}

output "fargate_profile_name" {
  value = aws_eks_fargate_profile.my_fargate_profile.name
}

output "node_group_names" {
  value = aws_eks_node_group.my_node_group.*.name
}

output "vpc_id" {
  value = aws_vpc.my_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.my_subnet.*.id
}