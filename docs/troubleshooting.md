# Troubleshooting Guide

## Common Issues

### Sysdig Agent Not Connecting

**Symptoms**: Agent pods running but not reporting to Sysdig backend

**Diagnosis**:
```bash
# Check agent logs
kubectl logs -f daemonset/sysdig-agent -n sysdig-shield

# Verify access key
kubectl get secret sysdig-agent -n sysdig-shield -o jsonpath='{.data.access-key}' | base64 -d

# Test connectivity
kubectl exec -it daemonset/sysdig-agent -n sysdig-shield -- curl -v https://app.sysdigcloud.com/api/ping
```

**Solutions**:
- Verify access key is correct
- Check network policies allow egress to Sysdig backend
- Verify firewall rules allow HTTPS to app.sysdigcloud.com

### Admission Controller Blocking All Deployments

**Symptoms**: All pod creations fail with webhook timeout or rejection

**Emergency Bypass**:
```bash
# Delete webhook configuration (emergency only)
kubectl delete validatingwebhookconfiguration sysdig-admission-controller

# Redeploy after fixing
argocd app sync sysdig-shield-production
```

**Root Causes**:
- Admission controller pods not ready
- TLS certificate issues
- Network policy blocking API server communication

**Solutions**:
```bash
# Check admission controller status
kubectl get pods -n sysdig-shield -l app.kubernetes.io/name=sysdig-admission-controller

# Verify webhook configuration
kubectl describe validatingwebhookconfiguration sysdig-admission-controller

# Check TLS certificate
kubectl get secret sysdig-admission-controller-tls -n sysdig-shield
```

### Network Connectivity Issues

**Symptoms**: Pods can't reach Sysdig backend or each other

**Diagnosis**:
```bash
# Test DNS resolution
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup app.sysdigcloud.com

# Test connectivity
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- curl -v https://app.sysdigcloud.com
```

**Solutions**:
- Review network policies
- Verify DNS egress is allowed
- Check firewall rules

### ArgoCD Sync Failures

**Symptoms**: ArgoCD shows "OutOfSync" or sync fails

**Diagnosis**:
```bash
argocd app get sysdig-shield-production --show-events
argocd app diff sysdig-shield-production
```

**Solutions**:
```bash
# Force sync with prune
argocd app sync sysdig-shield-production --force --prune

# Hard refresh
argocd app sync sysdig-shield-production --force --replace
```

## Performance Issues

### High Resource Usage

Monitor resource consumption:
```bash
kubectl top pods -n sysdig-shield
kubectl top nodes
```

Adjust resource limits in environment overlays.

### Image Scanning Delays

Configure scan caching and rate limiting in node-analyzer ConfigMap.

## Support Resources

- [Sysdig Support Portal](https://support.sysdig.com)
- [Sysdig Documentation](https://docs.sysdig.com)
- GitHub Issues: (this repository)
