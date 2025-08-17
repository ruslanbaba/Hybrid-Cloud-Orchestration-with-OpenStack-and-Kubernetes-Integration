# GitOps Configuration

This directory contains GitOps configurations for automated deployment and management of the hybrid cloud orchestration platform using ArgoCD and policy enforcement with OPA Gatekeeper.

## Directory Structure

```
├── argocd/               # ArgoCD applications and configurations
│   ├── applications/     # Application definitions
│   ├── projects/         # ArgoCD projects
│   └── repositories/     # Repository connections
└── policies/             # OPA Gatekeeper policies
    ├── security/         # Security policies
    ├── resource/         # Resource management policies
    └── compliance/       # Compliance policies
```

## ArgoCD Setup

ArgoCD provides declarative, GitOps continuous delivery for Kubernetes:

### Features
- **Declarative GitOps**: Application definitions stored in Git
- **Multi-cluster deployment**: Deploy to OpenStack and public cloud clusters
- **Application health monitoring**: Real-time application status
- **Rollback capabilities**: Easy rollback to previous versions
- **RBAC integration**: Role-based access control

### Application Types
- **Infrastructure applications**: Core infrastructure components
- **Platform applications**: Monitoring, security, networking
- **Workload applications**: Business applications and services

## Policy Enforcement

OPA Gatekeeper provides policy enforcement for Kubernetes:

### Policy Categories
- **Security policies**: Pod security standards, network policies
- **Resource policies**: Resource quotas, limits, requests
- **Compliance policies**: Regulatory compliance requirements
- **Operational policies**: Naming conventions, labeling standards

## Workflow

1. **Code Changes**: Developers push changes to Git repositories
2. **GitOps Sync**: ArgoCD detects changes and syncs applications
3. **Policy Validation**: OPA Gatekeeper validates deployments
4. **Deployment**: Applications deployed to target clusters
5. **Monitoring**: Continuous monitoring and alerting
