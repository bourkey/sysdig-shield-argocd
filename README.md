# Sysdig Shield ArgoCD Deployment

GitOps-based deployment of Sysdig Shield security platform using ArgoCD for Kubernetes clusters.

Thanks to AndrewD for the inspiration

## Overview

This repository contains ArgoCD Application manifests and Kubernetes configurations for deploying **Sysdig Shield**, a comprehensive runtime security, compliance, and threat detection platform for Kubernetes environments. Using GitOps principles with ArgoCD ensures consistent, auditable, and automated deployments across multiple clusters and environments.

### What is Sysdig Shield?

Sysdig Shield provides:
- **Runtime Threat Detection**: Real-time security monitoring and threat detection
- **Kubernetes Security Posture Management (KSPM)**: Compliance and configuration monitoring
- **Image Scanning**: Vulnerability assessment and policy enforcement
- **Admission Controller**: Policy-based deployment controls
- **Forensics**: Detailed investigation and response capabilities

### Why ArgoCD?

ArgoCD provides:
- **Declarative GitOps**: Infrastructure and application definitions stored in Git
- **Automated Sync**: Automatic deployment of changes from Git repository
- **Rollback**: Easy rollback to previous versions
- **Multi-cluster**: Manage deployments across multiple Kubernetes clusters
- **Audit Trail**: Complete history of all changes and deployments

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Git Repository                          │
│  (This Repo - Single Source of Truth)                       │
│                                                              │
│  ├── argocd-apps/          (ArgoCD Applications)            │
│  ├── manifests/            (Kubernetes Manifests)           │
│  ├── helm-values/          (Helm Values)                    │
│  └── kustomize/            (Environment Overlays)           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ GitOps Sync
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      ArgoCD                                  │
│  - Monitors Git repository                                   │
│  - Syncs desired state to clusters                          │
│  - Provides UI/CLI for management                           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ Deploy
                     ▼
┌─────────────────────────────────────────────────────────────┐
│              Kubernetes Cluster(s)                           │
│                                                              │
│  ┌──────────────────────────────────────────────┐           │
│  │         Sysdig Shield Components              │           │
│  ├──────────────────────────────────────────────┤           │
│  │ • Sysdig Agent (DaemonSet)                   │           │
│  │ • Admission Controller (Deployment)          │           │
│  │ • Node Analyzer (DaemonSet)                  │           │
│  │ • KSPM Collector (Deployment)                │           │
│  │ • Rapid Response (Deployment)                │           │
│  └──────────────────────────────────────────────┘           │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

- **Kubernetes Cluster**: v1.24+ with RBAC enabled
- **ArgoCD**: v2.8+ installed and configured
- **kubectl**: Configured to access your cluster
- **argocd CLI**: For command-line management
- **Sysdig Account**: Active Sysdig Secure subscription with access key

## Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/sysdig-shield-argocd.git
cd sysdig-shield-argocd
```

### 2. Configure Sysdig Access

Create a secret with your Sysdig access key:

```bash
kubectl create namespace sysdig-shield

kubectl create secret generic sysdig-agent \
  --from-literal=access-key=YOUR_SYSDIG_ACCESS_KEY \
  -n sysdig-shield
```

### 3. Deploy with ArgoCD

```bash
# Create ArgoCD application
argocd app create sysdig-shield \
  --repo https://github.com/yourusername/sysdig-shield-argocd.git \
  --path manifests \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace sysdig-shield \
  --sync-policy automated

# Or apply from manifest
argocd app create -f argocd-apps/sysdig-shield.yaml
```

### 4. Verify Deployment

```bash
# Check ArgoCD application status
argocd app get sysdig-shield

# Verify pods are running
kubectl get pods -n sysdig-shield

# Check Sysdig agent connectivity
kubectl exec -it daemonset/sysdig-agent -n sysdig-shield -- sysdig-agent-check
```

## Repository Structure

```
.
├── argocd-apps/              # ArgoCD Application definitions
│   ├── sysdig-shield.yaml   # Main Sysdig Shield application
│   └── environments/        # Environment-specific applications
│       ├── dev.yaml
│       ├── staging.yaml
│       └── production.yaml
│
├── manifests/               # Kubernetes manifests
│   ├── namespace.yaml
│   ├── sysdig-agent/
│   ├── admission-controller/
│   ├── node-analyzer/
│   └── kspm-collector/
│
├── helm-values/             # Helm values files
│   ├── base-values.yaml
│   └── environments/
│       ├── dev-values.yaml
│       ├── staging-values.yaml
│       └── production-values.yaml
│
├── kustomize/              # Kustomize overlays
│   ├── base/
│   │   └── kustomization.yaml
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── production/
│
├── test/                   # Test manifests and policies
│   ├── sample-deployment.yaml
│   └── policy-tests/
│
└── docs/                   # Documentation
    ├── installation.md
    ├── configuration.md
    └── troubleshooting.md
```

## Configuration

### Environment Variables

Configure Sysdig behavior through environment-specific values:

| Variable | Description | Default |
|----------|-------------|---------|
| `SYSDIG_BACKEND` | Sysdig SaaS backend URL | `https://app.sysdigcloud.com` |
| `SYSDIG_REGION` | Regional backend (us1, us2, eu1, etc.) | `us1` |
| `AGENT_LOG_LEVEL` | Agent logging level | `info` |
| `ADMISSION_CONTROLLER_ENABLED` | Enable admission controller | `true` |

### Helm Values

Customize deployment using Helm values files in `helm-values/`:

```yaml
# helm-values/production-values.yaml
global:
  sysdig:
    region: "us1"

agent:
  enabled: true
  resources:
    requests:
      cpu: 500m
      memory: 512Mi
    limits:
      cpu: 1000m
      memory: 1Gi

admissionController:
  enabled: true
  features:
    k8sAuditDetections: true
    scanningPolicies: true
```

### Multi-Environment Setup

Use Kustomize overlays for environment-specific configurations:

```bash
# Deploy to development
argocd app create sysdig-shield-dev \
  --path kustomize/overlays/dev \
  --dest-namespace sysdig-shield-dev

# Deploy to production
argocd app create sysdig-shield-prod \
  --path kustomize/overlays/production \
  --dest-namespace sysdig-shield-prod
```

## Security

### Secrets Management

**NEVER commit secrets to Git.** Use one of these approaches:

#### Option 1: Sealed Secrets
```bash
kubectl create secret generic sysdig-agent \
  --from-literal=access-key=YOUR_KEY \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > manifests/sealed-secret.yaml
```

#### Option 2: External Secrets Operator
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: sysdig-agent
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: sysdig-agent
  data:
  - secretKey: access-key
    remoteRef:
      key: sysdig/access-key
```

#### Option 3: ArgoCD Vault Plugin
Configure ArgoCD to inject secrets from HashiCorp Vault at deployment time.

### RBAC

Sysdig Shield requires cluster-level permissions. Review and adjust RBAC manifests in `manifests/rbac/` to meet your security requirements.

## Monitoring

Monitor the health of Sysdig Shield components:

```bash
# Check all pods
kubectl get pods -n sysdig-shield -w

# View agent logs
kubectl logs -f daemonset/sysdig-agent -n sysdig-shield

# Check admission controller
kubectl logs -f deployment/sysdig-admission-controller -n sysdig-shield

# ArgoCD health status
argocd app get sysdig-shield --show-health
```

## Troubleshooting

### Agent Not Connecting

```bash
# Verify access key
kubectl get secret sysdig-agent -n sysdig-shield -o jsonpath='{.data.access-key}' | base64 -d

# Check network connectivity
kubectl exec -it daemonset/sysdig-agent -n sysdig-shield -- \
  curl -v https://app.sysdigcloud.com/api/ping
```

### Admission Controller Blocking Deployments

```bash
# Check webhook status
kubectl get validatingwebhookconfigurations
kubectl get mutatingwebhookconfigurations

# Review policies
kubectl get sysdigpolicies -A

# Temporarily disable (emergency only)
kubectl delete validatingwebhookconfiguration sysdig-admission-controller
```

### ArgoCD Sync Issues

```bash
# View sync status and events
argocd app get sysdig-shield --show-events

# Manual sync with force
argocd app sync sysdig-shield --force --prune

# Refresh and hard refresh
argocd app diff sysdig-shield
argocd app sync sysdig-shield --force --replace
```

## Upgrading

### Update Sysdig Components

1. Update image tags or Helm chart versions in manifests
2. Commit changes to Git
3. ArgoCD will automatically sync (if auto-sync enabled)
4. Monitor rollout:

```bash
argocd app sync sysdig-shield
argocd app wait sysdig-shield --health
```

### Rollback

```bash
# View history
argocd app history sysdig-shield

# Rollback to specific revision
argocd app rollback sysdig-shield <REVISION>
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/improvement`)
3. Make your changes
4. Test in development environment
5. Commit your changes (`git commit -am 'Add new feature'`)
6. Push to the branch (`git push origin feature/improvement`)
7. Create a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Resources

- [Sysdig Documentation](https://docs.sysdig.com/)
- [Sysdig Helm Charts Repository](https://github.com/sysdiglabs/charts)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)

## Support

For issues and questions:
- **Sysdig Support**: https://support.sysdig.com
- **GitHub Issues**: https://github.com/yourusername/sysdig-shield-argocd/issues
- **Community**: Join the #sysdig channel on Kubernetes Slack

---

**Maintained by**: Nick Bourke
**Last Updated**: 2026-02-18
