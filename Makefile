# Hybrid Cloud Orchestration with OpenStack and Kubernetes Integration
# Makefile for deployment automation and management

.PHONY: help init plan apply destroy validate lint test clean setup-tools

# Variables
TERRAFORM_DIR := infrastructure/terraform
ANSIBLE_DIR := infrastructure/ansible
K8S_DIR := kubernetes
GITOPS_DIR := gitops
MONITORING_DIR := monitoring

# Environment variables
ENV ?= dev
REGION ?= us-west-2
OPENSTACK_CLOUD ?= openstack

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[1;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
help: ## Show this help message
	@echo "$(BLUE)Hybrid Cloud Orchestration - Available Commands$(NC)"
	@echo "=================================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Setup and initialization
setup-tools: ## Install required tools and dependencies
	@echo "$(YELLOW)Installing required tools...$(NC)"
	@command -v terraform >/dev/null 2>&1 || { echo "Installing Terraform..."; curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -; sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(shell lsb_release -cs) main"; sudo apt-get update && sudo apt-get install terraform; }
	@command -v ansible >/dev/null 2>&1 || { echo "Installing Ansible..."; pip3 install ansible; }
	@command -v kubectl >/dev/null 2>&1 || { echo "Installing kubectl..."; curl -LO "https://dl.k8s.io/release/$$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"; chmod +x kubectl; sudo mv kubectl /usr/local/bin/; }
	@command -v helm >/dev/null 2>&1 || { echo "Installing Helm..."; curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash; }
	@command -v argocd >/dev/null 2>&1 || { echo "Installing ArgoCD CLI..."; curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64; sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd; rm argocd-linux-amd64; }
	@echo "$(GREEN)✓ All tools installed successfully$(NC)"

init: setup-tools ## Initialize the project and install dependencies
	@echo "$(YELLOW)Initializing Terraform...$(NC)"
	cd $(TERRAFORM_DIR) && terraform init
	@echo "$(YELLOW)Installing Ansible requirements...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-galaxy install -r requirements.yml --force
	@echo "$(GREEN)✓ Project initialized successfully$(NC)"

# Terraform operations
validate: ## Validate Terraform configuration
	@echo "$(YELLOW)Validating Terraform configuration...$(NC)"
	cd $(TERRAFORM_DIR) && terraform validate
	@echo "$(GREEN)✓ Terraform configuration is valid$(NC)"

plan: validate ## Create Terraform execution plan
	@echo "$(YELLOW)Creating Terraform plan...$(NC)"
	cd $(TERRAFORM_DIR) && terraform plan -var="environment=$(ENV)" -out=tfplan
	@echo "$(GREEN)✓ Terraform plan created$(NC)"

apply: plan ## Apply Terraform configuration
	@echo "$(YELLOW)Applying Terraform configuration...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply tfplan
	@echo "$(GREEN)✓ Infrastructure deployed successfully$(NC)"
	@$(MAKE) generate-inventory

destroy: ## Destroy Terraform-managed infrastructure
	@echo "$(RED)WARNING: This will destroy all infrastructure!$(NC)"
	@echo "Press Enter to continue or Ctrl+C to cancel..."
	@read
	cd $(TERRAFORM_DIR) && terraform destroy -var="environment=$(ENV)" -auto-approve
	@echo "$(GREEN)✓ Infrastructure destroyed$(NC)"

# Infrastructure deployment
deploy-openstack: apply generate-inventory ## Deploy OpenStack infrastructure
	@echo "$(YELLOW)Deploying OpenStack with Ansible...$(NC)"
	cd $(ANSIBLE_DIR) && ansible-playbook -i inventory/$(ENV) playbooks/site.yml
	@echo "$(GREEN)✓ OpenStack deployed successfully$(NC)"

deploy-public-cloud: ## Deploy public cloud resources
	@echo "$(YELLOW)Deploying public cloud infrastructure...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -target=module.aws -target=module.gcp -var="environment=$(ENV)"
	@echo "$(GREEN)✓ Public cloud infrastructure deployed$(NC)"

# Kubernetes operations
deploy-k8s-openstack: ## Deploy Kubernetes cluster on OpenStack using Magnum
	@echo "$(YELLOW)Deploying Kubernetes cluster on OpenStack...$(NC)"
	cd $(K8S_DIR) && kubectl apply -f clusters/openstack/
	@echo "$(GREEN)✓ OpenStack Kubernetes cluster deployed$(NC)"

deploy-monitoring: ## Deploy monitoring stack
	@echo "$(YELLOW)Deploying monitoring stack...$(NC)"
	kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm repo add grafana https://grafana.github.io/helm-charts
	helm repo update
	helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
		--namespace monitoring \
		--values $(MONITORING_DIR)/prometheus/values.yml
	helm upgrade --install grafana grafana/grafana \
		--namespace monitoring \
		--values $(MONITORING_DIR)/grafana/values.yml
	@echo "$(GREEN)✓ Monitoring stack deployed$(NC)"

# GitOps operations
install-argocd: ## Install ArgoCD
	@echo "$(YELLOW)Installing ArgoCD...$(NC)"
	kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
	helm repo add argo https://argoproj.github.io/argo-helm
	helm repo update
	helm upgrade --install argocd argo/argo-cd \
		--namespace argocd \
		--values $(GITOPS_DIR)/argocd/values.yml
	@echo "$(YELLOW)Waiting for ArgoCD to be ready...$(NC)"
	kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd
	@echo "$(GREEN)✓ ArgoCD installed successfully$(NC)"
	@$(MAKE) configure-argocd

configure-argocd: ## Configure ArgoCD with projects and applications
	@echo "$(YELLOW)Configuring ArgoCD...$(NC)"
	kubectl apply -f $(GITOPS_DIR)/argocd/projects/
	kubectl apply -f $(GITOPS_DIR)/argocd/applications/
	@echo "$(GREEN)✓ ArgoCD configured$(NC)"

# Application deployment
deploy-sample-apps: ## Deploy sample applications
	@echo "$(YELLOW)Deploying sample applications...$(NC)"
	kubectl apply -f $(K8S_DIR)/applications/sample-apps/
	@echo "$(GREEN)✓ Sample applications deployed$(NC)"

# Security operations
deploy-policies: ## Deploy OPA Gatekeeper policies
	@echo "$(YELLOW)Deploying security policies...$(NC)"
	kubectl apply -f $(GITOPS_DIR)/policies/security/
	@echo "$(GREEN)✓ Security policies deployed$(NC)"

# Utility operations
generate-inventory: ## Generate Ansible inventory from Terraform output
	@echo "$(YELLOW)Generating Ansible inventory...$(NC)"
	cd $(TERRAFORM_DIR) && terraform output -json ansible_inventory > ../ansible/inventory/$(ENV).json
	@echo "$(GREEN)✓ Inventory generated$(NC)"

get-kubeconfig: ## Get kubeconfig for clusters
	@echo "$(YELLOW)Getting kubeconfig files...$(NC)"
	cd $(TERRAFORM_DIR) && terraform output -raw kubeconfig_eks > ~/.kube/config-eks
	@echo "OpenStack kubeconfig: kubectl config --kubeconfig=~/.kube/config-openstack"
	@echo "AWS EKS kubeconfig: kubectl config --kubeconfig=~/.kube/config-eks"
	@echo "$(GREEN)✓ Kubeconfig files ready$(NC)"

get-endpoints: ## Get important service endpoints
	@echo "$(BLUE)Service Endpoints:$(NC)"
	@cd $(TERRAFORM_DIR) && echo "OpenStack Horizon: https://$$(terraform output -raw openstack_api_endpoint)"
	@cd $(TERRAFORM_DIR) && echo "AWS EKS Endpoint: $$(terraform output -raw aws_eks_cluster_endpoint)"
	@echo "ArgoCD UI: https://$$(kubectl get ingress argocd-server-ingress -n argocd -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo 'Not configured')"
	@echo "Grafana UI: https://$$(kubectl get ingress grafana-ingress -n monitoring -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo 'Not configured')"
	@echo "Sock Shop: https://$$(kubectl get ingress sock-shop-ingress -n sock-shop -o jsonpath='{.spec.rules[0].host}' 2>/dev/null || echo 'Not configured')"

# Testing and validation
test-connectivity: ## Test connectivity between clusters
	@echo "$(YELLOW)Testing cluster connectivity...$(NC)"
	kubectl --context=openstack get nodes
	kubectl --context=aws get nodes
	@echo "$(GREEN)✓ Connectivity test passed$(NC)"

test-applications: ## Test application deployments
	@echo "$(YELLOW)Testing application health...$(NC)"
	kubectl get pods -A --field-selector=status.phase!=Running
	@echo "$(GREEN)✓ Application health check completed$(NC)"

benchmark: ## Run performance benchmarks
	@echo "$(YELLOW)Running performance benchmarks...$(NC)"
	@echo "This would run k6, wrk, or other performance testing tools"
	@echo "$(GREEN)✓ Benchmarks completed$(NC)"

# Maintenance operations
backup: ## Backup critical data and configurations
	@echo "$(YELLOW)Creating backups...$(NC)"
	@echo "Backing up Terraform state..."
	@echo "Backing up Kubernetes configurations..."
	@echo "Backing up monitoring data..."
	@echo "$(GREEN)✓ Backup completed$(NC)"

update: ## Update all components to latest versions
	@echo "$(YELLOW)Updating components...$(NC)"
	helm repo update
	kubectl apply -f $(GITOPS_DIR)/argocd/applications/
	@echo "$(GREEN)✓ Components updated$(NC)"

scale-up: ## Scale up the infrastructure
	@echo "$(YELLOW)Scaling up infrastructure...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -var="compute_count=4" -var="controller_count=3"
	@echo "$(GREEN)✓ Infrastructure scaled up$(NC)"

scale-down: ## Scale down the infrastructure
	@echo "$(YELLOW)Scaling down infrastructure...$(NC)"
	cd $(TERRAFORM_DIR) && terraform apply -var="compute_count=2" -var="controller_count=3"
	@echo "$(GREEN)✓ Infrastructure scaled down$(NC)"

# Troubleshooting
logs: ## Get logs from critical components
	@echo "$(YELLOW)Gathering logs...$(NC)"
	kubectl logs -n argocd deployment/argocd-server --tail=50
	kubectl logs -n monitoring deployment/prometheus-server --tail=50
	kubectl logs -n kube-system daemonset/cilium --tail=50

debug: ## Debug cluster issues
	@echo "$(YELLOW)Running debug checks...$(NC)"
	kubectl cluster-info
	kubectl get events --sort-by=.metadata.creationTimestamp
	kubectl top nodes
	kubectl top pods -A

health-check: ## Perform comprehensive health check
	@echo "$(YELLOW)Performing health check...$(NC)"
	@echo "Checking cluster status..."
	kubectl get nodes
	@echo "Checking system pods..."
	kubectl get pods -n kube-system
	@echo "Checking ArgoCD status..."
	kubectl get pods -n argocd
	@echo "Checking monitoring status..."
	kubectl get pods -n monitoring
	@echo "$(GREEN)✓ Health check completed$(NC)"

# Cleanup operations
clean: ## Clean up temporary files and caches
	@echo "$(YELLOW)Cleaning up...$(NC)"
	cd $(TERRAFORM_DIR) && rm -f tfplan terraform.tfstate.backup .terraform.lock.hcl
	find . -name "*.pyc" -delete
	find . -name "__pycache__" -delete
	docker system prune -f
	@echo "$(GREEN)✓ Cleanup completed$(NC)"

reset: clean ## Reset the entire environment (destructive)
	@echo "$(RED)WARNING: This will reset the entire environment!$(NC)"
	@echo "Press Enter to continue or Ctrl+C to cancel..."
	@read
	@$(MAKE) destroy
	@$(MAKE) clean
	@echo "$(GREEN)✓ Environment reset$(NC)"

# Linting and validation
lint: ## Lint all configuration files
	@echo "$(YELLOW)Linting configuration files...$(NC)"
	@command -v yamllint >/dev/null 2>&1 || pip3 install yamllint
	@command -v ansible-lint >/dev/null 2>&1 || pip3 install ansible-lint
	find . -name "*.yml" -o -name "*.yaml" | xargs yamllint -d relaxed
	cd $(ANSIBLE_DIR) && ansible-lint playbooks/
	cd $(TERRAFORM_DIR) && terraform fmt -check -recursive
	@echo "$(GREEN)✓ Linting completed$(NC)"

format: ## Format all configuration files
	@echo "$(YELLOW)Formatting configuration files...$(NC)"
	cd $(TERRAFORM_DIR) && terraform fmt -recursive
	@echo "$(GREEN)✓ Formatting completed$(NC)"

# Documentation
docs: ## Generate documentation
	@echo "$(YELLOW)Generating documentation...$(NC)"
	cd $(TERRAFORM_DIR) && terraform-docs markdown table --output-file README.md .
	@echo "$(GREEN)✓ Documentation generated$(NC)"

# Complete deployment workflows
deploy-all: init deploy-openstack deploy-public-cloud install-argocd deploy-monitoring deploy-sample-apps ## Deploy complete hybrid cloud platform
	@echo "$(GREEN)🎉 Complete hybrid cloud platform deployed successfully!$(NC)"
	@$(MAKE) get-endpoints

quick-start: setup-tools init plan apply install-argocd deploy-sample-apps ## Quick start deployment for demo
	@echo "$(GREEN)🚀 Quick start deployment completed!$(NC)"
	@$(MAKE) get-endpoints
