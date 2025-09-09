#!/bin/bash

# =================================
# AUTOMATED DEPLOYMENT SCRIPT
# =================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="dev"
ACTION="deploy"
SKIP_BUILD=false
SKIP_INFRASTRUCTURE=false
AUTO_APPROVE=false

# Functions
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

show_help() {
    cat << EOF
SpringBoot Kafka Microservices - Automated Deployment Script

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -e, --environment ENV     Target environment (dev|prod) [default: dev]
    -a, --action ACTION       Action to perform (deploy|destroy|plan) [default: deploy]
    -b, --skip-build         Skip Docker image building
    -i, --skip-infrastructure Skip infrastructure deployment
    -y, --auto-approve       Auto approve Terraform changes
    -h, --help               Show this help message

EXAMPLES:
    # Deploy development environment
    $0 --environment dev

    # Deploy production with auto-approval
    $0 --environment prod --auto-approve

    # Plan infrastructure changes only
    $0 --action plan --skip-build --environment prod

    # Destroy development environment
    $0 --action destroy --environment dev

    # Deploy without rebuilding images
    $0 --skip-build --environment dev
EOF
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check required tools
    local tools=("terraform" "kubectl" "aws" "docker")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            log_error "$tool is required but not installed"
            exit 1
        fi
    done
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        log_error "AWS credentials not configured or invalid"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_success "All prerequisites met"
}

build_images() {
    if [ "$SKIP_BUILD" = true ]; then
        log_warning "Skipping Docker image build"
        return
    fi
    
    log_info "Building Docker images..."
    
    # Build JARs first
    if [ -f "./build-jars.sh" ]; then
        log_info "Building JAR files..."
        ./build-jars.sh
    else
        log_warning "build-jars.sh not found, assuming JARs are already built"
    fi
    
    # Build Docker images
    if [ -f "docker-compose-build.yml" ]; then
        log_info "Building Docker images with docker-compose..."
        docker-compose -f docker-compose-build.yml build
    else
        log_warning "docker-compose-build.yml not found, skipping Docker build"
    fi
    
    log_success "Docker images built successfully"
}

deploy_infrastructure() {
    if [ "$SKIP_INFRASTRUCTURE" = true ]; then
        log_warning "Skipping infrastructure deployment"
        return
    fi
    
    log_info "Deploying infrastructure for $ENVIRONMENT environment..."
    
    cd "terraform/environments/$ENVIRONMENT"
    
    # Initialize Terraform
    log_info "Initializing Terraform..."
    terraform init
    
    # Validate configuration
    log_info "Validating Terraform configuration..."
    terraform validate
    
    case $ACTION in
        "plan")
            log_info "Creating Terraform plan..."
            terraform plan -var-file=terraform.tfvars
            ;;
        "deploy")
            log_info "Applying Terraform configuration..."
            if [ "$AUTO_APPROVE" = true ]; then
                terraform apply -var-file=terraform.tfvars -auto-approve
            else
                terraform apply -var-file=terraform.tfvars
            fi
            log_success "Infrastructure deployed successfully"
            ;;
        "destroy")
            log_warning "Destroying infrastructure..."
            if [ "$AUTO_APPROVE" = true ]; then
                terraform destroy -var-file=terraform.tfvars -auto-approve
            else
                terraform destroy -var-file=terraform.tfvars
            fi
            log_success "Infrastructure destroyed successfully"
            ;;
    esac
    
    cd - > /dev/null
}

configure_kubernetes() {
    if [ "$ACTION" = "destroy" ]; then
        return
    fi
    
    log_info "Configuring kubectl for EKS cluster..."
    
    aws eks update-kubeconfig --region us-west-2 --name "springboot-kafka-microservices-$ENVIRONMENT-cluster"
    
    # Wait for cluster to be ready
    log_info "Waiting for cluster to be ready..."
    kubectl wait --for=condition=Ready nodes --all --timeout=300s
    
    log_success "Kubernetes configured successfully"
}

verify_deployment() {
    if [ "$ACTION" = "destroy" ]; then
        return
    fi
    
    log_info "Verifying deployment..."
    
    # Check nodes
    log_info "Checking cluster nodes..."
    kubectl get nodes
    
    # Check system pods
    log_info "Checking system pods..."
    kubectl get pods -n kube-system
    
    # Check application pods
    log_info "Checking application pods..."
    kubectl get pods -n default
    
    # Check services
    log_info "Checking services..."
    kubectl get services -n default
    
    log_success "Deployment verification completed"
}

show_access_info() {
    if [ "$ACTION" = "destroy" ]; then
        return
    fi
    
    log_info "Access Information:"
    echo ""
    echo "🌐 Kubernetes Dashboard:"
    echo "   kubectl proxy"
    echo "   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/"
    echo ""
    echo "📊 Monitoring Dashboards:"
    echo "   kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80"
    echo "   Grafana: http://localhost:3000 (admin/admin123)"
    echo ""
    echo "   kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090"
    echo "   Prometheus: http://localhost:9090"
    echo ""
    echo "🔍 Service Discovery:"
    echo "   kubectl port-forward svc/eureka-server 8761:8761"
    echo "   Eureka: http://localhost:8761"
    echo ""
    echo "🚀 API Gateway:"
    API_GATEWAY_LB=$(kubectl get svc api-gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
    echo "   External LB: $API_GATEWAY_LB:9191"
    echo ""
    echo "📝 Useful Commands:"
    echo "   kubectl get pods -A"
    echo "   kubectl logs -f deployment/order-service"
    echo "   kubectl describe pod <pod-name>"
}

cleanup() {
    log_info "Cleaning up temporary files..."
    # Add any cleanup tasks here
}

main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--environment)
                ENVIRONMENT="$2"
                shift 2
                ;;
            -a|--action)
                ACTION="$2"
                shift 2
                ;;
            -b|--skip-build)
                SKIP_BUILD=true
                shift
                ;;
            -i|--skip-infrastructure)
                SKIP_INFRASTRUCTURE=true
                shift
                ;;
            -y|--auto-approve)
                AUTO_APPROVE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Validate environment
    if [[ "$ENVIRONMENT" != "dev" && "$ENVIRONMENT" != "prod" ]]; then
        log_error "Invalid environment: $ENVIRONMENT. Must be 'dev' or 'prod'"
        exit 1
    fi
    
    # Validate action
    if [[ "$ACTION" != "deploy" && "$ACTION" != "destroy" && "$ACTION" != "plan" ]]; then
        log_error "Invalid action: $ACTION. Must be 'deploy', 'destroy', or 'plan'"
        exit 1
    fi
    
    log_info "Starting $ACTION for $ENVIRONMENT environment..."
    
    # Trap for cleanup
    trap cleanup EXIT
    
    # Execute deployment steps
    check_prerequisites
    
    if [ "$ACTION" = "deploy" ]; then
        build_images
    fi
    
    deploy_infrastructure
    
    if [ "$ACTION" = "deploy" ]; then
        configure_kubernetes
        verify_deployment
        show_access_info
    fi
    
    log_success "$ACTION completed successfully for $ENVIRONMENT environment!"
}

# Execute main function
main "$@"
