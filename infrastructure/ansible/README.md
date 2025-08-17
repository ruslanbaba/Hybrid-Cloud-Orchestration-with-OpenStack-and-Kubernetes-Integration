# Ansible Configuration for OpenStack Deployment

This directory contains Ansible playbooks and configurations for deploying and managing OpenStack infrastructure using OpenStack-Ansible and Kolla-Ansible.

## Directory Structure

```
├── inventories/           # Inventory files for different environments
├── playbooks/            # Ansible playbooks for deployment and management
├── roles/                # Custom Ansible roles
├── group_vars/           # Group-specific variables
├── host_vars/            # Host-specific variables
└── configs/              # Configuration templates
```

## Deployment Methods

### 1. OpenStack-Ansible (OSA)
- Production-ready deployment method
- Uses LXC containers for service isolation
- Highly available configuration
- Integrated with Ceph storage

### 2. Kolla-Ansible
- Container-based deployment using Docker
- Faster deployment and updates
- Better resource utilization
- Easier upgrade path

## Quick Start

1. **Prepare the environment:**
```bash
# Install Ansible and dependencies
pip3 install ansible
pip3 install netaddr

# Clone OpenStack-Ansible
git clone https://opendev.org/openstack/openstack-ansible /opt/openstack-ansible
cd /opt/openstack-ansible
git checkout stable/2023.1

# Install Ansible galaxy requirements
ansible-galaxy install -r requirements.yml
```

2. **Configure inventory:**
```bash
# Copy and customize inventory
cp inventories/production/openstack_user_config.yml /etc/openstack_deploy/
```

3. **Deploy OpenStack:**
```bash
# Bootstrap the deployment
ansible-playbook -i inventory/production setup-hosts.yml
ansible-playbook -i inventory/production setup-infrastructure.yml
ansible-playbook -i inventory/production setup-openstack.yml
```

## Key Features

- **High Availability**: Multi-controller setup with load balancing
- **Security**: Hardened configurations and security policies
- **Monitoring**: Integrated monitoring and logging
- **Backup**: Automated backup and disaster recovery
- **Scalability**: Horizontal scaling capabilities
