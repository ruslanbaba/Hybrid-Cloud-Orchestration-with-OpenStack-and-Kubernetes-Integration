# Kubernetes Cluster Configurations

This directory contains Kubernetes cluster definitions, applications, and networking configurations for the hybrid cloud orchestration platform.

## Directory Structure

```
├── clusters/              # Cluster API definitions and configurations
│   ├── openstack/        # OpenStack-based Kubernetes clusters
│   ├── aws/              # AWS EKS cluster configurations
│   ├── gcp/              # GCP GKE cluster configurations
│   └── azure/            # Azure AKS cluster configurations
├── applications/         # Application deployments and manifests
│   ├── sample-apps/      # Sample applications (Sock Shop, etc.)
│   ├── monitoring/       # Monitoring stack deployments
│   └── networking/       # Network-related applications
└── networking/           # CNI and service mesh configurations
    ├── cilium/           # Cilium CNI configuration
    ├── istio/            # Istio service mesh
    └── metallb/          # Load balancer configuration
```

## Cluster Federation

The hybrid cloud setup uses Cluster API and Admiral for multi-cluster management:

- **Cluster API**: Declarative cluster lifecycle management
- **Admiral**: Multi-cluster service discovery and traffic management
- **Submariner**: Cross-cluster networking and service discovery
- **Liqo**: Dynamic resource sharing between clusters

## Networking

### CNI: Cilium with eBPF
- High-performance networking
- Advanced security policies
- Multi-cluster mesh capabilities
- Observability and monitoring

### Service Mesh: Istio
- Cross-cluster service communication
- Traffic management and load balancing
- Security and policy enforcement
- Distributed tracing

## Application Deployment

Applications are deployed using:
- **Helm Charts**: Package management
- **Kustomize**: Configuration management
- **ArgoCD**: GitOps continuous delivery
- **Flux**: Alternative GitOps solution

## Security

- **Pod Security Standards**: Enforced security policies
- **Network Policies**: Micro-segmentation
- **RBAC**: Role-based access control
- **OPA Gatekeeper**: Policy as code
