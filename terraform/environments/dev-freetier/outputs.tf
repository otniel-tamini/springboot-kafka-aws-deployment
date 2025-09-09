output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.dev_app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.dev_app.public_dns
}

output "database_endpoint" {
  description = "RDS MySQL endpoint"
  value       = aws_db_instance.dev_mysql.endpoint
  sensitive   = true
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/aws-dev-key ec2-user@${aws_eip.dev_app.public_ip}"
}

output "service_urls" {
  description = "URLs for accessing the microservices"
  value = {
    dashboard        = "http://${aws_eip.dev_app.public_ip}/"
    service_registry = "http://${aws_eip.dev_app.public_ip}:8761"
    api_gateway     = "http://${aws_eip.dev_app.public_ip}:9191"
    order_service   = "http://${aws_eip.dev_app.public_ip}:8080"
    payment_service = "http://${aws_eip.dev_app.public_ip}:8085"
    product_service = "http://${aws_eip.dev_app.public_ip}:8084"
    email_service   = "http://${aws_eip.dev_app.public_ip}:8086"
    identity_service = "http://${aws_eip.dev_app.public_ip}:9898"
  }
}

output "cost_estimation" {
  description = "Estimated monthly cost breakdown"
  value = {
    ec2_instance     = "FREE (t2.micro within 750h/month)"
    rds_database     = "FREE (db.t3.micro within 750h/month)"
    elastic_ip       = "FREE (while attached to running instance)"
    data_transfer    = "FREE (first 1GB outbound/month)"
    vpc_networking   = "FREE"
    total_estimated  = "$0.00/month (within free tier limits)"
    warning         = "Monitor usage to stay within free tier limits"
  }
}
