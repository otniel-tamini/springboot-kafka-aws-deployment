#!/bin/bash

# =================================
# SCRIPT DE DESTRUCTION EKS PRODUCTION
# =================================

set -e

# Configuration
PROJECT_NAME="springboot-microservices"
ENVIRONMENT="production"
AWS_REGION="us-west-2"
TERRAFORM_DIR="/home/otniel/springboot-kafka-microservices/terraform/environments/eks-production"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Fonction de destruction
destroy_infrastructure() {
    log_warning "⚠️  DESTRUCTION DE L'INFRASTRUCTURE EKS ⚠️"
    echo
    log_warning "Cette action va supprimer TOUTE l'infrastructure:"
    log_warning "- Cluster EKS et tous les nœuds"
    log_warning "- Bases de données RDS (avec leurs données)"
    log_warning "- Cluster Redis ElastiCache"
    log_warning "- Cluster Kafka MSK"
    log_warning "- VPC et tous les composants réseau"
    log_warning "- Tous les microservices et leurs données"
    echo
    log_error "⚠️  CETTE ACTION EST IRRÉVERSIBLE! ⚠️"
    echo
    
    read -p "Tapez 'DÉTRUIRE' pour confirmer la destruction: " confirm
    
    if [[ $confirm != "DÉTRUIRE" ]]; then
        log_info "Destruction annulée."
        exit 0
    fi
    
    log_info "Destruction en cours..."
    
    cd "$TERRAFORM_DIR"
    
    # Destruction Terraform
    terraform destroy -auto-approve
    
    log_success "Infrastructure détruite avec succès!"
}

# Fonction principale
main() {
    echo "=========================================="
    echo "🗑️  DESTRUCTION EKS PRODUCTION"
    echo "=========================================="
    echo "Projet: $PROJECT_NAME"
    echo "Environnement: $ENVIRONMENT"
    echo "=========================================="
    echo
    
    destroy_infrastructure
    
    log_success "🎉 Destruction terminée!"
}

main "$@"
