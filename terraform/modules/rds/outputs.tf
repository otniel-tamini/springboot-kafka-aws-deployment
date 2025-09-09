output "database_endpoints" {
  description = "RDS instance endpoints"
  value       = { for k, v in aws_db_instance.databases : k => v.endpoint }
}

output "database_ports" {
  description = "RDS instance ports"
  value       = { for k, v in aws_db_instance.databases : k => v.port }
}

output "database_identifiers" {
  description = "RDS instance identifiers"
  value       = { for k, v in aws_db_instance.databases : k => v.identifier }
}

output "security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "subnet_group_name" {
  description = "Database subnet group name"
  value       = aws_db_subnet_group.main.name
}
