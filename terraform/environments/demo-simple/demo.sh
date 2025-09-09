#!/bin/bash

# =================================
# DEMO AWS SIMPLE - 3H MAX
# =================================

set -e

echo "🎬 DÉMO AWS MICROSERVICES - Simple et Efficace"
echo "💰 Coût estimé: $0.50 pour 3h"
echo "⏰ Durée de déploiement: ~5 minutes"
echo "🖥️  Instance: t3.medium avec Docker"
echo "============================================="

# Timer de sécurité
DEMO_DURATION=10800  # 3 heures

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🧹 Nettoyage automatique..."
    terraform destroy -auto-approve
    echo "✅ Infrastructure détruite"
    echo "💰 Coût final: ~$0.50"
}

trap cleanup EXIT

# Check prerequisites
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI non configuré"
    exit 1
fi

echo "✅ Prérequis validés"

# Move to directory
cd "$(dirname "$0")"

# Initialize
echo "🔧 Initialisation Terraform..."
terraform init

# Validate
echo "✅ Validation..."
terraform validate

# Deploy
echo "🚀 Déploiement sur AWS..."
echo "⏱️  Démarrage à: $(date)"

terraform apply -auto-approve

DEPLOY_END=$(date)
echo "✅ Infrastructure déployée à: $DEPLOY_END"

# Get IP
INSTANCE_IP=$(terraform output -raw instance_public_ip)

echo ""
echo "🎉 MICROSERVICES PRÊTS SUR AWS !"
echo "================================"
echo "🌐 IP Public: $INSTANCE_IP"
echo ""

echo "⏳ Attente que les services démarrent (60 secondes)..."
sleep 60

echo ""
echo "🌐 URLs pour votre démo LinkedIn:"
echo "================================="
echo "✅ Dashboard Principal: http://$INSTANCE_IP"
echo "✅ Service Registry: http://$INSTANCE_IP:8761"
echo "✅ API Gateway: http://$INSTANCE_IP:9191"
echo "✅ Order Service: http://$INSTANCE_IP:8080"
echo "✅ Payment Service: http://$INSTANCE_IP:8085"
echo "✅ Product Service: http://$INSTANCE_IP:8084"
echo "✅ Email Service: http://$INSTANCE_IP:8086"
echo "✅ Identity Service: http://$INSTANCE_IP:9898"
echo "✅ Prometheus: http://$INSTANCE_IP:9090"
echo "✅ Grafana: http://$INSTANCE_IP:3000 (admin/admin)"

echo ""
echo "📸 Checklist LinkedIn PARFAITE:"
echo "==============================="
echo "✅ Screenshot dashboard principal"
echo "✅ Montrer Service Registry Eureka"
echo "✅ Tester les endpoints des services"
echo "✅ Montrer monitoring Prometheus"
echo "✅ Architecture Docker sur AWS"
echo "✅ Scalabilité cloud native"

echo ""
echo "🎯 POST LINKEDIN SUGGÉRÉ:"
echo "========================="
cat << EOF

🚀 Déploiement de microservices Spring Boot sur AWS !

✅ 7 microservices interconnectés
✅ Service Discovery avec Eureka
✅ API Gateway pour le routing
✅ Apache Kafka pour la communication asynchrone
✅ Redis pour le cache distribué
✅ MySQL pour la persistance
✅ Monitoring avec Prometheus & Grafana
✅ Déployé sur AWS avec Docker

🔧 Stack technique:
- Spring Boot 3.x + Spring Cloud
- Apache Kafka & Redis
- MySQL Database
- Docker & Docker Compose
- AWS EC2 Infrastructure
- Prometheus & Grafana

⚡ Déployé en 5 minutes avec Terraform !
💰 Coût: $0.50 pour cette démo de 3h
🌐 Architecture prête pour la production

#SpringBoot #Microservices #AWS #Docker #Kafka #Architecture #DevOps #CloudNative

EOF

echo ""
echo "⚠️  INFORMATIONS IMPORTANTES:"
echo "============================"
echo "🕐 Démo commencée à: $(date)"
echo "⏰ Fin automatique dans: 3 heures"
echo "💰 Coût par minute: ~$0.003"
echo "🧹 Destruction automatique programmée"

# Set up automatic cleanup
(
    sleep $DEMO_DURATION
    echo "⏰ 3 heures écoulées - Destruction automatique..."
    cleanup
) &

CLEANUP_PID=$!
echo "🛡️  Processus de nettoyage: PID $CLEANUP_PID"

echo ""
echo "🎯 DÉMO PRÊTE - AWS EC2 + Docker"
echo "💡 Pour arrêter: Ctrl+C ou attendre 3h"
echo "🔗 Tous les services accessibles via IP public"
echo ""

# Wait for user input or timeout
read -t $DEMO_DURATION -p "Appuyez sur Entrée pour arrêter la démo..." || true

echo ""
echo "🎬 FIN DE LA DÉMO"
cleanup
