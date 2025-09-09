output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = module.eks.cluster_endpoint
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "database_endpoint" {
  description = "RDS MySQL endpoint"
  value       = try(module.rds.database_endpoints.shared_db, "pending")
  sensitive   = true
}

output "redis_endpoint" {
  description = "ElastiCache Redis endpoint"
  value       = module.elasticache.redis_endpoint
}

output "kafka_bootstrap_brokers" {
  description = "MSK Kafka bootstrap brokers"
  value       = module.msk.bootstrap_brokers
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "kubectl_config" {
  description = "kubectl config command"
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}

# =================================
# COST BREAKDOWN ESTIMATION
# =================================
output "monthly_cost_breakdown" {
  description = "Estimation détaillée des coûts mensuels"
  value = {
    # EKS Control Plane
    eks_control_plane = {
      service = "EKS Control Plane"
      cost    = "$73.00"
      details = "$0.10/hour * 24h * 30 days"
    }
    
    # EC2 Node Groups (SPOT)
    ec2_nodes = {
      service = "EC2 SPOT t3.small nodes"
      cost    = "$15.00"
      details = "2 nodes * t3.small SPOT (~$0.0104/hour) * 24h * 30 days"
    }
    
    # RDS Database
    rds_database = {
      service = "RDS db.t3.micro"
      cost    = "$16.00"
      details = "db.t3.micro * 24h * 30 days + 20GB storage"
    }
    
    # ElastiCache Redis
    elasticache = {
      service = "ElastiCache cache.t3.micro"
      cost    = "$17.00"
      details = "cache.t3.micro * 24h * 30 days"
    }
    
    # MSK Kafka
    msk_kafka = {
      service = "MSK kafka.t3.small (2 brokers)"
      cost    = "$60.00"
      details = "2 brokers * kafka.t3.small * 24h * 30 days"
    }
    
    # EBS Storage
    ebs_storage = {
      service = "EBS Storage"
      cost    = "$8.00"
      details = "Node disks (40GB) + Kafka storage (100GB)"
    }
    
    # Data Transfer
    data_transfer = {
      service = "Data Transfer"
      cost    = "$5.00"
      details = "Inter-AZ transfer + Internet egress"
    }
    
    # Load Balancer (ALB)
    load_balancer = {
      service = "Application Load Balancer"
      cost    = "$18.00"
      details = "ALB for ingress (~$0.025/hour + LCU charges)"
    }
    
    total_estimated = "$212.00/month"
    optimization_note = "Utilisation SPOT instances pour économiser ~70% sur EC2"
    
    # Comparaison avec production
    production_equivalent = "$1,200-1,500/month"
    savings = "Économie de ~85% vs production"
  }
}

output "cost_optimization_tips" {
  description = "Conseils pour optimiser les coûts"
  value = {
    current_optimizations = [
      "✅ SPOT instances pour économiser 70% sur EC2",
      "✅ Instance sizes minimales (t3.small, t3.micro)",
      "✅ 2 nœuds Kafka au lieu de 3",
      "✅ Base de données partagée au lieu de 4 séparées",
      "✅ Pas de NAT Gateway ($45/mois économisés)",
      "✅ Pas de multi-AZ pour dev",
      "✅ Monitoring basique seulement"
    ]
    
    additional_savings = [
      "🔄 Arrêter l'environnement la nuit/weekend (-40%)",
      "📊 Utiliser CloudWatch pour surveiller l'utilisation",
      "🚀 Migrer vers Fargate Spot si possible",
      "💾 Optimiser les tailles de stockage EBS"
    ]
    
    budget_alert = "Configurer des alertes de budget AWS à $250"
  }
}

output "quick_commands" {
  description = "Commandes utiles pour la gestion"
  value = {
    connect_cluster = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
    check_pods     = "kubectl get pods -A"
    check_costs    = "aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost"
    scale_down     = "kubectl scale deployment --replicas=0 --all -n default"
    scale_up       = "kubectl scale deployment --replicas=1 --all -n default"
  }
}
