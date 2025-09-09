#!/bin/bash

# =================================
# SCRIPT DE DÉPLOIEMENT EKS PRODUCTION
# =================================

set -e  # Arrêt en cas d'erreur

# Configuration
PROJECT_NAME="springboot-microservices"
ENVIRONMENT="production"
AWS_REGION="us-west-2"
TERRAFORM_DIR="/home/otniel/springboot-kafka-microservices/terraform/environments/eks-production"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction de logging
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

# Fonction de vérification des prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    # Vérifier AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI n'est pas installé. Veuillez l'installer."
        exit 1
    fi
    
    # Vérifier kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl n'est pas installé. Veuillez l'installer."
        exit 1
    fi
    
    # Vérifier Terraform
    if ! command -v terraform &> /dev/null; then
        log_error "Terraform n'est pas installé. Veuillez l'installer."
        exit 1
    fi
    
    # Vérifier helm
    if ! command -v helm &> /dev/null; then
        log_error "Helm n'est pas installé. Veuillez l'installer."
        exit 1
    fi
    
    # Vérifier les credentials AWS
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "Credentials AWS non configurés. Exécutez 'aws configure'."
        exit 1
    fi
    
    log_success "Tous les prérequis sont satisfaits."
}

# Fonction de création de la policy AWS Load Balancer Controller
create_alb_policy() {
    log_info "Création de la policy AWS Load Balancer Controller..."
    
    local policy_arn="arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):policy/AWSLoadBalancerControllerIAMPolicy"
    
    # Vérifier si la policy existe déjà
    if aws iam get-policy --policy-arn "$policy_arn" &> /dev/null; then
        log_warning "La policy AWS Load Balancer Controller existe déjà."
        return 0
    fi
    
    # Télécharger la policy
    curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json
    
    # Créer la policy
    aws iam create-policy \
        --policy-name AWSLoadBalancerControllerIAMPolicy \
        --policy-document file://iam_policy.json
    
    # Nettoyer
    rm -f iam_policy.json
    
    log_success "Policy AWS Load Balancer Controller créée."
}

# Fonction de déploiement Terraform
deploy_terraform() {
    log_info "Déploiement de l'infrastructure Terraform..."
    
    cd "$TERRAFORM_DIR"
    
    # Initialisation Terraform
    log_info "Initialisation Terraform..."
    terraform init
    
    # Validation
    log_info "Validation de la configuration Terraform..."
    terraform validate
    
    # Plan
    log_info "Génération du plan Terraform..."
    terraform plan -out=tfplan
    
    # Demander confirmation
    echo
    log_warning "ATTENTION: Ce déploiement coûtera environ 750$/mois."
    log_warning "Assurez-vous d'avoir les permissions et le budget nécessaires."
    echo
    read -p "Voulez-vous continuer avec le déploiement? (oui/non): " confirm
    
    if [[ $confirm != "oui" ]]; then
        log_info "Déploiement annulé par l'utilisateur."
        exit 0
    fi
    
    # Apply
    log_info "Application de la configuration Terraform..."
    terraform apply tfplan
    
    log_success "Infrastructure Terraform déployée avec succès!"
}

# Fonction de configuration de kubectl
configure_kubectl() {
    log_info "Configuration de kubectl..."
    
    local cluster_name="${PROJECT_NAME}-${ENVIRONMENT}"
    aws eks update-kubeconfig --region "$AWS_REGION" --name "$cluster_name"
    
    # Vérifier la connexion
    log_info "Vérification de la connexion au cluster..."
    kubectl cluster-info
    kubectl get nodes
    
    log_success "kubectl configuré avec succès!"
}

# Fonction d'attente de disponibilité des services
wait_for_services() {
    log_info "Attente de la disponibilité des services..."
    
    # Attendre que tous les nœuds soient prêts
    log_info "Attente des nœuds..."
    kubectl wait --for=condition=Ready nodes --all --timeout=600s
    
    # Attendre les deployments dans le namespace microservices
    log_info "Attente des microservices..."
    kubectl wait --for=condition=available --timeout=600s deployment --all -n microservices
    
    # Attendre les services de monitoring
    log_info "Attente des services de monitoring..."
    kubectl wait --for=condition=available --timeout=600s deployment --all -n monitoring
    
    log_success "Tous les services sont disponibles!"
}

# Fonction d'affichage des informations de connexion
display_access_info() {
    log_info "Récupération des informations d'accès..."
    
    echo
    echo "=========================================="
    echo "🚀 DÉPLOIEMENT EKS PRODUCTION TERMINÉ! 🚀"
    echo "=========================================="
    echo
    
    # Informations du cluster
    echo "📊 INFORMATIONS DU CLUSTER:"
    echo "Cluster: ${PROJECT_NAME}-${ENVIRONMENT}"
    echo "Région: $AWS_REGION"
    echo "Nœuds: $(kubectl get nodes --no-headers | wc -l)"
    echo
    
    # Endpoints des services
    echo "🌐 ENDPOINTS DES SERVICES:"
    
    # API Gateway
    local api_gateway_url=$(kubectl get ingress api-gateway-ingress -n microservices -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "En cours de configuration...")
    echo "API Gateway: http://$api_gateway_url"
    
    # Service Registry
    echo "Service Registry: kubectl port-forward -n microservices svc/service-registry 8761:8761"
    
    # Monitoring
    echo "Prometheus: kubectl port-forward -n monitoring svc/prometheus-server 9090:80"
    echo "Grafana: kubectl port-forward -n monitoring svc/grafana 3000:80"
    echo
    
    # Commandes utiles
    echo "🛠️ COMMANDES UTILES:"
    echo "kubectl get pods --all-namespaces"
    echo "kubectl logs -f deployment/api-gateway -n microservices"
    echo "kubectl top nodes"
    echo "kubectl top pods --all-namespaces"
    echo
    
    # Informations de coût
    echo "💰 COÛT ESTIMÉ:"
    echo "Mensuel: ~750 USD"
    echo "Journalier: ~25 USD"
    echo "Horaire: ~1 USD"
    echo
    
    # Commandes de nettoyage
    echo "🧹 POUR DÉTRUIRE L'INFRASTRUCTURE:"
    echo "cd $TERRAFORM_DIR"
    echo "terraform destroy"
    echo
    
    log_success "Déploiement EKS production terminé avec succès!"
}

# Fonction de nettoyage en cas d'erreur
cleanup_on_error() {
    log_error "Erreur détectée. Nettoyage en cours..."
    
    # Optionnel: détruire l'infrastructure en cas d'erreur
    # cd "$TERRAFORM_DIR"
    # terraform destroy -auto-approve
    
    exit 1
}

# Fonction principale
main() {
    echo "=========================================="
    echo "🚀 DÉPLOIEMENT EKS PRODUCTION"
    echo "=========================================="
    echo "Projet: $PROJECT_NAME"
    echo "Environnement: $ENVIRONMENT"
    echo "Région AWS: $AWS_REGION"
    echo "=========================================="
    echo
    
    # Trap pour gérer les erreurs
    trap cleanup_on_error ERR
    
    # Étapes du déploiement
    check_prerequisites
    create_alb_policy
    deploy_terraform
    configure_kubectl
    wait_for_services
    display_access_info
    
    log_success "🎉 Déploiement EKS production réussi!"
}

# Exécution du script principal
main "$@"
