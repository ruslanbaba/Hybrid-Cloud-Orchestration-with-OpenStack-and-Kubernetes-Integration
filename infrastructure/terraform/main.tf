terraform {
  required_version = ">= 1.5"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.54"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  backend "s3" {
    # Configure with environment variables or terraform.tfvars
    # bucket         = "terraform-state-bucket"
    # key            = "hybrid-cloud/terraform.tfstate"
    # region         = "us-west-2"
    # encrypt        = true
    # dynamodb_table = "terraform-locks"
  }
}

# OpenStack Provider Configuration
provider "openstack" {
  auth_url          = var.openstack_auth_url
  region            = var.openstack_region
  tenant_name       = var.openstack_tenant_name
  user_domain_name  = var.openstack_user_domain_name
  project_domain_name = var.openstack_project_domain_name
  use_octavia       = true
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = var.environment
      Project     = "hybrid-cloud-orchestration"
      ManagedBy   = "terraform"
    }
  }
}

# Google Cloud Provider Configuration
provider "google" {
  project = var.gcp_project_id
  region  = var.gcp_region
}

# Azure Provider Configuration
provider "azurerm" {
  features {}
  subscription_id = var.azure_subscription_id
  tenant_id       = var.azure_tenant_id
}

# Data sources for existing resources
data "openstack_images_image_v2" "ubuntu" {
  name        = "Ubuntu 22.04 LTS"
  most_recent = true
}

data "openstack_compute_flavor_v2" "controller" {
  name = var.controller_flavor
}

data "openstack_compute_flavor_v2" "compute" {
  name = var.compute_flavor
}

data "openstack_networking_network_v2" "external" {
  name     = var.external_network_name
  external = true
}
