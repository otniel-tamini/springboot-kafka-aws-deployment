output "namespace" {
  description = "Application namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "eureka_service_url" {
  description = "Eureka service URL"
  value       = "http://eureka-server:${var.microservices.service_registry.port}/eureka/"
}

output "api_gateway_service" {
  description = "API Gateway service name"
  value       = kubernetes_service.api_gateway.metadata[0].name
}

output "config_map_name" {
  description = "Application config map name"
  value       = kubernetes_config_map.app_config.metadata[0].name
}

output "secret_name" {
  description = "Database secrets name"
  value       = kubernetes_secret.db_passwords.metadata[0].name
}
