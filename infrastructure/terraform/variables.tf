# Environment Configuration
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

# OpenStack Configuration
variable "openstack_auth_url" {
  description = "OpenStack authentication URL"
  type        = string
}

variable "openstack_region" {
  description = "OpenStack region"
  type        = string
  default     = "RegionOne"
}

variable "openstack_tenant_name" {
  description = "OpenStack tenant/project name"
  type        = string
}

variable "openstack_user_domain_name" {
  description = "OpenStack user domain name"
  type        = string
  default     = "Default"
}

variable "openstack_project_domain_name" {
  description = "OpenStack project domain name"
  type        = string
  default     = "Default"
}

# Network Configuration
variable "external_network_name" {
  description = "Name of the external network"
  type        = string
  default     = "public"
}

variable "management_network_cidr" {
  description = "CIDR for management network"
  type        = string
  default     = "10.0.1.0/24"
}

variable "tunnel_network_cidr" {
  description = "CIDR for tunnel network"
  type        = string
  default     = "10.0.2.0/24"
}

variable "storage_network_cidr" {
  description = "CIDR for storage network"
  type        = string
  default     = "10.0.3.0/24"
}

# Compute Configuration
variable "controller_flavor" {
  description = "Flavor for controller nodes"
  type        = string
  default     = "m1.xlarge"
}

variable "compute_flavor" {
  description = "Flavor for compute nodes"
  type        = string
  default     = "m1.large"
}

variable "controller_count" {
  description = "Number of controller nodes"
  type        = number
  default     = 3
}

variable "compute_count" {
  description = "Number of compute nodes"
  type        = number
  default     = 2
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "aws_availability_zones" {
  description = "AWS availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "eks_cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.27"
}

variable "eks_node_instance_types" {
  description = "EKS node instance types"
  type        = list(string)
  default     = ["m5.large", "m5.xlarge"]
}

# GCP Configuration
variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "us-west1"
}

variable "gke_cluster_version" {
  description = "GKE cluster version"
  type        = string
  default     = "1.27"
}

variable "gke_node_machine_type" {
  description = "GKE node machine type"
  type        = string
  default     = "e2-standard-4"
}

# Azure Configuration
variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_location" {
  description = "Azure location"
  type        = string
  default     = "West US 2"
}

variable "aks_cluster_version" {
  description = "AKS cluster version"
  type        = string
  default     = "1.27"
}

variable "aks_node_vm_size" {
  description = "AKS node VM size"
  type        = string
  default     = "Standard_D4s_v3"
}

# Security Configuration
variable "enable_pod_security_policy" {
  description = "Enable Pod Security Policy"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Network Policy"
  type        = bool
  default     = true
}

variable "enable_rbac" {
  description = "Enable RBAC"
  type        = bool
  default     = true
}

# Monitoring Configuration
variable "enable_monitoring" {
  description = "Enable monitoring stack"
  type        = bool
  default     = true
}

variable "enable_logging" {
  description = "Enable logging stack"
  type        = bool
  default     = true
}

variable "enable_tracing" {
  description = "Enable distributed tracing"
  type        = bool
  default     = true
}

# Tags
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "hybrid-cloud-orchestration"
    ManagedBy   = "terraform"
  }
}
