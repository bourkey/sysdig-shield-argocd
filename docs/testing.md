# Testing and Validation Guide

## Pre-Deployment Validation

### 1. Validate Manifests with Dry Run

```bash
# Validate all base manifests
kubectl apply -f manifests/ --dry-run=server --recursive

# Validate a specific environment overlay
kubectl kustomize kustomize/overlays/dev/ | kubectl apply --dry-run=server -f -
kubectl kustomize kustomize/overlays/staging/ | kubectl apply --dry-run=server -f -
kubectl kustomize kustomize/overlays/production/ | kubectl apply --dry-run=server -f -
```

### 2. Validate Kustomize Overlays

```bash
# Render and inspect each overlay
kubectl kustomize kustomize/overlays/dev/
kubectl kustomize kustomize/overlays/staging/
kubectl kustomize kustomize/overlays/production/
```

### 3. Validate Helm Values

```bash
# Render and inspect Helm templates
helm template sysdig sysdig/shield \
  -f helm-values/base-values.yaml \
  -f helm-values/dev-values.yaml \
  --debug

# Validate against Kubernetes API
helm template sysdig sysdig/shield \
  -f helm-values/base-values.yaml \
  -f helm-values/production-values.yaml | kubectl apply --dry-run=server -f -
```

### 4. Validate Secrets Configuration

```bash
# Confirm secrets exist (do not print values)
kubectl get secret sysdig-agent -n sysdig-shield
kubectl get secret sysdig-admission-controller-tls -n sysdig-shield

# Verify secret has required keys
kubectl get secret sysdig-agent -n sysdig-shield -o jsonpath='{.data}' | jq 'keys'
```

### 5. Validate RBAC

```bash
# Run the RBAC validation script
bash test/validate-rbac.sh
```

### 6. Validate Network Policies

```bash
# Run the network policy validation script
bash test/validate-network-policies.sh
```

### 7. Test Backend Connectivity

```bash
# Deploy and run the connectivity test job
kubectl apply -f test/connectivity-test.yaml
kubectl wait --for=condition=complete job/sysdig-connectivity-test -n sysdig-shield --timeout=60s
kubectl logs -n sysdig-shield job/sysdig-connectivity-test

# Cleanup
kubectl delete -f test/connectivity-test.yaml
```

---

## Post-Deployment Verification

### 1. Verify All Pods Running

```bash
# Check all pods in the sysdig-shield namespace
kubectl get pods -n sysdig-shield

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod \
  -l app.kubernetes.io/part-of=sysdig-shield \
  -n sysdig-shield \
  --timeout=300s
```

### 2. Verify Agent Connectivity

```bash
# Check agent logs for successful connection
kubectl logs -n sysdig-shield daemonset/sysdig-agent --tail=50 | grep -E "connected|error|warn"

# Check that agents are reporting to Sysdig backend
kubectl exec -n sysdig-shield daemonset/sysdig-agent -- cat /opt/draios/logs/draios.log | tail -20
```

### 3. Verify Admission Controller

```bash
# Check webhook is registered
kubectl get validatingwebhookconfigurations | grep sysdig

# Test webhook with a sample deployment (should be admitted)
kubectl apply -f test/sample-deployment.yaml --dry-run=server

# Test policy violation (should be flagged/blocked in production)
kubectl apply -f test/policy-violation.yaml --dry-run=server

# Check admission controller logs
kubectl logs -n sysdig-shield deployment/sysdig-admission-controller --tail=50
```

### 4. Verify Node Analyzer

```bash
# Check node analyzer is running on all nodes
kubectl get pods -n sysdig-shield -l app.kubernetes.io/component=node-analyzer

# Check scanning activity
kubectl logs -n sysdig-shield daemonset/sysdig-node-analyzer --tail=30
```

### 5. Verify KSPM Collector

```bash
# Check collector pods
kubectl get pods -n sysdig-shield -l app.kubernetes.io/component=kspm-collector

# Verify posture data collection
kubectl logs -n sysdig-shield deployment/sysdig-kspm-collector --tail=30
```

### 6. ArgoCD Sync Status

```bash
# Check all Sysdig applications are synced and healthy
argocd app list | grep sysdig

# Get detailed status
argocd app get sysdig-shield-production
```

---

## Environment-Specific Validation

### Dev Environment

```bash
# Verify admission controller is in dry-run mode
kubectl get configmap sysdig-admission-controller -n sysdig-shield -o yaml | grep dryRun

# Confirm limited features (no drift detection, etc.)
kubectl get pods -n sysdig-shield
```

### Staging Environment

```bash
# Test admission controller in warn mode (failurePolicy: Ignore)
kubectl apply -f test/policy-violation.yaml

# Verify all features active (drift, malware, network security)
kubectl logs -n sysdig-shield daemonset/sysdig-agent | grep -E "drift|malware|policy"
```

### Production Environment

```bash
# Verify admission controller is in enforce mode
kubectl get validatingwebhookconfiguration sysdig-admission-controller-webhook \
  -o jsonpath='{.webhooks[0].failurePolicy}'
# Expected output: Fail

# Verify HPA is active
kubectl get hpa -n sysdig-shield

# Check PodDisruptionBudget
kubectl get pdb -n sysdig-shield
```
