#!/bin/bash

# =================================
# SCRIPT DE DÉPLOIEMENT ANSIBLE
# =================================

set -e

echo "🚀 DÉPLOIEMENT SPRINGBOOT KAFKA MICROSERVICES"
echo "=============================================="

# Configuration
ENVIRONMENT=${1:-production}
NAMESPACE=${2:-microservices}
ACTION=${3:-all}

echo "📋 Configuration:"
echo "├── Environnement: $ENVIRONMENT"
echo "├── Namespace: $NAMESPACE"
echo "└── Action: $ACTION"

# Vérifications préalables
echo ""
echo "🔍 Vérifications préalables..."

# Vérifier kubectl
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl n'est pas installé"
    exit 1
fi

# Vérifier la connexion au cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Impossible de se connecter au cluster Kubernetes"
    echo "💡 Vérifiez votre configuration kubeconfig"
    exit 1
fi

# Vérifier ansible
if ! command -v ansible-playbook &> /dev/null; then
    echo "❌ ansible-playbook n'est pas installé"
    exit 1
fi

# Vérifier les collections Ansible
echo "📦 Vérification des collections Ansible..."
ansible-galaxy collection install kubernetes.core --force-with-deps
ansible-galaxy collection install cloud.common --force-with-deps

echo "✅ Vérifications terminées"

# Déploiement selon l'action
echo ""
echo "🚀 Démarrage du déploiement..."

case $ACTION in
    "infrastructure")
        echo "🗄️ Déploiement de l'infrastructure uniquement..."
        ansible-playbook -i inventory/hosts.yml \
            --extra-vars "environment=$ENVIRONMENT k8s_namespace=$NAMESPACE" \
            deploy-infrastructure.yml
        ;;
    "microservices")
        echo "📦 Déploiement des microservices uniquement..."
        ansible-playbook -i inventory/hosts.yml \
            --extra-vars "environment=$ENVIRONMENT k8s_namespace=$NAMESPACE" \
            deploy-microservices.yml
        ;;
    "ingress")
        echo "🌐 Configuration du load balancing et exposition externe..."
        ansible-playbook -i inventory/hosts.yml \
            --extra-vars "environment=$ENVIRONMENT k8s_namespace=$NAMESPACE" \
            deploy-ingress.yml
        ;;
    "all")
        echo "🎯 Déploiement complet (infrastructure + microservices + ingress)..."
        ansible-playbook -i inventory/hosts.yml \
            --extra-vars "environment=$ENVIRONMENT k8s_namespace=$NAMESPACE" \
            deploy-all.yml
        ;;
    "health")
        echo "🏥 Vérification de santé des services..."
        ansible-playbook -i inventory/hosts.yml \
            --extra-vars "environment=$ENVIRONMENT k8s_namespace=$NAMESPACE" \
            deploy-microservices.yml --tags health
        ;;
    *)
        echo "❌ Action non reconnue: $ACTION"
        echo "💡 Actions disponibles: infrastructure, microservices, ingress, all, health"
        exit 1
        ;;
esac

echo ""
echo "🎉 Déploiement terminé !"
echo ""
echo "📍 Prochaines étapes:"
echo "├── Vérifier les pods: kubectl get pods -n $NAMESPACE"
echo "├── Vérifier les services: kubectl get svc -n $NAMESPACE"
echo "├── Port-forward API Gateway: kubectl port-forward -n $NAMESPACE svc/api-gateway 8080:8080"
echo "└── Port-forward Grafana: kubectl port-forward -n infrastructure svc/monitoring-stack-grafana 3000:3000"
