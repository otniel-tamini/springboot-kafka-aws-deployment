#!/bin/bash

# =================================
# SCRIPT DE NETTOYAGE COMPLET AWS
# =================================

set -e

# Configuration
AWS_REGION="us-west-2"
PROJECT_NAME="springboot-microservices"
ENVIRONMENT="production"

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

# Fonction de nettoyage MSK
cleanup_msk() {
    log_info "Nettoyage des clusters MSK..."
    
    # Lister et supprimer tous les clusters MSK
    local clusters=$(aws kafka list-clusters --region $AWS_REGION --query 'ClusterInfoList[].ClusterArn' --output text)
    
    for cluster_arn in $clusters; do
        if [[ $cluster_arn == *"$PROJECT_NAME"* ]]; then
            log_info "Suppression du cluster MSK: $cluster_arn"
            aws kafka delete-cluster --cluster-arn "$cluster_arn" --region $AWS_REGION || true
        fi
    done
    
    # Attendre que les clusters soient supprimés
    log_info "Attente de la suppression des clusters MSK..."
    while true; do
        local remaining=$(aws kafka list-clusters --region $AWS_REGION --query 'ClusterInfoList[?contains(ClusterName, `'$PROJECT_NAME'`)].ClusterArn' --output text)
        if [[ -z "$remaining" ]]; then
            log_success "Tous les clusters MSK ont été supprimés"
            break
        fi
        log_info "Attente... Clusters restants trouvés"
        sleep 30
    done
}

# Fonction de nettoyage EKS
cleanup_eks() {
    log_info "Nettoyage des clusters EKS..."
    
    local clusters=$(aws eks list-clusters --region $AWS_REGION --query 'clusters[]' --output text)
    
    for cluster in $clusters; do
        if [[ $cluster == *"$PROJECT_NAME"* ]]; then
            log_info "Suppression du cluster EKS: $cluster"
            
            # Supprimer les node groups d'abord
            local nodegroups=$(aws eks list-nodegroups --cluster-name "$cluster" --region $AWS_REGION --query 'nodegroups[]' --output text)
            for ng in $nodegroups; do
                log_info "Suppression du node group: $ng"
                aws eks delete-nodegroup --cluster-name "$cluster" --nodegroup-name "$ng" --region $AWS_REGION || true
            done
            
            # Attendre que les node groups soient supprimés
            while true; do
                local remaining_ng=$(aws eks list-nodegroups --cluster-name "$cluster" --region $AWS_REGION --query 'nodegroups[]' --output text)
                if [[ -z "$remaining_ng" ]]; then
                    break
                fi
                log_info "Attente suppression node groups..."
                sleep 30
            done
            
            # Supprimer le cluster
            aws eks delete-cluster --name "$cluster" --region $AWS_REGION || true
        fi
    done
}

# Fonction de nettoyage RDS
cleanup_rds() {
    log_info "Nettoyage des instances RDS..."
    
    local instances=$(aws rds describe-db-instances --region $AWS_REGION --query 'DBInstances[].DBInstanceIdentifier' --output text)
    
    for instance in $instances; do
        if [[ $instance == *"$PROJECT_NAME"* ]]; then
            log_info "Suppression de l'instance RDS: $instance"
            aws rds delete-db-instance --db-instance-identifier "$instance" --skip-final-snapshot --region $AWS_REGION || true
        fi
    done
}

# Fonction de nettoyage ElastiCache
cleanup_elasticache() {
    log_info "Nettoyage des clusters ElastiCache..."
    
    local clusters=$(aws elasticache describe-cache-clusters --region $AWS_REGION --query 'CacheClusters[].CacheClusterId' --output text)
    
    for cluster in $clusters; do
        if [[ $cluster == *"$PROJECT_NAME"* ]]; then
            log_info "Suppression du cluster ElastiCache: $cluster"
            aws elasticache delete-cache-cluster --cache-cluster-id "$cluster" --region $AWS_REGION || true
        fi
    done
}

# Fonction de nettoyage des Security Groups
cleanup_security_groups() {
    log_info "Nettoyage des Security Groups..."
    
    local sgs=$(aws ec2 describe-security-groups --region $AWS_REGION --query 'SecurityGroups[?contains(GroupName, `'$PROJECT_NAME'`)].GroupId' --output text)
    
    for sg in $sgs; do
        log_info "Suppression du Security Group: $sg"
        aws ec2 delete-security-group --group-id "$sg" --region $AWS_REGION || true
    done
}

# Fonction de nettoyage des subnets
cleanup_subnets() {
    log_info "Nettoyage des subnets..."
    
    local subnets=$(aws ec2 describe-subnets --region $AWS_REGION --query 'Subnets[?contains(Tags[?Key==`Name`].Value | [0], `'$PROJECT_NAME'`)].SubnetId' --output text)
    
    for subnet in $subnets; do
        log_info "Suppression du subnet: $subnet"
        aws ec2 delete-subnet --subnet-id "$subnet" --region $AWS_REGION || true
    done
}

# Fonction de nettoyage VPC
cleanup_vpc() {
    log_info "Nettoyage des VPC..."
    
    local vpcs=$(aws ec2 describe-vpcs --region $AWS_REGION --query 'Vpcs[?contains(Tags[?Key==`Name`].Value | [0], `'$PROJECT_NAME'`)].VpcId' --output text)
    
    for vpc in $vpcs; do
        log_info "Nettoyage du VPC: $vpc"
        
        # Supprimer les IGW
        local igws=$(aws ec2 describe-internet-gateways --region $AWS_REGION --query 'InternetGateways[?Attachments[?VpcId==`'$vpc'`]].InternetGatewayId' --output text)
        for igw in $igws; do
            aws ec2 detach-internet-gateway --internet-gateway-id "$igw" --vpc-id "$vpc" --region $AWS_REGION || true
            aws ec2 delete-internet-gateway --internet-gateway-id "$igw" --region $AWS_REGION || true
        done
        
        # Supprimer les NAT Gateways
        local nats=$(aws ec2 describe-nat-gateways --region $AWS_REGION --query 'NatGateways[?VpcId==`'$vpc'`].NatGatewayId' --output text)
        for nat in $nats; do
            aws ec2 delete-nat-gateway --nat-gateway-id "$nat" --region $AWS_REGION || true
        done
        
        # Supprimer les route tables
        local rts=$(aws ec2 describe-route-tables --region $AWS_REGION --query 'RouteTables[?VpcId==`'$vpc'` && !Associations[?Main==`true`]].RouteTableId' --output text)
        for rt in $rts; do
            aws ec2 delete-route-table --route-table-id "$rt" --region $AWS_REGION || true
        done
        
        # Attendre et supprimer le VPC
        sleep 60
        aws ec2 delete-vpc --vpc-id "$vpc" --region $AWS_REGION || true
    done
}

# Fonction de nettoyage Terraform
cleanup_terraform_state() {
    log_info "Nettoyage de l'état Terraform..."
    
    cd /home/otniel/springboot-kafka-microservices/terraform/environments/eks-production
    
    # Supprimer le fichier d'état
    rm -f terraform.tfstate*
    rm -f .terraform.lock.hcl
    rm -rf .terraform/
    
    log_success "État Terraform nettoyé"
}

# Fonction principale
main() {
    echo "=========================================="
    echo "🧹 NETTOYAGE COMPLET AWS"
    echo "=========================================="
    echo "Projet: $PROJECT_NAME"
    echo "Environnement: $ENVIRONMENT"
    echo "Région: $AWS_REGION"
    echo "=========================================="
    echo
    
    log_warning "⚠️  Ce script va supprimer TOUTES les ressources AWS liées au projet!"
    echo
    read -p "Voulez-vous continuer? (oui/non): " confirm
    
    if [[ $confirm != "oui" ]]; then
        log_info "Nettoyage annulé."
        exit 0
    fi
    
    # Exécuter le nettoyage dans l'ordre
    cleanup_msk
    cleanup_eks
    cleanup_rds
    cleanup_elasticache
    
    # Attendre que les services soient supprimés
    log_info "Attente de la suppression des services..."
    sleep 120
    
    cleanup_security_groups
    cleanup_subnets
    cleanup_vpc
    cleanup_terraform_state
    
    log_success "🎉 Nettoyage complet terminé!"
    echo
    echo "Toutes les ressources AWS ont été supprimées."
    echo "Vous pouvez maintenant relancer un déploiement propre."
}

# Exécution
main "$@"
