# Secrets Management for Sysdig Shield

This directory contains examples and configurations for managing secrets in the Sysdig Shield deployment. **IMPORTANT**: Never commit plaintext secrets to Git.

## Three Supported Approaches

### 1. External Secrets Operator (Recommended)

**Best for**: Organizations with existing secret stores (AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, Azure Key Vault)

**Advantages**:
- Integrates with existing secret infrastructure
- Automatic secret rotation support
- Centralized secret management
- No secrets in Git repository

**Setup**:
1. Install External Secrets Operator in your cluster
2. Create a SecretStore or ClusterSecretStore (see `external-secrets/secret-store.yaml`)
3. Create ExternalSecret resources (see `external-secrets/external-secret-sysdig-agent.yaml`)
4. Operator syncs secrets from external store to Kubernetes Secrets

**Required Secrets**:
- `sysdig-agent`: Sysdig access key
- `sysdig-admission-controller-tls`: TLS certificate and key for webhook

---

### 2. Sealed Secrets

**Best for**: Smaller deployments without external secret infrastructure

**Advantages**:
- Encrypted secrets can be committed to Git
- No external dependencies beyond sealed-secrets controller
- GitOps-friendly

**Setup**:
1. Install sealed-secrets controller in your cluster
2. Use `kubeseal` CLI to encrypt secrets
3. Commit SealedSecret resources to Git (see `sealed-secrets/sealed-secret-example.yaml`)
4. Controller decrypts and creates Kubernetes Secrets

**Example**:
```bash
# Create secret and seal it
kubectl create secret generic sysdig-agent \
  --from-literal=access-key=YOUR_SYSDIG_ACCESS_KEY \
  --dry-run=client -o yaml | \
  kubeseal -o yaml > sealed-secrets/sysdig-agent-sealed.yaml

# Commit sealed secret to Git
git add sealed-secrets/sysdig-agent-sealed.yaml
git commit -m "Add sealed Sysdig access key"
```

---

### 3. ArgoCD Vault Plugin

**Best for**: Organizations using HashiCorp Vault with ArgoCD

**Advantages**:
- Secrets injected at deployment time
- No secrets stored in ArgoCD
- Works with existing Vault infrastructure

**Setup**:
1. Configure ArgoCD with Vault plugin
2. Use placeholders in manifests (see `argocd-vault-plugin/secret-with-placeholders.yaml`)
3. ArgoCD replaces placeholders with actual values from Vault during sync

**Example Placeholder**:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: sysdig-agent
data:
  access-key: <path:secret/data/sysdig#access-key | base64encode>
```

---

## Secret Validation

Before deploying Sysdig Shield, validate your secrets:

### 1. Verify Sysdig Access Key Format
```bash
# Access key should be a UUID or valid API key
kubectl get secret sysdig-agent -n sysdig-shield -o jsonpath='{.data.access-key}' | base64 -d
```

### 2. Test Backend Connectivity
```bash
# Test connection to Sysdig backend
curl -H "Authorization: Bearer $(kubectl get secret sysdig-agent -n sysdig-shield -o jsonpath='{.data.access-key}' | base64 -d)" \
  https://app.sysdigcloud.com/api/ping
```

Expected response: `{"status":"ok"}`

### 3. Verify TLS Certificates
```bash
# Check certificate validity for admission controller
kubectl get secret sysdig-admission-controller-tls -n sysdig-shield -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -dates

# Verify certificate matches service DNS
kubectl get secret sysdig-admission-controller-tls -n sysdig-shield -o jsonpath='{.data.tls\.crt}' | \
  base64 -d | openssl x509 -noout -text | grep DNS
```

Expected DNS: `sysdig-admission-controller.sysdig-shield.svc`

### 4. Pre-Deployment Checklist
- [ ] Sysdig access key created in external secret store or sealed
- [ ] Access key tested against Sysdig backend
- [ ] TLS certificate generated for admission controller
- [ ] Certificate valid for at least 90 days
- [ ] Certificate DNS name matches service: `sysdig-admission-controller.sysdig-shield.svc`
- [ ] No plaintext secrets in Git repository
- [ ] Secret rotation schedule documented

---

## Troubleshooting

### External Secrets Not Syncing
```bash
# Check ExternalSecret status
kubectl describe externalsecret sysdig-agent -n sysdig-shield

# Check SecretStore connectivity
kubectl describe secretstore aws-secrets-manager -n sysdig-shield

# View External Secrets Operator logs
kubectl logs -n external-secrets-system deployment/external-secrets
```

### Sealed Secrets Not Decrypting
```bash
# Verify sealed-secrets controller is running
kubectl get pods -n kube-system -l name=sealed-secrets-controller

# Check controller logs
kubectl logs -n kube-system -l name=sealed-secrets-controller

# Verify SealedSecret was created
kubectl get sealedsecrets -n sysdig-shield
```

### Vault Plugin Issues
```bash
# Check ArgoCD application events
argocd app get sysdig-shield --show-events

# Verify Vault authentication
kubectl exec -it -n argocd deployment/argocd-repo-server -- vault status

# Test Vault path access
vault kv get secret/sysdig
```

---

## Security Best Practices

1. **Never commit plaintext secrets**: Use .gitignore to exclude secrets/ directory
2. **Rotate secrets regularly**: Set up automated rotation (quarterly minimum)
3. **Use least privilege**: Grant minimal IAM/RBAC permissions to secret stores
4. **Audit secret access**: Enable audit logging in Vault/AWS Secrets Manager
5. **Encrypt at rest**: Ensure Kubernetes secrets are encrypted (EncryptionConfiguration)
6. **Monitor for leaks**: Use secret scanning tools (GitGuardian, TruffleHog)

---

## Quick Reference

| Secret Name | Purpose | Required | Format |
|-------------|---------|----------|--------|
| `sysdig-agent` | Sysdig backend authentication | Yes | `access-key`: UUID/API key |
| `sysdig-admission-controller-tls` | Webhook TLS | Yes | `tls.crt`, `tls.key` |

## Additional Resources

- [External Secrets Operator Docs](https://external-secrets.io/)
- [Sealed Secrets GitHub](https://github.com/bitnami-labs/sealed-secrets)
- [ArgoCD Vault Plugin](https://argocd-vault-plugin.readthedocs.io/)
- [Sysdig Secure Documentation](https://docs.sysdig.com/en/sysdig-secure.html)
