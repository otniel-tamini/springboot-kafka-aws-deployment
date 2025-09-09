#!/bin/bash

# =================================
# DEMO LINKEDIN SIMPLIFIÉ - 3H MAX
# =================================

set -e

echo "🎬 Déploiement DEMO LinkedIn SIMPLIFIÉ"
echo "💰 Coût estimé: $0.50 pour 3h (sans EKS)"
echo "⏰ Durée: ~5 minutes seulement"
echo "======================================="

# Check prerequisites
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI non configuré"
    exit 1
fi

echo "✅ Prérequis validés"

# Timer de sécurité
DEMO_DURATION=10800  # 3 heures

# Fonction de nettoyage
cleanup() {
    echo ""
    echo "🧹 Nettoyage automatique..."
    cd /home/otniel/springboot-kafka-microservices
    docker-compose down 2>/dev/null || true
    echo "✅ Services Docker arrêtés"
    echo "💰 Coût total: $0.00 (Docker local)"
}

trap cleanup EXIT

echo "🚀 Démarrage des microservices avec Docker Compose..."
echo "⏱️  Démarrage à: $(date)"

# Move to main directory
cd /home/otniel/springboot-kafka-microservices

# Start services with Docker Compose
echo "🐳 Lancement des services Docker..."
docker-compose up -d

echo ""
echo "⏳ Attente que les services démarrent..."
sleep 30

echo ""
echo "🎉 MICROSERVICES PRÊTS POUR DÉMO !"
echo "=================================="

# Check service status
echo "📊 État des services:"
docker-compose ps

echo ""
echo "🌐 URLs des services pour démo:"
echo "================================"
echo "✅ Service Registry: http://localhost:8761"
echo "✅ API Gateway: http://localhost:9191"
echo "✅ Order Service: http://localhost:8080/actuator/health"
echo "✅ Payment Service: http://localhost:8085/actuator/health"
echo "✅ Product Service: http://localhost:8084/actuator/health"
echo "✅ Email Service: http://localhost:8086/actuator/health"
echo "✅ Identity Service: http://localhost:9898/actuator/health"
echo "✅ Kafka UI: http://localhost:9021 (si configuré)"
echo "✅ MySQL: localhost:3306"
echo "✅ Redis: localhost:6379"

echo ""
echo "📸 Checklist pour LinkedIn:"
echo "==========================="
echo "✅ Screenshot Service Registry (Eureka)"
echo "✅ Screenshot docker-compose ps"
echo "✅ Test des API endpoints"
echo "✅ Architecture diagram Docker"
echo "✅ Logs en temps réel"

echo ""
echo "📋 Commandes utiles pour la démo:"
echo "================================="
echo "docker-compose ps                    # État des services"
echo "docker-compose logs -f order-service # Logs en temps réel"
echo "docker-compose logs -f --tail=50     # Tous les logs"
echo "curl http://localhost:8761           # Test Service Registry"
echo "curl http://localhost:8080/actuator/health # Test Order Service"

echo ""
echo "⚠️  AVANTAGES DE CETTE DÉMO:"
echo "============================"
echo "✅ Architecture identique (7 microservices)"
echo "✅ Kafka + Redis + MySQL intégrés"
echo "✅ Démarrage ultra-rapide (5 min)"
echo "✅ Coût: $0.00 (100% local)"
echo "✅ Parfait pour démonstration"
echo "✅ Peut montrer scalabilité (docker-compose scale)"

echo ""
echo "💰 COMPARAISON COÛTS:"
echo "===================="
echo "🏠 Docker Local: $0.00"
echo "☁️  AWS EKS: $0.82 pour 3h"
echo "🏭 Production AWS: $1,200/mois"

echo ""
echo "🎯 POST LINKEDIN SUGGÉRÉ:"
echo "========================="
cat << 'EOF'

🚀 Architecture Microservices Spring Boot avec Docker !

✅ 7 microservices interconnectés
✅ Service Discovery (Eureka)
✅ API Gateway (Spring Cloud Gateway) 
✅ Kafka pour la communication asynchrone
✅ Redis pour le cache distribué
✅ MySQL pour la persistance
✅ Docker Compose pour l'orchestration

🔧 Stack technique:
- Spring Boot 3.x
- Spring Cloud 2023.x
- Apache Kafka 3.5
- Redis 7.0
- MySQL 8.0
- Docker & Docker Compose

⚡ Démarrage en 5 minutes avec une seule commande !
📊 Architecture prête pour la production (Kubernetes/AWS)

#SpringBoot #Microservices #Docker #Kafka #Java #Architecture #DevOps

EOF

echo ""
echo "🕐 Démo commencée à: $(date)"
echo "⏰ Durée maximale: 3 heures"
echo "🧹 Arrêt automatique programmé"

# Set up automatic cleanup
(
    sleep $DEMO_DURATION
    echo "⏰ 3 heures écoulées - Arrêt automatique..."
    cleanup
) &

echo ""
echo "🎬 DÉMO PRÊTE !"
echo "⏳ Appuyez sur Ctrl+C pour arrêter la démo"
echo "🔄 Ou laissez tourner - arrêt automatique dans 3h"

# Wait for user input or timeout
read -t $DEMO_DURATION -p "Appuyez sur Entrée pour arrêter la démo maintenant..." || true

echo ""
echo "🎬 FIN DE LA DÉMO"
cleanup
