# OpenStack Network Resources
resource "openstack_networking_network_v2" "management" {
  name           = "management-network"
  admin_state_up = "true"
  
  tags = ["management", "openstack"]
}

resource "openstack_networking_subnet_v2" "management" {
  name       = "management-subnet"
  network_id = openstack_networking_network_v2.management.id
  cidr       = var.management_network_cidr
  ip_version = 4
  
  allocation_pool {
    start = cidrhost(var.management_network_cidr, 10)
    end   = cidrhost(var.management_network_cidr, 250)
  }
  
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_networking_network_v2" "tunnel" {
  name           = "tunnel-network"
  admin_state_up = "true"
  
  tags = ["tunnel", "openstack"]
}

resource "openstack_networking_subnet_v2" "tunnel" {
  name       = "tunnel-subnet"
  network_id = openstack_networking_network_v2.tunnel.id
  cidr       = var.tunnel_network_cidr
  ip_version = 4
  
  allocation_pool {
    start = cidrhost(var.tunnel_network_cidr, 10)
    end   = cidrhost(var.tunnel_network_cidr, 250)
  }
}

resource "openstack_networking_network_v2" "storage" {
  name           = "storage-network"
  admin_state_up = "true"
  
  tags = ["storage", "openstack"]
}

resource "openstack_networking_subnet_v2" "storage" {
  name       = "storage-subnet"
  network_id = openstack_networking_network_v2.storage.id
  cidr       = var.storage_network_cidr
  ip_version = 4
  
  allocation_pool {
    start = cidrhost(var.storage_network_cidr, 10)
    end   = cidrhost(var.storage_network_cidr, 250)
  }
}

# Router for external connectivity
resource "openstack_networking_router_v2" "router" {
  name                = "main-router"
  admin_state_up      = true
  external_network_id = data.openstack_networking_network_v2.external.id
}

resource "openstack_networking_router_interface_v2" "management" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.management.id
}

# Security Groups
resource "openstack_networking_secgroup_v2" "controller" {
  name        = "controller-secgroup"
  description = "Security group for OpenStack controller nodes"
}

resource "openstack_networking_secgroup_rule_v2" "controller_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_http" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_https" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_mysql" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_group_id   = openstack_networking_secgroup_v2.controller.id
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_rabbitmq" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5672
  port_range_max    = 5672
  remote_group_id   = openstack_networking_secgroup_v2.controller.id
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_memcached" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 11211
  port_range_max    = 11211
  remote_group_id   = openstack_networking_secgroup_v2.controller.id
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

# OpenStack API ports
resource "openstack_networking_secgroup_rule_v2" "controller_keystone" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 5000
  port_range_max    = 5000
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_glance" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9292
  port_range_max    = 9292
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_nova" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8774
  port_range_max    = 8774
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_neutron" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 9696
  port_range_max    = 9696
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

resource "openstack_networking_secgroup_rule_v2" "controller_cinder" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8776
  port_range_max    = 8776
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.controller.id
}

# Security group for compute nodes
resource "openstack_networking_secgroup_v2" "compute" {
  name        = "compute-secgroup"
  description = "Security group for OpenStack compute nodes"
}

resource "openstack_networking_secgroup_rule_v2" "compute_ssh" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.management_network_cidr
  security_group_id = openstack_networking_secgroup_v2.compute.id
}

resource "openstack_networking_secgroup_rule_v2" "compute_nova_compute" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8775
  port_range_max    = 8775
  remote_group_id   = openstack_networking_secgroup_v2.controller.id
  security_group_id = openstack_networking_secgroup_v2.compute.id
}

resource "openstack_networking_secgroup_rule_v2" "compute_libvirt" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 16509
  port_range_max    = 16509
  remote_group_id   = openstack_networking_secgroup_v2.controller.id
  security_group_id = openstack_networking_secgroup_v2.compute.id
}

# VXLAN tunneling
resource "openstack_networking_secgroup_rule_v2" "compute_vxlan" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "udp"
  port_range_min    = 4789
  port_range_max    = 4789
  remote_group_id   = openstack_networking_secgroup_v2.compute.id
  security_group_id = openstack_networking_secgroup_v2.compute.id
}
