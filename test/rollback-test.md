# Rollback Validation Procedures

This document outlines procedures for validating a successful rollback of Sysdig Shield components.

## When to Roll Back

- Admission controller blocking legitimate workloads unexpectedly
- Agent causing node instability (high CPU/memory)
- Policy changes causing too many false positives
- Failed upgrade leaving components in broken state

## Pre-Rollback Checklist

- [ ] Identify the last known good Git commit or Helm chart version
- [ ] Note which components are affected (agent, admission controller, node analyzer, kspm)
- [ ] Check if any secrets or CRDs were modified in the failed deployment
- [ ] Notify stakeholders of maintenance window

## Rollback Procedures

### Option 1: ArgoCD Rollback (GitOps)

```bash
# Identify the last successful sync
argocd app history sysdig-shield-production

# Roll back to a previous revision
argocd app rollback sysdig-shield-production <REVISION_ID>

# Verify rollback status
argocd app get sysdig-shield-production
```

### Option 2: Git Revert + ArgoCD Sync

```bash
# Revert the problematic commit
git revert <COMMIT_SHA>
git push origin main

# Force sync in ArgoCD
argocd app sync sysdig-shield-production --force
```

### Option 3: Emergency Admission Controller Bypass

If the admission controller is blocking deployments during a critical incident:

```bash
# Change failurePolicy to Ignore (allows deployments even if webhook fails)
kubectl patch validatingwebhookconfiguration sysdig-admission-controller-webhook \
  --type='json' \
  -p='[{"op": "replace", "path": "/webhooks/0/failurePolicy", "value": "Ignore"}]'

# Alternatively, disable the webhook temporarily
kubectl delete validatingwebhookconfiguration sysdig-admission-controller-webhook

# Restore after incident resolution
kubectl apply -f manifests/admission-controller/validatingwebhookconfiguration.yaml
```

### Option 4: Helm Rollback

```bash
# List Helm releases
helm list -n sysdig-shield

# Check rollback history
helm history sysdig -n sysdig-shield

# Roll back to previous release
helm rollback sysdig <REVISION> -n sysdig-shield

# Verify rollback
helm status sysdig -n sysdig-shield
```

## Post-Rollback Validation

### 1. Verify Component Health

```bash
# Check all pods are running
kubectl get pods -n sysdig-shield
kubectl wait --for=condition=ready pod -l app.kubernetes.io/part-of=sysdig-shield \
  -n sysdig-shield --timeout=300s
```

### 2. Verify Agent Connectivity

```bash
kubectl logs -n sysdig-shield daemonset/sysdig-agent --tail=30 | grep -E "connected|error"
```

### 3. Verify Admission Controller

```bash
# Confirm webhook is operational
kubectl apply -f test/sample-deployment.yaml --dry-run=server

# Check policy is enforcing correctly
kubectl get validatingwebhookconfiguration sysdig-admission-controller-webhook \
  -o jsonpath='{.webhooks[0].failurePolicy}'
```

### 4. Verify No Data Loss

```bash
# Check agent reporting in Sysdig UI: Integrations > Agents
# Verify posture data: Security > Compliance
# Check recent events: Events > Activity Audit
```

### 5. Run Connectivity Test

```bash
kubectl apply -f test/connectivity-test.yaml
kubectl wait --for=condition=complete job/sysdig-connectivity-test -n sysdig-shield --timeout=60s
kubectl logs -n sysdig-shield job/sysdig-connectivity-test
kubectl delete -f test/connectivity-test.yaml
```

## Rollback Validation Sign-Off

Complete this checklist before closing the rollback incident:

- [ ] All Sysdig pods running and ready
- [ ] Agent connected to Sysdig backend (confirmed in UI)
- [ ] Admission controller admitting legitimate workloads
- [ ] Test deployment passes (`test/sample-deployment.yaml`)
- [ ] Connectivity test passes
- [ ] Incident documented in runbook
- [ ] Post-mortem scheduled if required
