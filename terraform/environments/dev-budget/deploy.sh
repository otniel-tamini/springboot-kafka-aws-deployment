#!/bin/bash

# =================================
# DEPLOY DEV BUDGET ENVIRONMENT
# =================================

set -e

echo "🚀 Déploiement de l'environnement DEV Budget (~$200/mois)"
echo "============================================================"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS CLI n'est pas configuré. Exécutez 'aws configure' d'abord."
    exit 1
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform n'est pas installé."
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé."
    exit 1
fi

echo "✅ Prérequis validés"

# Move to the dev-budget directory
cd "$(dirname "$0")"

echo "📁 Répertoire actuel: $(pwd)"

# Initialize Terraform
echo "🔧 Initialisation de Terraform..."
terraform init

# Validate configuration
echo "✅ Validation de la configuration..."
terraform validate

# Show plan
echo "📋 Plan de déploiement:"
terraform plan -out=tfplan

# Ask for confirmation
echo ""
echo "⚠️  ATTENTION: Ce déploiement coûtera environ $200/mois"
echo "📊 Répartition estimée:"
echo "   - EKS Control Plane: $73/mois"
echo "   - EC2 SPOT instances: $15/mois"  
echo "   - RDS MySQL: $16/mois"
echo "   - ElastiCache Redis: $17/mois"
echo "   - MSK Kafka: $60/mois"
echo "   - Autres (Storage, LB, etc.): $31/mois"
echo ""

read -p "🤔 Voulez-vous continuer avec le déploiement? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
    echo "❌ Déploiement annulé"
    rm -f tfplan
    exit 1
fi

# Apply the plan
echo "🚀 Déploiement en cours..."
terraform apply tfplan

# Clean up plan file
rm -f tfplan

# Get outputs
echo ""
echo "📊 Informations de déploiement:"
terraform output

echo ""
echo "🎉 Déploiement terminé avec succès!"
echo ""

# Get cluster name and region for kubectl
CLUSTER_NAME=$(terraform output -raw cluster_name)
REGION=$(terraform output -json | jq -r '.vpc_id.value' | cut -d':' -f4)

echo "🔧 Configuration de kubectl..."
aws eks update-kubeconfig --region us-west-2 --name "$CLUSTER_NAME"

echo "✅ kubectl configuré pour le cluster $CLUSTER_NAME"

echo ""
echo "📋 Commandes utiles:"
echo "   kubectl get nodes                    # Vérifier les nœuds"
echo "   kubectl get pods -A                  # Vérifier tous les pods"
echo "   kubectl get svc -A                   # Vérifier les services"
echo ""

echo "📊 Surveiller les coûts:"
echo "   - Configurez des alertes de budget AWS"
echo "   - Surveillez l'utilisation avec 'kubectl top nodes'"
echo "   - Pensez à arrêter l'environnement quand inutilisé"
echo ""

echo "🎯 Environnement DEV prêt pour le développement!"
echo "💰 Coût estimé: ~$200/mois"
