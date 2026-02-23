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
│  ├── kustomize/            (Environment Overlays)           │
│  ├── secrets/              (Secrets Management Templates)   │
│  ├── test/                 (Test Manifests & Procedures)    │
│  └── docs/                 (Operational Documentation)      │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ GitOps Sync
                     ▼
┌─────────────────────────────────────────────────────────────┐
│                      ArgoCD                                  │
│  - Monitors Git repository                                   │
│  - Syncs desired state to clusters                          │
│  - Provides UI/CLI for management                           │
│  - Sends Slack notifications for sync events                │
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
│  │ • Admission Controller (Deployment + HPA)    │           │
│  │ • Node Analyzer (DaemonSet)                  │           │
│  │ • KSPM Collector (Deployment)                │           │
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
# Deploy to dev (automated sync)
argocd app create -f argocd-apps/sysdig-shield-dev.yaml

# Deploy to staging (automated sync)
argocd app create -f argocd-apps/sysdig-shield-staging.yaml

# Deploy to production (manual sync)
argocd app create -f argocd-apps/sysdig-shield-production.yaml
argocd app sync sysdig-shield-production
```

### 4. Verify Deployment

```bash
# Check ArgoCD application status
argocd app get sysdig-shield-production

# Verify pods are running
kubectl get pods -n sysdig-shield

# Run backend connectivity test
kubectl apply -f test/connectivity-test.yaml
kubectl wait --for=condition=complete job/sysdig-connectivity-test -n sysdig-shield --timeout=60s
kubectl logs -n sysdig-shield job/sysdig-connectivity-test
kubectl delete -f test/connectivity-test.yaml
```

## Repository Structure

```
.
├── argocd-apps/                      # ArgoCD Application definitions
│   ├── sysdig-shield-base.yaml       # Base application template
│   ├── sysdig-shield-dev.yaml        # Dev application (auto-sync, Slack notifications)
│   ├── sysdig-shield-staging.yaml    # Staging application (auto-sync, Slack notifications)
│   └── sysdig-shield-production.yaml # Production application (manual sync, custom health)
│
├── manifests/                        # Kubernetes manifests (direct apply)
│   ├── 00-namespace.yaml
│   ├── sysdig-agent/
│   ├── admission-controller/         # Includes HPA and audit logging config
│   ├── node-analyzer/
│   ├── kspm-collector/
│   ├── rbac/
│   └── network-policies/
│
├── helm-values/                      # Helm values files
│   ├── base-values.yaml
│   ├── dev-values.yaml
│   ├── staging-values.yaml
│   └── production-values.yaml
│
├── kustomize/                        # Kustomize overlays
│   ├── base/                         # Base configuration for all environments
│   └── overlays/
│       ├── dev/
│       ├── staging/
│       └── production/               # Includes HPA for admission controller
│
├── secrets/                          # Secrets management templates (no plaintext secrets)
│   ├── README.md
│   ├── sealed-secrets/
│   ├── external-secrets/
│   └── argocd-vault-plugin/
│
├── test/                             # Test manifests and validation procedures
│   ├── connectivity-test.yaml        # Job to verify Sysdig backend connectivity
│   ├── sample-deployment.yaml        # Compliant deployment for AC testing
│   ├── policy-violation.yaml         # Policy violation test case
│   ├── rollback-test.md              # Rollback validation procedures
│   ├── validate-rbac.sh              # RBAC validation script
│   └── validate-network-policies.sh  # Network policy validation script
│
└── docs/                             # Operational documentation
    ├── installation.md               # Step-by-step installation guide
    ├── configuration.md              # Environment variables and ConfigMap settings
    ├── helm-integration.md           # Helm chart usage and feature reference
    ├── testing.md                    # Pre/post deployment validation procedures
    ├── monitoring.md                 # Prometheus/Grafana setup and alert rules
    ├── maintenance.md                # Backup/DR procedures and on-call runbooks
    ├── security.md                   # Security hardening checklist
    ├── troubleshooting.md            # Common issues and solutions
    ├── incident-response.md          # P1/P2 incident procedures and escalation
    └── upgrade.md                    # Upgrade and rollback procedures
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
  --dest-namespace sysdig-shield

# Deploy to production
argocd app create sysdig-shield-production \
  --path kustomize/overlays/production \
  --dest-namespace sysdig-shield
```

### Environment Differences

| Feature | Dev | Staging | Production |
|---------|-----|---------|------------|
| Sync | Automated | Automated | Manual |
| Webhook failurePolicy | Ignore | Ignore | Fail |
| AC replicas | 1 | 2 | 3 (min) |
| HPA | No | No | Yes (3-8 replicas) |
| PodDisruptionBudget | No | No | Yes |
| Slack notifications | Yes | Yes | Yes |
| Audit logging | Yes | Yes | Yes |

## Admission Controller

The admission controller is configured with audit logging enabled across all environments. The audit log records admission decisions to `/var/log/sysdig/admission-controller-audit.log`.

In production, the admission controller uses `failurePolicy: Fail` (enforcing) and is backed by a HorizontalPodAutoscaler that scales between 3 and 8 replicas based on CPU (70%) and memory (80%) utilization.

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

Templates for all three approaches are provided in the `secrets/` directory.

### RBAC

Sysdig Shield requires cluster-level permissions. Review and adjust RBAC manifests in `manifests/rbac/` to meet your security requirements.

## Monitoring

Monitor the health of Sysdig Shield components using Prometheus and Grafana. Component metrics are exposed on the following ports:

| Component | Port | Path |
|-----------|------|------|
| sysdig-agent | 24231 | /metrics |
| admission-controller | 8080 | /metrics |
| node-analyzer | 8080 | /metrics |
| kspm-collector | 8080 | /metrics |

For full Prometheus alert rules and Grafana dashboard configuration, see [docs/monitoring.md](docs/monitoring.md).

```bash
# Check all pods
kubectl get pods -n sysdig-shield -w

# View agent logs
kubectl logs -f daemonset/sysdig-agent -n sysdig-shield

# Check admission controller
kubectl logs -f deployment/sysdig-admission-controller -n sysdig-shield

# ArgoCD health status
argocd app list | grep sysdig
```

## Testing

### Pre-Deployment Validation

```bash
# Validate manifests
kubectl apply -f manifests/ --dry-run=server --recursive

# Validate a Kustomize overlay
kubectl kustomize kustomize/overlays/production/ | kubectl apply --dry-run=server -f -

# Validate Helm values
helm template sysdig sysdig/shield \
  -f helm-values/base-values.yaml \
  -f helm-values/production-values.yaml | kubectl apply --dry-run=server -f -

# Run RBAC validation
bash test/validate-rbac.sh

# Run network policy validation
bash test/validate-network-policies.sh

# Test backend connectivity
kubectl apply -f test/connectivity-test.yaml
kubectl wait --for=condition=complete job/sysdig-connectivity-test -n sysdig-shield --timeout=60s
kubectl logs -n sysdig-shield job/sysdig-connectivity-test
kubectl delete -f test/connectivity-test.yaml
```

For complete pre/post deployment validation procedures, see [docs/testing.md](docs/testing.md).

For rollback validation procedures, see [test/rollback-test.md](test/rollback-test.md).

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
argocd app get sysdig-shield-production --show-events

# Manual sync with force
argocd app sync sysdig-shield-production --force --prune

# Refresh and hard refresh
argocd app diff sysdig-shield-production
argocd app sync sysdig-shield-production --force --replace
```

See [docs/troubleshooting.md](docs/troubleshooting.md) for the full troubleshooting guide.

## Upgrading

### Update Sysdig Components

1. Update image tags or Helm chart versions in manifests
2. Commit changes to Git
3. ArgoCD will automatically sync dev/staging (if auto-sync enabled)
4. Monitor rollout:

```bash
argocd app sync sysdig-shield-production
argocd app wait sysdig-shield-production --health
```

### Rollback

```bash
# View history
argocd app history sysdig-shield-production

# Rollback to specific revision
argocd app rollback sysdig-shield-production <REVISION>
```

See [docs/upgrade.md](docs/upgrade.md) for full upgrade procedures and [test/rollback-test.md](test/rollback-test.md) for rollback validation.

## Documentation

| Document | Description |
|----------|-------------|
| [docs/installation.md](docs/installation.md) | Step-by-step installation guide |
| [docs/configuration.md](docs/configuration.md) | ConfigMap and environment variable reference |
| [docs/helm-integration.md](docs/helm-integration.md) | Helm chart usage and feature configuration |
| [docs/testing.md](docs/testing.md) | Pre/post deployment validation procedures |
| [docs/monitoring.md](docs/monitoring.md) | Prometheus metrics, alert rules, and Grafana dashboards |
| [docs/maintenance.md](docs/maintenance.md) | Backup/DR procedures and on-call runbooks |
| [docs/security.md](docs/security.md) | Security hardening checklist |
| [docs/troubleshooting.md](docs/troubleshooting.md) | Common issues and diagnostic commands |
| [docs/incident-response.md](docs/incident-response.md) | P1/P2 incident procedures and escalation paths |
| [docs/upgrade.md](docs/upgrade.md) | Upgrade and rollback procedures |

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
**Last Updated**: 2026-02-23
