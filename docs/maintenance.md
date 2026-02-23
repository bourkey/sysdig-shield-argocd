# Maintenance Guide

## Regular Maintenance Tasks

### Quarterly Reviews
- **RBAC Audit**: Review and remove unused permissions
- **Secret Rotation**: Rotate Sysdig access keys
- **Network Policy Review**: Verify policies are still appropriate

### Monthly Tasks
- Update Sysdig component images to latest versions
- Review admission controller policies
- Check resource usage and adjust limits if needed

## Secret Rotation

### Rotate Sysdig Access Key
```bash
# 1. Generate new key in Sysdig portal
# 2. Update secret in external store or create new sealed secret
# 3. Restart components
kubectl rollout restart daemonset/sysdig-agent -n sysdig-shield
```

### Rotate TLS Certificates
cert-manager handles automatic rotation. Verify:
```bash
kubectl get certificate -n sysdig-shield
```

## Monitoring

Set up alerts for:
- Agent disconnections
- Webhook failures
- Pod crashes
- Resource saturation

## Backup and Disaster Recovery

### What to Back Up

Sysdig Shield is fully declarative — all configuration is stored in this Git repository. The primary backup is Git itself.

#### Additional Backup Items

| Item | Location | Backup Method |
|------|----------|---------------|
| Git repository | GitHub/GitLab | Automated mirroring or periodic clone |
| Sysdig access keys | AWS Secrets Manager / Vault | Provider-managed backup |
| TLS certificates | Kubernetes secrets / cert-manager | Backup included with cluster etcd |
| ArgoCD app state | ArgoCD | Backup ArgoCD namespace or use `argocd export` |

### Backup Procedures

#### Repository Backup

```bash
# Mirror the repository to a secondary remote
git remote add backup git@backup-host:org/sysdig-shield-argocd.git
git push backup --mirror

# Or create a local backup bundle
git bundle create sysdig-shield-argocd-$(date +%Y%m%d).bundle --all
```

#### ArgoCD State Export

```bash
# Export all ArgoCD application definitions
argocd app list -o yaml > argocd-apps-backup-$(date +%Y%m%d).yaml

# Export ArgoCD project definitions
argocd proj list -o yaml > argocd-projects-backup-$(date +%Y%m%d).yaml
```

#### Kubernetes Secrets Backup

```bash
# Export secrets (store encrypted, never in plain Git)
kubectl get secrets -n sysdig-shield -o yaml | \
  kubeseal --format yaml > sealed-secrets-backup-$(date +%Y%m%d).yaml
```

### Disaster Recovery

#### Full Cluster Rebuild from Git

If the cluster is lost, redeploy from Git:

```bash
# 1. Install ArgoCD
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Restore secrets from external store
kubectl apply -f secrets/external-secrets/

# 3. Apply ArgoCD applications
kubectl apply -f argocd-apps/

# 4. Wait for sync
argocd app wait sysdig-shield-production --health --timeout 600
```

#### Recovery Time Objectives

| Scenario | RTO | RPO |
|----------|-----|-----|
| Pod failure | < 2 min (auto-heal) | 0 |
| Node failure | < 5 min (reschedule) | 0 |
| Cluster rebuild | < 30 min | 0 (config in Git) |
| Region failure | < 60 min | 0 (config in Git) |

## On-Call Procedures and Escalation

### On-Call Responsibilities

The on-call engineer is responsible for:
- Responding to Sysdig component alerts within SLA
- Performing emergency admission controller bypass if required
- Escalating to vendor support for product bugs

### Alert Response SLAs

| Severity | Response Time | Resolution Time |
|----------|--------------|-----------------|
| Critical (agent down, AC down) | 15 min | 1 hour |
| Warning (high latency, high CPU) | 1 hour | 4 hours |
| Info | Next business day | Next sprint |

### Escalation Path

1. **On-call engineer** — First response, initial triage
2. **Platform team lead** — If not resolved within SLA or requires cluster-wide changes
3. **Sysdig support** — For product bugs: [support.sysdig.com](https://support.sysdig.com)
   - Priority support: Include cluster info and relevant logs
   - Emergency: Use Sysdig emergency support line

### Sysdig Support Information

```bash
# Collect diagnostic bundle for Sysdig support
kubectl exec -n sysdig-shield daemonset/sysdig-agent -- \
  /opt/draios/bin/sysdig-agent-check --bundle

# Check agent version
kubectl exec -n sysdig-shield daemonset/sysdig-agent -- \
  cat /opt/draios/version/sysdig-agent
```

### Common On-Call Runbooks

| Scenario | Runbook |
|----------|---------|
| Agent disconnected | [troubleshooting.md#agent-not-connecting](troubleshooting.md) |
| Admission controller blocking | [troubleshooting.md#admission-controller](troubleshooting.md) |
| Emergency AC bypass | [incident-response.md](incident-response.md) |
| Rollback required | [test/rollback-test.md](../test/rollback-test.md) |
