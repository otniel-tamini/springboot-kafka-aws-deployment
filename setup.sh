#!/bin/bash

# =================================
# INITIALIZATION SCRIPT
# =================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

# Welcome message
cat << "EOF"
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🚀 SpringBoot Kafka Microservices - Infrastructure Setup                  ║
║                                                                              ║
║   This script will help you set up the complete infrastructure for          ║
║   your microservices application on AWS EKS.                                ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

echo ""

# Check if we're in the right directory
if [ ! -f "terraform/main.tf" ]; then
    log_error "This script must be run from the project root directory"
    log_info "Please navigate to the springboot-kafka-microservices directory"
    exit 1
fi

log_info "Checking prerequisites..."

# Check required tools
check_tool() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 is installed"
        return 0
    else
        log_error "$1 is not installed"
        return 1
    fi
}

# Check all tools
tools_ok=true
if ! check_tool "terraform"; then
    echo "  Install: https://learn.hashicorp.com/tutorials/terraform/install-cli"
    tools_ok=false
fi

if ! check_tool "aws"; then
    echo "  Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    tools_ok=false
fi

if ! check_tool "kubectl"; then
    echo "  Install: https://kubernetes.io/docs/tasks/tools/"
    tools_ok=false
fi

if ! check_tool "docker"; then
    echo "  Install: https://docs.docker.com/get-docker/"
    tools_ok=false
fi

if [ "$tools_ok" = false ]; then
    log_error "Please install the missing tools and run this script again"
    exit 1
fi

# Check AWS credentials
log_info "Checking AWS credentials..."
if aws sts get-caller-identity &> /dev/null; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    AWS_REGION=$(aws configure get region)
    AWS_USER=$(aws sts get-caller-identity --query Arn --output text)
    
    log_success "AWS credentials are configured"
    echo "  Account: $AWS_ACCOUNT"
    echo "  Region: ${AWS_REGION:-us-west-2 (default)}"
    echo "  User: $AWS_USER"
else
    log_error "AWS credentials are not configured"
    log_info "Please run: aws configure"
    exit 1
fi

# Check Docker daemon
log_info "Checking Docker..."
if docker info &> /dev/null; then
    log_success "Docker is running"
else
    log_error "Docker daemon is not running"
    log_info "Please start Docker and run this script again"
    exit 1
fi

echo ""
log_info "Environment Setup Options:"
echo ""
echo "1. 🧪 Development Environment (Recommended for testing)"
echo "   - Smaller instances (t3.medium)"
echo "   - Single AZ deployment"
echo "   - Cost: ~$150-200/month"
echo ""
echo "2. 🏭 Production Environment"
echo "   - Larger instances (t3.large+)"
echo "   - Multi-AZ deployment"
echo "   - High availability"
echo "   - Cost: ~$800-1200/month"
echo ""

read -p "Which environment would you like to deploy? (1/2): " env_choice

case $env_choice in
    1)
        ENVIRONMENT="dev"
        log_info "Selected: Development Environment"
        ;;
    2)
        ENVIRONMENT="prod"
        log_warning "Selected: Production Environment"
        log_warning "This will incur significant AWS costs!"
        read -p "Are you sure you want to continue? (y/N): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log_info "Deployment cancelled"
            exit 0
        fi
        ;;
    *)
        log_error "Invalid choice. Please select 1 or 2"
        exit 1
        ;;
esac

echo ""
log_info "Pre-deployment Checklist:"
echo ""
echo "✅ Prerequisites checked"
echo "✅ AWS credentials configured"
echo "✅ Docker daemon running"
echo "✅ Environment selected: $ENVIRONMENT"
echo ""

read -p "🚀 Ready to deploy? This will create AWS resources that will incur costs. (y/N): " deploy_confirm

if [[ ! $deploy_confirm =~ ^[Yy]$ ]]; then
    log_info "Deployment cancelled"
    exit 0
fi

echo ""
log_info "Starting deployment process..."

# Step 1: Build Docker images
log_info "Step 1: Building Docker images..."
if [ -f "build-jars.sh" ]; then
    log_info "Building JAR files..."
    chmod +x build-jars.sh
    ./build-jars.sh
else
    log_warning "build-jars.sh not found, assuming JARs are already built"
fi

if [ -f "docker-compose-build.yml" ]; then
    log_info "Building Docker images..."
    docker-compose -f docker-compose-build.yml build
else
    log_warning "docker-compose-build.yml not found, skipping Docker build"
fi

# Step 2: Initialize Terraform
log_info "Step 2: Initializing Terraform..."
cd "terraform/environments/$ENVIRONMENT"
terraform init

# Step 3: Plan deployment
log_info "Step 3: Creating deployment plan..."
terraform plan -var-file=terraform.tfvars -out=tfplan

echo ""
log_warning "⚠️  IMPORTANT: Review the Terraform plan above"
log_warning "This plan shows all the AWS resources that will be created."
echo ""
read -p "Do you want to proceed with the deployment? (y/N): " proceed_confirm

if [[ ! $proceed_confirm =~ ^[Yy]$ ]]; then
    log_info "Deployment cancelled"
    cd ../../..
    exit 0
fi

# Step 4: Apply deployment
log_info "Step 4: Applying deployment (this may take 15-20 minutes)..."
terraform apply tfplan

# Step 5: Configure kubectl
log_info "Step 5: Configuring kubectl..."
cd ../../..
aws eks update-kubeconfig --region ${AWS_REGION:-us-west-2} --name "springboot-kafka-microservices-$ENVIRONMENT-cluster"

# Step 6: Wait for cluster to be ready
log_info "Step 6: Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=600s

# Step 7: Verify deployment
log_info "Step 7: Verifying deployment..."
echo ""
log_info "Cluster Nodes:"
kubectl get nodes

echo ""
log_info "System Pods:"
kubectl get pods -n kube-system

echo ""
log_info "Application Pods:"
kubectl get pods -n default

echo ""
log_info "Services:"
kubectl get services -A

echo ""
log_success "🎉 Deployment completed successfully!"
echo ""

# Show access information
cat << EOF
📊 Access Information:

🌐 Kubernetes Dashboard:
   kubectl proxy
   http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

📈 Monitoring Dashboards:
   # Grafana (username: admin, password: admin123)
   kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80
   http://localhost:3000

   # Prometheus
   kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090
   http://localhost:9090

🔍 Service Discovery:
   kubectl port-forward svc/eureka-server 8761:8761
   http://localhost:8761

🚀 API Gateway:
EOF

API_GATEWAY_LB=$(kubectl get svc api-gateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
echo "   External Load Balancer: $API_GATEWAY_LB:9191"

cat << EOF

📝 Useful Commands:
   # View all pods
   kubectl get pods -A

   # View logs
   kubectl logs -f deployment/order-service

   # Scale a service
   kubectl scale deployment order-service --replicas=3

   # Access monitoring dashboards
   make monitoring-dashboard

   # Destroy environment (when done testing)
   cd terraform/environments/$ENVIRONMENT && terraform destroy

💡 Next Steps:
   1. Wait for all pods to be in 'Running' state
   2. Test the API endpoints through the load balancer
   3. Access monitoring dashboards to see metrics
   4. Check application logs for any issues

🆘 Need Help?
   - Check the README.md in the terraform/ directory
   - View logs: kubectl logs -f deployment/<service-name>
   - Get help: make help

EOF

log_warning "💰 Remember: This infrastructure will incur AWS costs until destroyed"
log_info "To destroy the environment: cd terraform/environments/$ENVIRONMENT && terraform destroy"

echo ""
log_success "Setup completed! Your microservices infrastructure is ready to use."
