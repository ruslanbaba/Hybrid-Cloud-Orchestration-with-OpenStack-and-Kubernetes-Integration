# Output values for OpenStack resources
output "openstack_controller_ips" {
  description = "IP addresses of OpenStack controller nodes"
  value = {
    management = openstack_compute_instance_v2.controller[*].network[0].fixed_ip_v4
    floating   = openstack_networking_floatingip_v2.controller[*].address
  }
}

output "openstack_compute_ips" {
  description = "IP addresses of OpenStack compute nodes"
  value = {
    management = openstack_compute_instance_v2.compute[*].network[0].fixed_ip_v4
  }
}

output "openstack_api_endpoint" {
  description = "OpenStack API load balancer endpoint"
  value       = openstack_networking_floatingip_v2.api_lb.address
}

output "openstack_networks" {
  description = "OpenStack network information"
  value = {
    management = {
      id   = openstack_networking_network_v2.management.id
      cidr = var.management_network_cidr
    }
    tunnel = {
      id   = openstack_networking_network_v2.tunnel.id
      cidr = var.tunnel_network_cidr
    }
    storage = {
      id   = openstack_networking_network_v2.storage.id
      cidr = var.storage_network_cidr
    }
  }
}

# Output values for AWS resources
output "aws_eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "aws_eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}

output "aws_eks_cluster_iam_role_arn" {
  description = "IAM role ARN associated with EKS cluster"
  value       = aws_eks_cluster.main.role_arn
}

output "aws_eks_cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

output "aws_vpc_id" {
  description = "ID of the VPC where resources are created"
  value       = aws_vpc.main.id
}

output "aws_private_subnets" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "aws_public_subnets" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

# Kubernetes configuration outputs
output "kubeconfig_eks" {
  description = "kubectl config for EKS cluster"
  value = {
    apiVersion      = "v1"
    kind            = "Config"
    current-context = "terraform"
    contexts = [{
      name = "terraform"
      context = {
        cluster = "terraform"
        user    = "terraform"
      }
    }]
    clusters = [{
      name = "terraform"
      cluster = {
        certificate-authority-data = aws_eks_cluster.main.certificate_authority[0].data
        server                     = aws_eks_cluster.main.endpoint
      }
    }]
    users = [{
      name = "terraform"
      user = {
        exec = {
          apiVersion = "client.authentication.k8s.io/v1beta1"
          command    = "aws"
          args = [
            "eks",
            "get-token",
            "--cluster-name",
            aws_eks_cluster.main.name,
          ]
        }
      }
    }]
  }
  sensitive = true
}

# Environment information
output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region_info" {
  description = "Regional deployment information"
  value = {
    openstack = var.openstack_region
    aws       = var.aws_region
    gcp       = var.gcp_region
    azure     = var.azure_location
  }
}

# Security and monitoring endpoints
output "security_groups" {
  description = "Security group information"
  value = {
    openstack = {
      controller = openstack_networking_secgroup_v2.controller.id
      compute    = openstack_networking_secgroup_v2.compute.id
    }
    aws = {
      eks_cluster = aws_security_group.eks_cluster.id
      eks_nodes   = aws_security_group.eks_nodes.id
    }
  }
}

# Load balancer information
output "load_balancers" {
  description = "Load balancer endpoints and information"
  value = {
    openstack_api = {
      vip_address    = openstack_lb_loadbalancer_v2.api_lb.vip_address
      floating_ip    = openstack_networking_floatingip_v2.api_lb.address
      loadbalancer_id = openstack_lb_loadbalancer_v2.api_lb.id
    }
  }
}

# Storage information
output "storage_volumes" {
  description = "Block storage volume information"
  value = {
    controller_storage = openstack_blockstorage_volume_v3.controller_storage[*].id
    compute_storage    = openstack_blockstorage_volume_v3.compute_storage[*].id
  }
}

# SSH access information
output "ssh_access" {
  description = "SSH access information"
  value = {
    keypair_name = openstack_compute_keypair_v2.keypair.name
    controller_access = [
      for i, ip in openstack_networking_floatingip_v2.controller[*].address :
      "ssh ubuntu@${ip}"
    ]
  }
}

# Inventory for Ansible
output "ansible_inventory" {
  description = "Ansible inventory in JSON format"
  value = {
    _meta = {
      hostvars = merge(
        # Controller nodes
        {
          for i, instance in openstack_compute_instance_v2.controller :
          "${var.environment}-controller-${i + 1}" => {
            ansible_host                 = openstack_networking_floatingip_v2.controller[i].address
            ansible_user                = "ubuntu"
            ansible_ssh_private_key_file = "~/.ssh/id_rsa"
            private_ip                  = instance.network[0].fixed_ip_v4
            tunnel_ip                   = instance.network[1].fixed_ip_v4
            storage_ip                  = instance.network[2].fixed_ip_v4
            node_role                   = "controller"
            node_id                     = i + 1
            environment                 = var.environment
          }
        },
        # Compute nodes
        {
          for i, instance in openstack_compute_instance_v2.compute :
          "${var.environment}-compute-${i + 1}" => {
            ansible_host                 = instance.network[0].fixed_ip_v4
            ansible_user                = "ubuntu"
            ansible_ssh_private_key_file = "~/.ssh/id_rsa"
            ansible_ssh_common_args     = "-o ProxyJump=ubuntu@${openstack_networking_floatingip_v2.controller[0].address}"
            private_ip                  = instance.network[0].fixed_ip_v4
            tunnel_ip                   = instance.network[1].fixed_ip_v4
            storage_ip                  = instance.network[2].fixed_ip_v4
            node_role                   = "compute"
            node_id                     = i + 1
            environment                 = var.environment
          }
        }
      )
    }
    controllers = {
      hosts = [
        for i in range(var.controller_count) :
        "${var.environment}-controller-${i + 1}"
      ]
      vars = {
        node_role = "controller"
      }
    }
    compute = {
      hosts = [
        for i in range(var.compute_count) :
        "${var.environment}-compute-${i + 1}"
      ]
      vars = {
        node_role = "compute"
      }
    }
    openstack = {
      children = ["controllers", "compute"]
      vars = {
        environment                = var.environment
        openstack_region          = var.openstack_region
        management_network_cidr   = var.management_network_cidr
        tunnel_network_cidr       = var.tunnel_network_cidr
        storage_network_cidr      = var.storage_network_cidr
        external_network_name     = var.external_network_name
        api_lb_vip               = openstack_lb_loadbalancer_v2.api_lb.vip_address
        api_lb_floating_ip       = openstack_networking_floatingip_v2.api_lb.address
      }
    }
  }
}
