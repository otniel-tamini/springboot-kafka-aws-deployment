output "instance_public_ip" {
  description = "Public IP de l'instance"
  value       = aws_eip.demo.public_ip
}

output "dashboard_url" {
  description = "URL du dashboard principal"
  value       = "http://${aws_eip.demo.public_ip}"
}

output "service_urls" {
  description = "URLs de tous les services"
  value = {
    dashboard        = "http://${aws_eip.demo.public_ip}"
    service_registry = "http://${aws_eip.demo.public_ip}:8761"
    api_gateway     = "http://${aws_eip.demo.public_ip}:9191"
    order_service   = "http://${aws_eip.demo.public_ip}:8080"
    payment_service = "http://${aws_eip.demo.public_ip}:8085"
    product_service = "http://${aws_eip.demo.public_ip}:8084"
    email_service   = "http://${aws_eip.demo.public_ip}:8086"
    identity_service = "http://${aws_eip.demo.public_ip}:9898"
    prometheus      = "http://${aws_eip.demo.public_ip}:9090"
    grafana         = "http://${aws_eip.demo.public_ip}:3000"
  }
}

output "ssh_command" {
  description = "Commande SSH pour se connecter"
  value       = var.ssh_public_key != "" ? "ssh -i ~/.ssh/demo-key ec2-user@${aws_eip.demo.public_ip}" : "SSH key not configured"
}

output "cost_info" {
  description = "Information sur les coûts"
  value = {
    instance_type    = "t3.medium"
    hourly_cost     = "$0.0416/hour"
    cost_3h         = "$0.125"
    daily_cost      = "$1.00"
    monthly_cost    = "$30.00"
    demo_cost       = "~$0.50 pour 3h avec Docker"
  }
}

output "demo_checklist" {
  description = "Checklist pour la démo LinkedIn"
  value = [
    "✅ Accéder au dashboard principal",
    "✅ Montrer Service Registry (Eureka)",
    "✅ Tester chaque microservice",
    "✅ Montrer Prometheus monitoring", 
    "✅ Montrer Grafana dashboards",
    "✅ Screenshot architecture Docker",
    "✅ Expliquer scalabilité AWS"
  ]
}
