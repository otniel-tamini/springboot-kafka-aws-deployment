resource "aws_eks_fargate_profile" "example" {
  cluster_name           = aws_eks_cluster.example.name
  fargate_profile_name   = "example-fargate-profile"
  pod_execution_role_arn = aws_iam_role.example.arn

  selector {
    namespace = "default"
  }

  pod_execution_role_arn = aws_iam_role.example.arn
}