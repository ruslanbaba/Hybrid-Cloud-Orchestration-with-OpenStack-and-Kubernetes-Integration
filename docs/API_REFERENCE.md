# API Reference Documentation

## Overview

This document provides comprehensive API reference for the Hybrid Cloud Orchestration platform, including OpenStack APIs, Kubernetes APIs, and custom platform APIs.

## Platform APIs

### Hybrid Cloud Management API

#### Base URL
```
https://api.hybrid-cloud.example.com/v1
```

#### Authentication

**Bearer Token Authentication**
```bash
curl -H "Authorization: Bearer ${API_TOKEN}" \
     https://api.hybrid-cloud.example.com/v1/clusters
```

**OAuth 2.0 Authentication**
```bash
# Get access token
curl -X POST https://auth.hybrid-cloud.example.com/oauth/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&client_id=${CLIENT_ID}&client_secret=${CLIENT_SECRET}"

# Use access token
curl -H "Authorization: Bearer ${ACCESS_TOKEN}" \
     https://api.hybrid-cloud.example.com/v1/clusters
```

#### Cluster Management

**List Clusters**
```http
GET /v1/clusters
```

**Response:**
```json
{
  "clusters": [
    {
      "id": "cluster-001",
      "name": "openstack-k8s-prod",
      "provider": "openstack",
      "region": "us-west-1",
      "status": "active",
      "version": "v1.28.0",
      "nodes": {
        "total": 10,
        "ready": 10,
        "master": 3,
        "worker": 7
      },
      "created_at": "2025-08-15T10:30:00Z",
      "updated_at": "2025-08-17T14:45:30Z"
    },
    {
      "id": "cluster-002",
      "name": "aws-eks-staging",
      "provider": "aws",
      "region": "us-west-2",
      "status": "active",
      "version": "v1.28.0",
      "nodes": {
        "total": 5,
        "ready": 5,
        "master": 3,
        "worker": 2
      },
      "created_at": "2025-08-16T09:15:00Z",
      "updated_at": "2025-08-17T12:20:15Z"
    }
  ],
  "total": 2,
  "page": 1,
  "per_page": 10
}
```

**Get Cluster Details**
```http
GET /v1/clusters/{cluster_id}
```

**Response:**
```json
{
  "id": "cluster-001",
  "name": "openstack-k8s-prod",
  "provider": "openstack",
  "region": "us-west-1",
  "status": "active",
  "version": "v1.28.0",
  "configuration": {
    "node_pools": [
      {
        "name": "master-pool",
        "size": 3,
        "instance_type": "m5.xlarge",
        "disk_size": 100,
        "labels": {
          "node-role.kubernetes.io/master": ""
        },
        "taints": [
          {
            "key": "node-role.kubernetes.io/master",
            "effect": "NoSchedule"
          }
        ]
      }
    ],
    "networking": {
      "cluster_cidr": "10.244.0.0/16",
      "service_cidr": "10.96.0.0/12",
      "cni": "cilium"
    },
    "addons": [
      "ingress-nginx",
      "cert-manager",
      "argocd",
      "prometheus-operator"
    ]
  },
  "metrics": {
    "cpu_usage": "45%",
    "memory_usage": "67%",
    "disk_usage": "23%",
    "network_io": {
      "ingress": "125.5 MB/s",
      "egress": "98.2 MB/s"
    }
  }
}
```

**Create Cluster**
```http
POST /v1/clusters
```

**Request Body:**
```json
{
  "name": "new-cluster",
  "provider": "openstack",
  "region": "us-east-1",
  "version": "v1.28.0",
  "configuration": {
    "node_pools": [
      {
        "name": "master-pool",
        "size": 3,
        "instance_type": "m5.xlarge",
        "disk_size": 100,
        "auto_scaling": false
      },
      {
        "name": "worker-pool",
        "size": 5,
        "instance_type": "m5.large",
        "disk_size": 50,
        "auto_scaling": {
          "enabled": true,
          "min_size": 3,
          "max_size": 10,
          "target_cpu": 70
        }
      }
    ],
    "networking": {
      "cluster_cidr": "10.244.0.0/16",
      "service_cidr": "10.96.0.0/12",
      "cni": "cilium"
    },
    "addons": [
      "ingress-nginx",
      "cert-manager"
    ]
  }
}
```

**Response:**
```json
{
  "id": "cluster-003",
  "name": "new-cluster",
  "status": "creating",
  "operation_id": "op-12345",
  "created_at": "2025-08-17T15:30:00Z"
}
```

#### Application Management

**Deploy Application**
```http
POST /v1/clusters/{cluster_id}/applications
```

**Request Body:**
```json
{
  "name": "sample-app",
  "namespace": "production",
  "source": {
    "type": "git",
    "repository": "https://github.com/example/sample-app.git",
    "path": "k8s/manifests",
    "revision": "main"
  },
  "sync_policy": {
    "automated": true,
    "prune": true,
    "self_heal": true
  },
  "values": {
    "image": {
      "tag": "v1.2.3"
    },
    "replicas": 3,
    "resources": {
      "requests": {
        "cpu": "100m",
        "memory": "128Mi"
      },
      "limits": {
        "cpu": "500m",
        "memory": "512Mi"
      }
    }
  }
}
```

**List Applications**
```http
GET /v1/clusters/{cluster_id}/applications
```

**Response:**
```json
{
  "applications": [
    {
      "id": "app-001",
      "name": "sample-app",
      "namespace": "production",
      "status": "healthy",
      "sync_status": "synced",
      "health_status": "healthy",
      "created_at": "2025-08-17T10:00:00Z",
      "last_sync": "2025-08-17T15:30:00Z",
      "resources": {
        "deployments": 1,
        "services": 1,
        "pods": 3
      }
    }
  ]
}
```

#### Workload Management

**Get Workload Status**
```http
GET /v1/clusters/{cluster_id}/workloads
```

**Response:**
```json
{
  "workloads": {
    "deployments": [
      {
        "name": "frontend",
        "namespace": "production",
        "replicas": {
          "desired": 3,
          "ready": 3,
          "available": 3
        },
        "image": "registry.example.com/frontend:v1.2.3",
        "status": "ready"
      }
    ],
    "services": [
      {
        "name": "frontend-service",
        "namespace": "production",
        "type": "ClusterIP",
        "cluster_ip": "10.96.45.123",
        "ports": [
          {
            "port": 80,
            "target_port": 8080,
            "protocol": "TCP"
          }
        ]
      }
    ],
    "pods": [
      {
        "name": "frontend-deployment-abc123",
        "namespace": "production",
        "status": "Running",
        "ready": true,
        "node": "worker-node-1",
        "ip": "10.244.1.45"
      }
    ]
  }
}
```

**Scale Workload**
```http
PATCH /v1/clusters/{cluster_id}/workloads/{workload_type}/{namespace}/{name}/scale
```

**Request Body:**
```json
{
  "replicas": 5
}
```

#### Multi-Cloud Operations

**Cross-Cluster Application Deployment**
```http
POST /v1/multi-cluster/applications
```

**Request Body:**
```json
{
  "name": "distributed-app",
  "clusters": [
    {
      "cluster_id": "cluster-001",
      "components": ["frontend", "api"]
    },
    {
      "cluster_id": "cluster-002",
      "components": ["database", "cache"]
    }
  ],
  "source": {
    "type": "git",
    "repository": "https://github.com/example/distributed-app.git",
    "path": "manifests"
  },
  "placement_policy": {
    "strategy": "availability",
    "constraints": [
      {
        "type": "region_diversity",
        "min_regions": 2
      },
      {
        "type": "provider_diversity",
        "min_providers": 2
      }
    ]
  }
}
```

**Get Multi-Cluster Status**
```http
GET /v1/multi-cluster/status
```

**Response:**
```json
{
  "clusters": {
    "total": 3,
    "healthy": 3,
    "degraded": 0,
    "offline": 0
  },
  "applications": {
    "total": 15,
    "healthy": 14,
    "degraded": 1,
    "failed": 0
  },
  "connectivity": {
    "inter_cluster_network": "healthy",
    "service_mesh": "healthy",
    "federation": "healthy"
  },
  "performance": {
    "avg_response_time": "45ms",
    "cross_cluster_latency": "12ms",
    "throughput": "1250 req/s"
  }
}
```

### Monitoring and Observability API

#### Metrics API

**Get Cluster Metrics**
```http
GET /v1/clusters/{cluster_id}/metrics
```

**Query Parameters:**
- `start`: Start time (RFC3339 format)
- `end`: End time (RFC3339 format)
- `step`: Query resolution step duration
- `metrics`: Comma-separated list of metrics

**Example:**
```bash
curl "https://api.hybrid-cloud.example.com/v1/clusters/cluster-001/metrics?start=2025-08-17T10:00:00Z&end=2025-08-17T11:00:00Z&step=5m&metrics=cpu_usage,memory_usage,network_io"
```

**Response:**
```json
{
  "metrics": {
    "cpu_usage": {
      "metric": "cpu_usage",
      "values": [
        ["2025-08-17T10:00:00Z", "45.2"],
        ["2025-08-17T10:05:00Z", "47.8"],
        ["2025-08-17T10:10:00Z", "43.1"]
      ]
    },
    "memory_usage": {
      "metric": "memory_usage",
      "values": [
        ["2025-08-17T10:00:00Z", "67.5"],
        ["2025-08-17T10:05:00Z", "69.2"],
        ["2025-08-17T10:10:00Z", "66.8"]
      ]
    }
  }
}
```

**Get Application Metrics**
```http
GET /v1/clusters/{cluster_id}/applications/{app_name}/metrics
```

**Response:**
```json
{
  "application": "sample-app",
  "metrics": {
    "request_rate": "125.5 req/s",
    "error_rate": "0.02%",
    "response_time": {
      "p50": "45ms",
      "p95": "120ms",
      "p99": "250ms"
    },
    "resource_usage": {
      "cpu": "230m",
      "memory": "456Mi"
    }
  }
}
```

#### Logging API

**Query Logs**
```http
POST /v1/logs/query
```

**Request Body:**
```json
{
  "query": "level:error AND namespace:production",
  "start_time": "2025-08-17T10:00:00Z",
  "end_time": "2025-08-17T11:00:00Z",
  "limit": 100,
  "sort": "timestamp:desc"
}
```

**Response:**
```json
{
  "logs": [
    {
      "timestamp": "2025-08-17T10:45:23Z",
      "level": "error",
      "message": "Failed to connect to database",
      "namespace": "production",
      "pod": "api-deployment-xyz789",
      "container": "api",
      "source": "application"
    }
  ],
  "total": 1,
  "took": "25ms"
}
```

#### Alerting API

**List Alerts**
```http
GET /v1/alerts
```

**Response:**
```json
{
  "alerts": [
    {
      "id": "alert-001",
      "name": "HighCPUUsage",
      "state": "firing",
      "severity": "warning",
      "description": "CPU usage is above 80%",
      "cluster": "cluster-001",
      "namespace": "production",
      "started_at": "2025-08-17T10:30:00Z",
      "labels": {
        "alertname": "HighCPUUsage",
        "cluster": "cluster-001",
        "severity": "warning"
      },
      "annotations": {
        "summary": "High CPU usage detected",
        "description": "CPU usage is 85% for the last 5 minutes"
      }
    }
  ]
}
```

**Create Alert Rule**
```http
POST /v1/alert-rules
```

**Request Body:**
```json
{
  "name": "DatabaseConnectionFailure",
  "description": "Alert when database connection fails",
  "expression": "increase(database_connection_errors_total[5m]) > 5",
  "duration": "2m",
  "severity": "critical",
  "labels": {
    "team": "backend",
    "service": "database"
  },
  "annotations": {
    "summary": "Database connection failures detected",
    "description": "{{ $value }} connection errors in the last 5 minutes"
  }
}
```

### Security API

#### Policy Management

**List Security Policies**
```http
GET /v1/security/policies
```

**Response:**
```json
{
  "policies": [
    {
      "id": "policy-001",
      "name": "require-security-context",
      "type": "admission_controller",
      "enabled": true,
      "description": "Require security context for all pods",
      "targets": {
        "namespaces": ["production", "staging"],
        "kinds": ["Pod"]
      },
      "created_at": "2025-08-15T09:00:00Z"
    }
  ]
}
```

**Create Security Policy**
```http
POST /v1/security/policies
```

**Request Body:**
```json
{
  "name": "require-resource-limits",
  "type": "admission_controller",
  "description": "Require resource limits for all containers",
  "enforcement": "deny",
  "targets": {
    "namespaces": ["production"],
    "kinds": ["Pod"]
  },
  "rules": {
    "require_resource_limits": {
      "cpu": true,
      "memory": true
    }
  }
}
```

#### Vulnerability Scanning

**Get Vulnerability Report**
```http
GET /v1/security/vulnerabilities
```

**Query Parameters:**
- `severity`: Filter by severity (low, medium, high, critical)
- `fixed`: Filter by fix availability (true, false)
- `namespace`: Filter by namespace

**Response:**
```json
{
  "vulnerabilities": [
    {
      "id": "CVE-2025-1234",
      "severity": "high",
      "score": 8.1,
      "package": "nginx",
      "version": "1.20.1",
      "fixed_version": "1.20.2",
      "description": "Buffer overflow in nginx HTTP request processing",
      "affected_images": [
        "registry.example.com/nginx:1.20.1"
      ],
      "fix_available": true
    }
  ],
  "summary": {
    "total": 1,
    "critical": 0,
    "high": 1,
    "medium": 0,
    "low": 0
  }
}
```

**Trigger Security Scan**
```http
POST /v1/security/scan
```

**Request Body:**
```json
{
  "targets": [
    {
      "type": "cluster",
      "cluster_id": "cluster-001"
    },
    {
      "type": "image",
      "image": "registry.example.com/app:latest"
    }
  ],
  "scan_types": ["vulnerabilities", "secrets", "misconfigurations"]
}
```

## OpenStack Integration APIs

### Magnum Cluster Management

**Create Kubernetes Cluster Template**
```bash
openstack coe cluster template create k8s-template \
  --image fedora-coreos-35 \
  --keypair my-keypair \
  --external-network public \
  --flavor m1.medium \
  --master-flavor m1.large \
  --docker-volume-size 20 \
  --network-driver cilium \
  --coe kubernetes \
  --labels kube_tag=v1.28.0,monitoring_enabled=true
```

**Create Kubernetes Cluster**
```bash
openstack coe cluster create production-k8s \
  --cluster-template k8s-template \
  --master-count 3 \
  --node-count 5 \
  --timeout 60
```

**Get Cluster Configuration**
```bash
openstack coe cluster config production-k8s --dir ~/.kube/
```

### Heat Orchestration Templates

**Stack Template for Hybrid Infrastructure**
```yaml
# stack-template.yaml
heat_template_version: 2021-04-16

description: Hybrid Cloud Infrastructure Stack

parameters:
  cluster_name:
    type: string
    description: Name of the Kubernetes cluster
    default: hybrid-k8s
  
  node_count:
    type: number
    description: Number of worker nodes
    default: 5
    constraints:
      - range: { min: 1, max: 20 }

resources:
  cluster_network:
    type: OS::Neutron::Net
    properties:
      name: { str_replace: { template: "$cluster-network", params: { $cluster: { get_param: cluster_name } } } }

  cluster_subnet:
    type: OS::Neutron::Subnet
    properties:
      network: { get_resource: cluster_network }
      cidr: 10.0.0.0/24
      gateway_ip: 10.0.0.1
      dns_nameservers: [8.8.8.8, 8.8.4.4]

  kubernetes_cluster:
    type: OS::Magnum::Cluster
    properties:
      name: { get_param: cluster_name }
      cluster_template: { get_resource: cluster_template }
      master_count: 3
      node_count: { get_param: node_count }

outputs:
  cluster_uuid:
    description: UUID of the Kubernetes cluster
    value: { get_resource: kubernetes_cluster }
  
  cluster_api_address:
    description: API address of the cluster
    value: { get_attr: [kubernetes_cluster, api_address] }
```

## Kubernetes API Extensions

### Custom Resource Definitions

**HybridCluster CRD**
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: hybridclusters.platform.example.com
spec:
  group: platform.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              provider:
                type: string
                enum: ["openstack", "aws", "gcp", "azure"]
              region:
                type: string
              version:
                type: string
              nodeGroups:
                type: array
                items:
                  type: object
                  properties:
                    name:
                      type: string
                    size:
                      type: integer
                      minimum: 1
                    instanceType:
                      type: string
                    autoScaling:
                      type: object
                      properties:
                        enabled:
                          type: boolean
                        minSize:
                          type: integer
                        maxSize:
                          type: integer
          status:
            type: object
            properties:
              phase:
                type: string
                enum: ["Pending", "Creating", "Active", "Updating", "Deleting", "Failed"]
              conditions:
                type: array
                items:
                  type: object
                  properties:
                    type:
                      type: string
                    status:
                      type: string
                    lastTransitionTime:
                      type: string
                      format: date-time
  scope: Namespaced
  names:
    plural: hybridclusters
    singular: hybridcluster
    kind: HybridCluster
```

**MultiClusterApplication CRD**
```yaml
apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
  name: multiclusterapplications.platform.example.com
spec:
  group: platform.example.com
  versions:
  - name: v1
    served: true
    storage: true
    schema:
      openAPIV3Schema:
        type: object
        properties:
          spec:
            type: object
            properties:
              source:
                type: object
                properties:
                  repository:
                    type: string
                  path:
                    type: string
                  revision:
                    type: string
              placement:
                type: array
                items:
                  type: object
                  properties:
                    cluster:
                      type: string
                    components:
                      type: array
                      items:
                        type: string
                    values:
                      type: object
                      x-kubernetes-preserve-unknown-fields: true
          status:
            type: object
            properties:
              deployments:
                type: array
                items:
                  type: object
                  properties:
                    cluster:
                      type: string
                    status:
                      type: string
                    lastSync:
                      type: string
                      format: date-time
  scope: Namespaced
  names:
    plural: multiclusterapplications
    singular: multiclusterapplication
    kind: MultiClusterApplication
```

## SDK and Client Libraries

### Python SDK

```python
from hybrid_cloud_sdk import HybridCloudClient

# Initialize client
client = HybridCloudClient(
    base_url="https://api.hybrid-cloud.example.com",
    api_key="your-api-key"
)

# List clusters
clusters = client.clusters.list()

# Get cluster details
cluster = client.clusters.get("cluster-001")

# Deploy application
application = client.applications.deploy(
    cluster_id="cluster-001",
    name="sample-app",
    source={
        "repository": "https://github.com/example/app.git",
        "path": "k8s",
        "revision": "main"
    },
    values={
        "image": {"tag": "v1.2.3"},
        "replicas": 3
    }
)

# Get metrics
metrics = client.metrics.get_cluster_metrics(
    cluster_id="cluster-001",
    start_time="2025-08-17T10:00:00Z",
    end_time="2025-08-17T11:00:00Z",
    metrics=["cpu_usage", "memory_usage"]
)
```

### Go SDK

```go
package main

import (
    "context"
    "fmt"
    "github.com/example/hybrid-cloud-go-sdk/client"
)

func main() {
    cfg := client.Config{
        BaseURL: "https://api.hybrid-cloud.example.com",
        APIKey:  "your-api-key",
    }
    
    c, err := client.New(cfg)
    if err != nil {
        panic(err)
    }
    
    ctx := context.Background()
    
    // List clusters
    clusters, err := c.Clusters.List(ctx, nil)
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Found %d clusters\n", len(clusters.Clusters))
    
    // Deploy application
    app, err := c.Applications.Deploy(ctx, "cluster-001", &client.ApplicationDeployRequest{
        Name:      "sample-app",
        Namespace: "production",
        Source: client.ApplicationSource{
            Repository: "https://github.com/example/app.git",
            Path:       "k8s",
            Revision:   "main",
        },
        Values: map[string]interface{}{
            "image": map[string]interface{}{
                "tag": "v1.2.3",
            },
            "replicas": 3,
        },
    })
    if err != nil {
        panic(err)
    }
    
    fmt.Printf("Deployed application: %s\n", app.ID)
}
```

### JavaScript/TypeScript SDK

```typescript
import { HybridCloudClient } from '@example/hybrid-cloud-sdk';

const client = new HybridCloudClient({
  baseUrl: 'https://api.hybrid-cloud.example.com',
  apiKey: 'your-api-key'
});

// List clusters
const clusters = await client.clusters.list();

// Deploy application
const application = await client.applications.deploy('cluster-001', {
  name: 'sample-app',
  namespace: 'production',
  source: {
    repository: 'https://github.com/example/app.git',
    path: 'k8s',
    revision: 'main'
  },
  values: {
    image: { tag: 'v1.2.3' },
    replicas: 3
  }
});

// Subscribe to real-time updates
const subscription = client.events.subscribe({
  clusters: ['cluster-001'],
  events: ['application.deployed', 'cluster.scaled']
});

subscription.on('event', (event) => {
  console.log('Received event:', event);
});
```

## Error Handling

### Standard Error Response Format

```json
{
  "error": {
    "code": "CLUSTER_NOT_FOUND",
    "message": "Cluster with ID 'cluster-001' not found",
    "details": {
      "cluster_id": "cluster-001",
      "available_clusters": ["cluster-002", "cluster-003"]
    },
    "request_id": "req-abc123def456"
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Invalid request format or parameters |
| `UNAUTHORIZED` | 401 | Authentication required or invalid |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `CLUSTER_NOT_FOUND` | 404 | Specified cluster does not exist |
| `APPLICATION_NOT_FOUND` | 404 | Specified application does not exist |
| `CONFLICT` | 409 | Resource conflict (e.g., name already exists) |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `INTERNAL_ERROR` | 500 | Internal server error |
| `SERVICE_UNAVAILABLE` | 503 | Service temporarily unavailable |

## Rate Limiting

### Rate Limit Headers

```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1692280800
```

### Rate Limit Tiers

| Tier | Requests per Hour | Burst Limit |
|------|-------------------|-------------|
| Basic | 1,000 | 100 |
| Professional | 10,000 | 500 |
| Enterprise | 100,000 | 2,000 |

## Webhooks

### Webhook Events

**Cluster Events**
```json
{
  "event": "cluster.created",
  "timestamp": "2025-08-17T15:30:00Z",
  "data": {
    "cluster_id": "cluster-003",
    "name": "new-cluster",
    "provider": "openstack",
    "status": "creating"
  }
}
```

**Application Events**
```json
{
  "event": "application.deployed",
  "timestamp": "2025-08-17T15:45:00Z",
  "data": {
    "application_id": "app-001",
    "cluster_id": "cluster-001",
    "name": "sample-app",
    "version": "v1.2.3",
    "status": "healthy"
  }
}
```

### Webhook Configuration

```http
POST /v1/webhooks
```

**Request Body:**
```json
{
  "url": "https://your-app.example.com/webhooks/hybrid-cloud",
  "events": [
    "cluster.created",
    "cluster.updated",
    "cluster.deleted",
    "application.deployed",
    "application.updated",
    "application.failed"
  ],
  "secret": "webhook-secret-key",
  "active": true
}
```

---

This API reference provides comprehensive documentation for integrating with the Hybrid Cloud Orchestration platform programmatically.
