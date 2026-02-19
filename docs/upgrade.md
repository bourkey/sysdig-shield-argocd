# Upgrade Guide

## Upgrade Process

### 1. Update Manifests
```bash
# Update image tags or configuration in manifests
git commit -am "Update Sysdig components to vX.Y.Z"
git push
```

### 2. Sync Changes
```bash
# Dev (auto-sync)
argocd app sync sysdig-shield-dev

# Production (manual)
argocd app sync sysdig-shield-production
```

### 3. Verify Upgrade
```bash
kubectl rollout status daemonset/sysdig-agent -n sysdig-shield
kubectl rollout status deployment/sysdig-admission-controller -n sysdig-shield
```

## Rollback

```bash
# View history
argocd app history sysdig-shield-production

# Rollback
argocd app rollback sysdig-shield-production <REVISION>
```
