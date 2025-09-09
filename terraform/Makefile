# =================================
# MAKEFILE FOR TERRAFORM DEPLOYMENTS
# =================================

.PHONY: help init plan apply destroy clean validate fmt docs build push

# Default environment
ENV ?= dev
AWS_REGION ?= us-west-2
PROJECT_NAME ?= springboot-kafka-microservices

# Terraform directories
TERRAFORM_DIR = terraform
ENV_DIR = $(TERRAFORM_DIR)/environments/$(ENV)

# Docker settings
DOCKER_REGISTRY ?= your-docker-registry
IMAGE_TAG ?= latest

# Colors for output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)SpringBoot Kafka Microservices - Infrastructure Management$(NC)"
	@echo ""
	@echo "$(YELLOW)Usage:$(NC)"
	@echo "  make <target> [ENV=<environment>]"
	@echo ""
	@echo "$(YELLOW)Environments:$(NC)"
	@echo "  dev  - Development environment (default)"
	@echo "  prod - Production environment"
	@echo ""
	@echo "$(YELLOW)Targets:$(NC)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# =================================
# TERRAFORM COMMANDS
# =================================

init: ## Initialize Terraform
	@echo "$(BLUE)Initializing Terraform for $(ENV) environment...$(NC)"
	cd $(ENV_DIR) && terraform init

validate: ## Validate Terraform configuration
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	cd $(ENV_DIR) && terraform validate

fmt: ## Format Terraform files
	@echo "$(BLUE)Formatting Terraform files...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive

plan: ## Show Terraform execution plan
	@echo "$(BLUE)Creating Terraform plan for $(ENV) environment...$(NC)"
	cd $(ENV_DIR) && terraform plan -var-file=terraform.tfvars

apply: ## Apply Terraform changes
	@echo "$(YELLOW)Applying Terraform changes for $(ENV) environment...$(NC)"
	cd $(ENV_DIR) && terraform apply -var-file=terraform.tfvars -auto-approve

destroy: ## Destroy Terraform infrastructure
	@echo "$(RED)Destroying Terraform infrastructure for $(ENV) environment...$(NC)"
	@echo "$(RED)This action cannot be undone!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		cd $(ENV_DIR) && terraform destroy -var-file=terraform.tfvars -auto-approve; \
	else \
		echo "$(YELLOW)Cancelled.$(NC)"; \
	fi

output: ## Show Terraform outputs
	@echo "$(BLUE)Terraform outputs for $(ENV) environment:$(NC)"
	cd $(ENV_DIR) && terraform output

refresh: ## Refresh Terraform state
	@echo "$(BLUE)Refreshing Terraform state for $(ENV) environment...$(NC)"
	cd $(ENV_DIR) && terraform refresh -var-file=terraform.tfvars

# =================================
# DOCKER COMMANDS
# =================================

build: ## Build all microservice Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	./build-jars.sh
	docker-compose -f docker-compose-build.yml build

push: ## Push Docker images to registry
	@echo "$(BLUE)Pushing Docker images to $(DOCKER_REGISTRY)...$(NC)"
	@services="service-registry api-gateway order-service payment-service product-service email-service identity-service"; \
	for service in $$services; do \
		echo "$(BLUE)Pushing $$service...$(NC)"; \
		docker tag $(PROJECT_NAME)/$$service:$(IMAGE_TAG) $(DOCKER_REGISTRY)/$$service:$(IMAGE_TAG); \
		docker push $(DOCKER_REGISTRY)/$$service:$(IMAGE_TAG); \
	done

# =================================
# KUBERNETES COMMANDS
# =================================

kubeconfig: ## Configure kubectl for EKS cluster
	@echo "$(BLUE)Configuring kubectl for $(ENV) environment...$(NC)"
	aws eks update-kubeconfig --region $(AWS_REGION) --name $(PROJECT_NAME)-$(ENV)-cluster

deploy-apps: ## Deploy applications to Kubernetes
	@echo "$(BLUE)Deploying applications to Kubernetes...$(NC)"
	cd $(ENV_DIR) && terraform apply -target=module.infrastructure.kubernetes_deployment -var-file=terraform.tfvars

k8s-status: ## Show Kubernetes cluster status
	@echo "$(BLUE)Kubernetes cluster status:$(NC)"
	kubectl get nodes
	kubectl get pods -A
	kubectl get services -A

monitoring-dashboard: ## Access monitoring dashboards
	@echo "$(BLUE)Setting up port forwards for monitoring dashboards...$(NC)"
	@echo "$(YELLOW)Grafana will be available at: http://localhost:3000$(NC)"
	@echo "$(YELLOW)Prometheus will be available at: http://localhost:9090$(NC)"
	@echo "$(YELLOW)Eureka will be available at: http://localhost:8761$(NC)"
	kubectl port-forward -n monitoring svc/prometheus-operator-grafana 3000:80 &
	kubectl port-forward -n monitoring svc/prometheus-operator-kube-p-prometheus 9090:9090 &
	kubectl port-forward svc/eureka-server 8761:8761 &
	@echo "$(GREEN)Port forwards started in background. Use 'make stop-monitoring' to stop.$(NC)"

stop-monitoring: ## Stop monitoring port forwards
	@echo "$(BLUE)Stopping monitoring port forwards...$(NC)"
	pkill -f "kubectl port-forward.*monitoring"
	pkill -f "kubectl port-forward.*eureka"

logs: ## Show application logs
	@echo "$(BLUE)Showing logs for $(SVC) service...$(NC)"
	kubectl logs -f deployment/$(SVC) --tail=100

# =================================
# DEVELOPMENT COMMANDS
# =================================

dev-up: ## Start development environment
	@echo "$(BLUE)Starting development environment...$(NC)"
	make ENV=dev init
	make ENV=dev apply
	make ENV=dev kubeconfig

dev-down: ## Stop development environment
	@echo "$(BLUE)Stopping development environment...$(NC)"
	make ENV=dev destroy

# =================================
# PRODUCTION COMMANDS
# =================================

prod-plan: ## Plan production deployment
	@echo "$(BLUE)Planning production deployment...$(NC)"
	make ENV=prod plan

prod-deploy: ## Deploy to production (requires confirmation)
	@echo "$(RED)Deploying to PRODUCTION environment!$(NC)"
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		make ENV=prod apply; \
		make ENV=prod kubeconfig; \
	else \
		echo "$(YELLOW)Cancelled.$(NC)"; \
	fi

# =================================
# UTILITY COMMANDS
# =================================

clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	find $(TERRAFORM_DIR) -name "*.tfstate*" -type f -delete
	find $(TERRAFORM_DIR) -name ".terraform" -type d -exec rm -rf {} +
	find $(TERRAFORM_DIR) -name ".terraform.lock.hcl" -type f -delete

docs: ## Generate documentation
	@echo "$(BLUE)Generating Terraform documentation...$(NC)"
	terraform-docs markdown table $(TERRAFORM_DIR) > $(TERRAFORM_DIR)/README.md

check-tools: ## Check required tools
	@echo "$(BLUE)Checking required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "$(RED)terraform is required but not installed$(NC)"; exit 1; }
	@command -v kubectl >/dev/null 2>&1 || { echo "$(RED)kubectl is required but not installed$(NC)"; exit 1; }
	@command -v aws >/dev/null 2>&1 || { echo "$(RED)aws cli is required but not installed$(NC)"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)docker is required but not installed$(NC)"; exit 1; }
	@echo "$(GREEN)All required tools are installed$(NC)"

cost-estimate: ## Estimate infrastructure costs
	@echo "$(BLUE)Estimating infrastructure costs for $(ENV) environment...$(NC)"
	@echo "$(YELLOW)Note: Install 'infracost' for detailed cost analysis$(NC)"
	@if command -v infracost >/dev/null 2>&1; then \
		cd $(ENV_DIR) && infracost breakdown --path .; \
	else \
		echo "$(YELLOW)Install infracost for cost estimation: https://www.infracost.io/docs/$(NC)"; \
	fi

# =================================
# EXAMPLES
# =================================

examples: ## Show usage examples
	@echo "$(BLUE)Usage Examples:$(NC)"
	@echo ""
	@echo "$(YELLOW)Deploy development environment:$(NC)"
	@echo "  make dev-up"
	@echo ""
	@echo "$(YELLOW)Deploy to production:$(NC)"
	@echo "  make prod-plan"
	@echo "  make prod-deploy"
	@echo ""
	@echo "$(YELLOW)Build and push Docker images:$(NC)"
	@echo "  make build"
	@echo "  make push DOCKER_REGISTRY=your-registry"
	@echo ""
	@echo "$(YELLOW)Access monitoring:$(NC)"
	@echo "  make kubeconfig ENV=dev"
	@echo "  make monitoring-dashboard"
	@echo ""
	@echo "$(YELLOW)View logs:$(NC)"
	@echo "  make logs SVC=order-service"
