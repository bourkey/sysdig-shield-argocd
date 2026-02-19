# Installation Guide

## Prerequisites

- Kubernetes cluster v1.24+ with RBAC enabled
- ArgoCD v2.8+ installed and configured
- kubectl configured to access your cluster
- Sysdig Secure subscription with access key
- (Optional) External Secrets Operator, Sealed Secrets, or Vault for secrets management

## Step-by-Step Installation

### 1. Clone Repository

```bash
git clone https://github.com/yourusername/sysdig-shield-argocd.git
cd sysdig-shield-argocd
```

### 2. Configure Secrets

Choose one of three approaches (see [Secrets Management Guide](secrets-management.md)):

**Option A: External Secrets Operator (Recommended)**
```bash
kubectl apply -f secrets/external-secrets/secret-store.yaml
kubectl apply -f secrets/external-secrets/external-secret-sysdig-agent.yaml
```

**Option B: Create Secret Manually (Testing)**
```bash
kubectl create namespace sysdig-shield
kubectl create secret generic sysdig-agent \
  --from-literal=access-key=YOUR_SYSDIG_ACCESS_KEY \
  -n sysdig-shield
```

### 3. Deploy to Dev Environment

```bash
# Create ArgoCD application
argocd app create -f argocd-apps/sysdig-shield-dev.yaml

# Verify sync
argocd app get sysdig-shield-dev
argocd app wait sysdig-shield-dev --health
```

### 4. Verify Deployment

```bash
# Check pods
kubectl get pods -n sysdig-shield

# Verify agent connectivity
kubectl exec -it daemonset/sysdig-agent -n sysdig-shield -- sysdig-agent-check

# Test admission controller
kubectl run test-pod --image=nginx --dry-run=server
```

### 5. Deploy to Production

After successful dev/staging validation:

```bash
# Create production application (manual sync)
argocd app create -f argocd-apps/sysdig-shield-production.yaml

# Manual sync
argocd app sync sysdig-shield-production
argocd app wait sysdig-shield-production --health
```

## Quick Start (Direct kubectl)

For testing without ArgoCD:

```bash
kubectl apply -k kustomize/overlays/dev/
```

## Next Steps

- [Configuration Guide](configuration.md)
- [Troubleshooting Guide](troubleshooting.md)
- [Security Hardening](../test/validate-rbac.sh)
