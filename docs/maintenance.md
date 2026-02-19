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

## Backup

Backup this Git repository regularly. All configuration is declarative and stored in Git.
