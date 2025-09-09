output "monitoring_namespace" {
  description = "Monitoring namespace name"
  value       = kubernetes_namespace.monitoring.metadata[0].name
}

output "prometheus_operator_status" {
  description = "Prometheus operator deployment status"
  value       = helm_release.prometheus_operator.status
}

output "loki_status" {
  description = "Loki deployment status"
  value       = helm_release.loki.status
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = "admin123"
  sensitive   = true
}
