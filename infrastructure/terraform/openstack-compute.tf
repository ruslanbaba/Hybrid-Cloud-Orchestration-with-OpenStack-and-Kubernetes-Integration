# SSH Key Pair
resource "openstack_compute_keypair_v2" "keypair" {
  name       = "${var.environment}-keypair"
  public_key = file("~/.ssh/id_rsa.pub")
}

# Controller Instances
resource "openstack_compute_instance_v2" "controller" {
  count           = var.controller_count
  name            = "${var.environment}-controller-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.controller.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.controller.name]

  metadata = {
    role        = "controller"
    environment = var.environment
    node_id     = count.index + 1
  }

  network {
    name = openstack_networking_network_v2.management.name
  }

  network {
    name = openstack_networking_network_v2.tunnel.name
  }

  network {
    name = openstack_networking_network_v2.storage.name
  }

  user_data = templatefile("${path.module}/cloud-init/controller.yaml", {
    hostname     = "${var.environment}-controller-${count.index + 1}"
    node_id      = count.index + 1
    environment  = var.environment
  })

  tags = ["controller", "openstack", var.environment]
}

# Compute Instances
resource "openstack_compute_instance_v2" "compute" {
  count           = var.compute_count
  name            = "${var.environment}-compute-${count.index + 1}"
  image_id        = data.openstack_images_image_v2.ubuntu.id
  flavor_id       = data.openstack_compute_flavor_v2.compute.id
  key_pair        = openstack_compute_keypair_v2.keypair.name
  security_groups = [openstack_networking_secgroup_v2.compute.name]

  metadata = {
    role        = "compute"
    environment = var.environment
    node_id     = count.index + 1
  }

  network {
    name = openstack_networking_network_v2.management.name
  }

  network {
    name = openstack_networking_network_v2.tunnel.name
  }

  network {
    name = openstack_networking_network_v2.storage.name
  }

  user_data = templatefile("${path.module}/cloud-init/compute.yaml", {
    hostname     = "${var.environment}-compute-${count.index + 1}"
    node_id      = count.index + 1
    environment  = var.environment
  })

  tags = ["compute", "openstack", var.environment]
}

# Floating IPs for controller nodes
resource "openstack_networking_floatingip_v2" "controller" {
  count = var.controller_count
  pool  = var.external_network_name
  
  tags = ["controller", "floating-ip"]
}

resource "openstack_compute_floatingip_associate_v2" "controller" {
  count       = var.controller_count
  floating_ip = openstack_networking_floatingip_v2.controller[count.index].address
  instance_id = openstack_compute_instance_v2.controller[count.index].id
}

# Load Balancer for OpenStack APIs
resource "openstack_lb_loadbalancer_v2" "api_lb" {
  name          = "${var.environment}-api-lb"
  vip_subnet_id = openstack_networking_subnet_v2.management.id
  
  tags = ["loadbalancer", "api", var.environment]
}

resource "openstack_networking_floatingip_v2" "api_lb" {
  pool = var.external_network_name
  tags = ["loadbalancer", "floating-ip"]
}

resource "openstack_networking_floatingip_associate_v2" "api_lb" {
  floating_ip = openstack_networking_floatingip_v2.api_lb.address
  port_id     = openstack_lb_loadbalancer_v2.api_lb.vip_port_id
}

# HTTP Listener
resource "openstack_lb_listener_v2" "api_http" {
  name            = "${var.environment}-api-http"
  protocol        = "HTTP"
  protocol_port   = 80
  loadbalancer_id = openstack_lb_loadbalancer_v2.api_lb.id
}

# HTTPS Listener
resource "openstack_lb_listener_v2" "api_https" {
  name            = "${var.environment}-api-https"
  protocol        = "HTTPS"
  protocol_port   = 443
  loadbalancer_id = openstack_lb_loadbalancer_v2.api_lb.id
}

# Pool for controller nodes
resource "openstack_lb_pool_v2" "api_pool" {
  name        = "${var.environment}-api-pool"
  protocol    = "HTTP"
  lb_method   = "ROUND_ROBIN"
  listener_id = openstack_lb_listener_v2.api_http.id
}

# Pool members (controller nodes)
resource "openstack_lb_member_v2" "api_members" {
  count         = var.controller_count
  pool_id       = openstack_lb_pool_v2.api_pool.id
  address       = openstack_compute_instance_v2.controller[count.index].network[0].fixed_ip_v4
  protocol_port = 80
  
  subnet_id = openstack_networking_subnet_v2.management.id
}

# Health Monitor
resource "openstack_lb_monitor_v2" "api_monitor" {
  name        = "${var.environment}-api-monitor"
  pool_id     = openstack_lb_pool_v2.api_pool.id
  type        = "HTTP"
  delay       = 10
  timeout     = 5
  max_retries = 3
  url_path    = "/healthcheck"
}

# Block Storage Volumes for additional storage
resource "openstack_blockstorage_volume_v3" "controller_storage" {
  count = var.controller_count
  name  = "${var.environment}-controller-${count.index + 1}-storage"
  size  = 100
  
  metadata = {
    role = "controller-storage"
    node = count.index + 1
  }
}

resource "openstack_compute_volume_attach_v2" "controller_storage" {
  count       = var.controller_count
  instance_id = openstack_compute_instance_v2.controller[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.controller_storage[count.index].id
}

resource "openstack_blockstorage_volume_v3" "compute_storage" {
  count = var.compute_count
  name  = "${var.environment}-compute-${count.index + 1}-storage"
  size  = 200
  
  metadata = {
    role = "compute-storage"
    node = count.index + 1
  }
}

resource "openstack_compute_volume_attach_v2" "compute_storage" {
  count       = var.compute_count
  instance_id = openstack_compute_instance_v2.compute[count.index].id
  volume_id   = openstack_blockstorage_volume_v3.compute_storage[count.index].id
}
