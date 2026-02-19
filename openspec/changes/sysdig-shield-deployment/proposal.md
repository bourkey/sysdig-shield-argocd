## Why

Organizations need runtime security, threat detection, and compliance monitoring for their Kubernetes clusters. Sysdig Shield provides comprehensive security capabilities, but manual deployment is error-prone and inconsistent across environments. A GitOps-based approach using ArgoCD ensures declarative, auditable, and automated deployments with full version control and rollback capabilities.

## What Changes

- ArgoCD Application manifests for GitOps-based deployment of all Sysdig Shield components
- Kubernetes manifests for Sysdig Agent (DaemonSet), Admission Controller, Node Analyzer, and KSPM Collector
- Multi-environment support using Kustomize overlays (dev, staging, production)
- Secure secrets management configuration (Sealed Secrets, External Secrets Operator, or Vault integration)
- Comprehensive RBAC policies with minimal required permissions
- Network policies to secure Sysdig component communication
- Helm values files for environment-specific configurations
- Health checks and sync wave configuration for ordered deployment
- Documentation for deployment, configuration, troubleshooting, and maintenance

## Capabilities

### New Capabilities

- `argocd-applications`: ArgoCD Application definitions for deploying Sysdig Shield components via GitOps
- `sysdig-agent`: Kubernetes DaemonSet deployment for Sysdig runtime security agent on all nodes
- `admission-controller`: Webhook-based policy enforcement at deployment time with image scanning
- `node-analyzer`: Image vulnerability scanning and compliance checking for container images
- `kspm-collector`: Kubernetes Security Posture Management for continuous compliance monitoring
- `multi-environment-config`: Kustomize-based overlays for dev, staging, and production environments
- `secrets-management`: Secure handling of Sysdig access keys and TLS certificates
- `rbac-policies`: Role-based access control configurations with minimal required permissions
- `network-policies`: Network security policies for Sysdig component communication
- `helm-integration`: Helm values files and chart integration for flexible deployment options

### Modified Capabilities

<!-- No existing capabilities are being modified - this is a new deployment -->

## Impact

**New Infrastructure**:
- Namespace: `sysdig-shield` for component isolation
- DaemonSets: Sysdig Agent, Node Analyzer (run on all nodes)
- Deployments: Admission Controller, KSPM Collector
- Services: Webhook endpoints for admission controller
- ConfigMaps: Agent configuration, collector settings
- Secrets: Sysdig access keys, TLS certificates
- RBAC: ServiceAccounts, ClusterRoles, ClusterRoleBindings
- NetworkPolicies: Ingress/egress rules for Sysdig components

**Dependencies**:
- ArgoCD (v2.8+) installed and configured on target cluster
- Kubernetes cluster (v1.24+) with RBAC enabled
- Active Sysdig Secure subscription with access key
- Optional: Sealed Secrets, External Secrets Operator, or Vault for secrets management

**Integration Points**:
- ArgoCD monitors Git repository for deployment automation
- Sysdig agents communicate with Sysdig SaaS backend (app.sysdigcloud.com)
- Admission controller webhook intercepts pod creation/updates
- Existing application deployments subject to admission controller policies
- CI/CD pipelines may need updates to handle policy enforcement

**Operational Impact**:
- All nodes will run Sysdig Agent (resource overhead: ~500m CPU, 512Mi memory per node)
- Admission controller may block deployments that violate security policies
- Image pulls may be delayed during scanning (first deployment)
- Network egress required to Sysdig backend (firewall rules may need updates)
