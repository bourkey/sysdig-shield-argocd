# Incident Response Procedures

## Emergency Contacts
- Platform Team: [contact-info]
- Security Team: [contact-info]
- Sysdig Support: https://support.sysdig.com

## Critical Incidents

### Admission Controller Blocking All Deployments

**Severity**: P1 - Production Impact

**Immediate Actions**:
```bash
# 1. Emergency bypass (removes webhook)
kubectl delete validatingwebhookconfiguration sysdig-admission-controller

# 2. Notify team
# 3. Investigate root cause
kubectl logs -f deployment/sysdig-admission-controller -n sysdig-shield

# 4. Fix and redeploy
argocd app sync sysdig-shield-production
```

### Agent Connectivity Loss

**Severity**: P2 - Monitoring Blind Spot

**Actions**:
```bash
# 1. Check agent status
kubectl get pods -n sysdig-shield -l app.kubernetes.io/name=sysdig-agent

# 2. Review logs
kubectl logs daemonset/sysdig-agent -n sysdig-shield

# 3. Verify network connectivity
# 4. Check secrets validity
```

### Resource Exhaustion

**Severity**: P2 - Performance Degradation

**Actions**:
```bash
# 1. Check resource usage
kubectl top pods -n sysdig-shield
kubectl top nodes

# 2. Adjust resource limits in overlays
# 3. Commit and sync changes
```

## Escalation Path

1. **L1**: On-call engineer (immediate response)
2. **L2**: Platform team lead (within 30 minutes)
3. **L3**: Security team (critical security issues)
4. **L4**: Sysdig Support (vendor escalation)

## Post-Incident Review

After resolving any P1/P2 incident:
1. Document timeline and actions taken
2. Identify root cause
3. Implement preventive measures
4. Update runbooks
5. Schedule team retrospective
