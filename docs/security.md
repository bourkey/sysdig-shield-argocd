# Security Hardening Checklist

## Pre-Production Security Review

### ✅ RBAC
- [ ] No wildcard permissions in ClusterRoles
- [ ] ServiceAccounts use least privilege
- [ ] Regular RBAC audits scheduled

### ✅ Secrets
- [ ] No plaintext secrets in Git
- [ ] Secrets encrypted at rest
- [ ] Secret rotation enabled
- [ ] Access logging configured

### ✅ Network Policies
- [ ] Default deny policy active
- [ ] Component policies tested
- [ ] DNS egress working
- [ ] Unauthorized traffic blocked

### ✅ Admission Controller
- [ ] Policies tested in audit mode
- [ ] failurePolicy appropriate (Ignore for rollout, Fail after validation)
- [ ] Namespace exclusions configured
- [ ] High availability (3+ replicas)

### ✅ Pod Security
- [ ] Non-root containers where possible
- [ ] Resource limits set
- [ ] Security contexts configured
- [ ] Pod Security Standards enforced

### ✅ Compliance
- [ ] CIS Kubernetes Benchmark passed
- [ ] KSPM collector active
- [ ] Audit logging enabled
- [ ] Compliance reports reviewed

## Security Incident Response

### Admission Controller Compromise
```bash
# Emergency: Delete webhook
kubectl delete validatingwebhookconfiguration sysdig-admission-controller

# Investigate and redeploy
argocd app sync sysdig-shield-production
```

### Suspected Agent Compromise
```bash
# Isolate: Delete DaemonSet
kubectl delete daemonset sysdig-agent -n sysdig-shield

# Investigate logs and redeploy
```

## Regular Security Tasks

- **Weekly**: Review Sysdig alerts and incidents
- **Monthly**: Update component images
- **Quarterly**: RBAC and network policy audit
- **Annually**: Comprehensive security review
