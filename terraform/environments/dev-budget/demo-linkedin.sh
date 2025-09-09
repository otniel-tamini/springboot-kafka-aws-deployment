#!/bin/bash

# =================================
# DEMO LINKEDIN - 3 HEURES MAX
# =================================

set -e

echo "🎬 Déploiement DEMO LinkedIn - 3 heures maximum"
echo "💰 Coût estimé: $1.20 pour 3h"
echo "⏰ Durée de déploiement: ~15 minutes"
echo "=============================================="

# Timer de sécurité
DEMO_DURATION=10800  # 3 heures en secondes

# Fonction de nettoyage automatique
cleanup() {
    echo ""
    echo "🧹 Nettoyage automatique déclenché..."
    terraform destroy -auto-approve
    echo "✅ Infrastructure détruite"
    echo "💰 Coût final: ~$1.20"
}

# Piège pour nettoyage en cas d'interruption
trap cleanup EXIT

# Check prerequisites
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI non configuré"
    exit 1
fi

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform non installé"
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

# Deploy with maximum parallelism for speed
echo "🚀 Déploiement rapide (parallélisme max)..."
echo "⏱️  Démarrage à: $(date)"

# Apply with auto-approve for demo
terraform apply -parallelism=20 -auto-approve

DEPLOY_END=$(date)
echo "✅ Déploiement terminé à: $DEPLOY_END"

# Configure kubectl
CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "springboot-kafka-dev")
aws eks update-kubeconfig --region us-west-2 --name "$CLUSTER_NAME"

echo ""
echo "🎉 INFRASTRUCTURE PRÊTE POUR DÉMO !"
echo "=================================="

# Wait for pods to be ready
echo "⏳ Attente que les pods soient prêts..."
kubectl wait --for=condition=ready pod --all --timeout=300s -A || true

echo ""
echo "📊 État de l'infrastructure:"
kubectl get nodes
echo ""
kubectl get pods -A
echo ""

# Get service URLs
echo "🌐 URLs des services pour démo:"
echo "================================"

# Try to get load balancer URLs
for service in service-registry api-gateway order-service payment-service product-service; do
    URL=$(kubectl get svc $service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    PORT=$(kubectl get svc $service -o jsonpath='{.spec.ports[0].port}' 2>/dev/null || echo "unknown")
    if [ "$URL" != "pending" ] && [ "$URL" != "" ]; then
        echo "✅ $service: http://$URL:$PORT"
    else
        echo "⏳ $service: URL en cours de génération..."
    fi
done

echo ""
echo "📋 Commandes utiles pour la démo:"
echo "================================="
echo "kubectl get pods -A              # Voir tous les pods"
echo "kubectl get svc -A               # Voir tous les services"
echo "kubectl top nodes                # Utilisation des nœuds"
echo "kubectl logs -f deployment/order-service  # Logs en temps réel"

echo ""
echo "📸 Checklist pour LinkedIn:"
echo "==========================="
echo "✅ Capture AWS Console EKS"
echo "✅ Screenshot kubectl get pods -A"
echo "✅ Service Registry dashboard"
echo "✅ Grafana monitoring (si déployé)"
echo "✅ Architecture diagram"

echo ""
echo "⚠️  IMPORTANT:"
echo "============="
echo "🕐 Démo commencée à: $(date)"
echo "⏰ Fin automatique dans: 3 heures"
echo "💰 Coût par minute: ~$0.007"
echo "🧹 Destruction automatique programmée"

# Set up automatic cleanup after 3 hours
(
    echo "⏰ Timer de 3h démarré..."
    sleep $DEMO_DURATION
    echo "⏰ 3 heures écoulées - Destruction automatique..."
    cleanup
) &

CLEANUP_PID=$!
echo "🛡️  Processus de nettoyage automatique: PID $CLEANUP_PID"

echo ""
echo "🎯 DÉMO PRÊTE - Durée maximale: 3h"
echo "💡 Pour arrêter manuellement: Ctrl+C ou 'terraform destroy'"
echo ""

# Keep script running to maintain the trap
echo "⏳ Appuyez sur Ctrl+C pour arrêter la démo et détruire l'infrastructure..."
echo "🔄 Ou laissez tourner - destruction automatique dans 3h"

# Wait for user input or timeout
read -t $DEMO_DURATION -p "Appuyez sur Entrée pour arrêter la démo maintenant..." || true

echo ""
echo "🎬 FIN DE LA DÉMO"
cleanup
