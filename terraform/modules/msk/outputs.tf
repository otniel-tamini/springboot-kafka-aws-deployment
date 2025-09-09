output "cluster_arn" {
  description = "MSK cluster ARN"
  value       = aws_msk_cluster.main.arn
}

output "cluster_name" {
  description = "MSK cluster name"
  value       = aws_msk_cluster.main.cluster_name
}

output "bootstrap_brokers" {
  description = "MSK bootstrap brokers"
  value       = aws_msk_cluster.main.bootstrap_brokers
}

output "bootstrap_brokers_tls" {
  description = "MSK bootstrap brokers TLS"
  value       = aws_msk_cluster.main.bootstrap_brokers_tls
}

output "zookeeper_connect_string" {
  description = "MSK Zookeeper connection string"
  value       = aws_msk_cluster.main.zookeeper_connect_string
}

output "security_group_id" {
  description = "Security group ID for MSK"
  value       = aws_security_group.msk.id
}

output "configuration_arn" {
  description = "MSK configuration ARN"
  value       = aws_msk_configuration.main.arn
}

output "kms_key_id" {
  description = "KMS key ID for MSK encryption"
  value       = aws_kms_key.msk.key_id
}
