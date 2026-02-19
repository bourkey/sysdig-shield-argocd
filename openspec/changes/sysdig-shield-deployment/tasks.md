## 1. Repository Structure Setup

- [x] 1.1 Create directory structure: argocd-apps/, manifests/, kustomize/, helm-values/, docs/, secrets/, test/
- [x] 1.2 Create .gitignore to exclude secrets/ directory and any plaintext credentials
- [x] 1.3 Create kustomize/base/ directory for common manifests
- [x] 1.4 Create kustomize/overlays/{dev,staging,production}/ directories
- [x] 1.5 Update repository README.md with project overview and quick start guide

## 2. Namespace and Base Resources (Sync Wave 0)

- [x] 2.1 Create manifests/00-namespace.yaml defining sysdig-shield namespace
- [x] 2.2 Add sync wave annotation (argocd.argoproj.io/sync-wave: "0") to namespace
- [x] 2.3 Add namespace labels for monitoring and management
- [x] 2.4 Copy namespace manifest to kustomize/base/

## 3. RBAC Configuration (Sync Wave 1)

- [x] 3.1 Create manifests/rbac/sysdig-agent-serviceaccount.yaml
- [x] 3.2 Create manifests/rbac/sysdig-agent-clusterrole.yaml with read-only permissions (pods, nodes, namespaces, services, events)
- [x] 3.3 Create manifests/rbac/sysdig-agent-clusterrolebinding.yaml
- [x] 3.4 Create manifests/rbac/admission-controller-serviceaccount.yaml
- [x] 3.5 Create manifests/rbac/admission-controller-clusterrole.yaml with webhook and policy permissions
- [x] 3.6 Create manifests/rbac/admission-controller-clusterrolebinding.yaml
- [x] 3.7 Create manifests/rbac/node-analyzer-serviceaccount.yaml
- [x] 3.8 Create manifests/rbac/node-analyzer-clusterrole.yaml with node access
- [x] 3.9 Create manifests/rbac/node-analyzer-clusterrolebinding.yaml
- [x] 3.10 Create manifests/rbac/kspm-collector-serviceaccount.yaml
- [x] 3.11 Create manifests/rbac/kspm-collector-clusterrole.yaml with comprehensive read access
- [x] 3.12 Create manifests/rbac/kspm-collector-clusterrolebinding.yaml
- [x] 3.13 Add sync wave annotation (argocd.argoproj.io/sync-wave: "1") to all RBAC resources
- [x] 3.14 Verify no wildcard permissions (*) in any ClusterRole
- [x] 3.15 Copy RBAC manifests to kustomize/base/rbac/

## 4. Secrets Management Setup (Sync Wave 2)

- [x] 4.1 Create secrets/README.md documenting three secret management approaches
- [x] 4.2 Create secrets/external-secrets/secret-store.yaml example for AWS Secrets Manager
- [x] 4.3 Create secrets/external-secrets/external-secret-sysdig-agent.yaml referencing access key
- [x] 4.4 Create secrets/external-secrets/secret-store-vault.yaml example for HashiCorp Vault
- [x] 4.5 Create secrets/sealed-secrets/sealed-secret-example.yaml with instructions
- [x] 4.6 Create secrets/argocd-vault-plugin/secret-with-placeholders.yaml example
- [x] 4.7 Create secrets/cert-manager/certificate.yaml for admission controller TLS
- [x] 4.8 Add sync wave annotation (argocd.argoproj.io/sync-wave: "2") to secret resources
- [x] 4.9 Document secret validation steps in secrets/README.md

## 5. Sysdig Agent DaemonSet (Sync Wave 3)

- [x] 5.1 Create manifests/sysdig-agent/configmap.yaml with agent configuration (log level, tags, collector URL)
- [x] 5.2 Create manifests/sysdig-agent/daemonset.yaml with hostPath mounts (/var/run/docker.sock, /proc)
- [x] 5.3 Configure privileged security context with hostPID and hostNetwork
- [x] 5.4 Set resource requests (500m CPU, 512Mi memory) and limits (1000m CPU, 1Gi memory)
- [x] 5.5 Add volume mounts for agent configuration and host filesystem access
- [x] 5.6 Configure environment variables for Sysdig backend and access key (from Secret)
- [x] 5.7 Add readiness and liveness probes for agent health checks
- [x] 5.8 Add sync wave annotation (argocd.argoproj.io/sync-wave: "3")
- [x] 5.9 Configure tolerations to run on all nodes including master/control-plane
- [x] 5.10 Copy Sysdig Agent manifests to kustomize/base/sysdig-agent/

## 6. Node Analyzer DaemonSet (Sync Wave 3)

- [x] 6.1 Create manifests/node-analyzer/configmap.yaml with analyzer configuration
- [x] 6.2 Create manifests/node-analyzer/daemonset.yaml with container runtime socket mounts
- [x] 6.3 Add volume mounts for CRI-O (/var/run/crio/crio.sock) and containerd (/run/containerd/containerd.sock)
- [x] 6.4 Set resource requests (250m CPU, 256Mi memory) and limits (500m CPU, 512Mi memory)
- [x] 6.5 Configure environment variables for image scanning and compliance checks
- [x] 6.6 Add readiness and liveness probes
- [x] 6.7 Add sync wave annotation (argocd.argoproj.io/sync-wave: "3")
- [x] 6.8 Configure node selectors if needed for specific node pools
- [x] 6.9 Copy Node Analyzer manifests to kustomize/base/node-analyzer/

## 7. Admission Controller Deployment (Sync Wave 4)

- [x] 7.1 Create manifests/admission-controller/configmap.yaml with policy configuration
- [x] 7.2 Create manifests/admission-controller/deployment.yaml with 3 replicas
- [x] 7.3 Configure pod anti-affinity to spread replicas across nodes
- [x] 7.4 Set resource requests (200m CPU, 256Mi memory) and limits (500m CPU, 512Mi memory)
- [x] 7.5 Add readiness and liveness probes on webhook port
- [x] 7.6 Configure TLS certificate volume from Secret
- [x] 7.7 Create manifests/admission-controller/service.yaml exposing webhook port 443
- [x] 7.8 Create manifests/admission-controller/poddisruptionbudget.yaml (maxUnavailable: 1)
- [x] 7.9 Add sync wave annotation (argocd.argoproj.io/sync-wave: "4") to deployment, service, PDB
- [x] 7.10 Copy Admission Controller manifests to kustomize/base/admission-controller/

## 8. Admission Controller Webhook Configuration (Sync Wave 5)

- [x] 8.1 Create manifests/admission-controller/validatingwebhookconfiguration.yaml
- [x] 8.2 Configure webhook to intercept pod create/update operations
- [x] 8.3 Set failurePolicy to "Ignore" (change to "Fail" after validation in production)
- [x] 8.4 Add namespace exclusions for kube-system, kube-public, sysdig-shield
- [x] 8.5 Configure webhook timeout (10 seconds)
- [x] 8.6 Reference admission controller service and TLS CA bundle
- [x] 8.7 Add sync wave annotation (argocd.argoproj.io/sync-wave: "5")
- [x] 8.8 Copy webhook configuration to kustomize/base/admission-controller/

## 9. KSPM Collector Deployment (Sync Wave 4)

- [x] 9.1 Create manifests/kspm-collector/configmap.yaml with compliance benchmark settings
- [x] 9.2 Create manifests/kspm-collector/deployment.yaml with 2 replicas
- [x] 9.3 Configure pod anti-affinity for high availability
- [x] 9.4 Set resource requests (100m CPU, 128Mi memory) and limits (300m CPU, 256Mi memory)
- [x] 9.5 Add readiness and liveness probes
- [x] 9.6 Configure environment variables for Kubernetes API access and Sysdig backend
- [x] 9.7 Add sync wave annotation (argocd.argoproj.io/sync-wave: "4")
- [x] 9.8 Copy KSPM Collector manifests to kustomize/base/kspm-collector/

## 10. Network Policies

- [x] 10.1 Create manifests/network-policies/default-deny.yaml for sysdig-shield namespace
- [x] 10.2 Create manifests/network-policies/sysdig-agent-egress.yaml (allow to Sysdig backend and API server)
- [x] 10.3 Create manifests/network-policies/admission-controller-ingress.yaml (allow from API server)
- [x] 10.4 Create manifests/network-policies/admission-controller-egress.yaml (allow to Sysdig backend and registries)
- [x] 10.5 Create manifests/network-policies/node-analyzer-egress.yaml (allow to Sysdig backend and registries)
- [x] 10.6 Create manifests/network-policies/kspm-collector-egress.yaml (allow to Sysdig backend and API server)
- [x] 10.7 Create manifests/network-policies/dns-egress.yaml (allow DNS on port 53 UDP/TCP)
- [x] 10.8 Add sync wave annotation (argocd.argoproj.io/sync-wave: "2") to network policies
- [x] 10.9 Copy network policies to kustomize/base/network-policies/

## 11. Kustomize Base Configuration

- [x] 11.1 Create kustomize/base/kustomization.yaml listing all resources
- [x] 11.2 Add namespace: sysdig-shield to kustomization.yaml
- [x] 11.3 Add commonLabels: app.kubernetes.io/name: sysdig-shield, app.kubernetes.io/managed-by: argocd
- [x] 11.4 Group resources by sync wave in kustomization.yaml comments
- [x] 11.5 Validate base with: kubectl kustomize kustomize/base/

## 12. Dev Environment Overlay

- [x] 12.1 Create kustomize/overlays/dev/kustomization.yaml referencing base
- [x] 12.2 Create kustomize/overlays/dev/admission-controller-patch.yaml (replicas: 1)
- [x] 12.3 Create kustomize/overlays/dev/kspm-collector-patch.yaml (replicas: 1)
- [x] 12.4 Create kustomize/overlays/dev/sysdig-agent-resources-patch.yaml (low resources: 100m CPU, 256Mi memory)
- [x] 12.5 Create kustomize/overlays/dev/admission-controller-resources-patch.yaml (low resources)
- [x] 12.6 Create kustomize/overlays/dev/node-analyzer-resources-patch.yaml (low resources)
- [x] 12.7 Create kustomize/overlays/dev/configmap-patch.yaml (log level: debug)
- [x] 12.8 Remove PodDisruptionBudget and anti-affinity rules in dev patches
- [x] 12.9 Validate dev overlay with: kubectl kustomize kustomize/overlays/dev/

## 13. Staging Environment Overlay

- [x] 13.1 Create kustomize/overlays/staging/kustomization.yaml referencing base
- [x] 13.2 Create kustomize/overlays/staging/admission-controller-patch.yaml (replicas: 2)
- [x] 13.3 Create kustomize/overlays/staging/kspm-collector-patch.yaml (replicas: 2)
- [x] 13.4 Create kustomize/overlays/staging/sysdig-agent-resources-patch.yaml (moderate resources: 300m CPU, 384Mi memory)
- [x] 13.5 Create kustomize/overlays/staging/admission-controller-resources-patch.yaml (moderate resources)
- [x] 13.6 Create kustomize/overlays/staging/node-analyzer-resources-patch.yaml (moderate resources)
- [x] 13.7 Create kustomize/overlays/staging/configmap-patch.yaml (log level: info)
- [x] 13.8 Validate staging overlay with: kubectl kustomize kustomize/overlays/staging/

## 14. Production Environment Overlay

- [x] 14.1 Create kustomize/overlays/production/kustomization.yaml referencing base
- [x] 14.2 Create kustomize/overlays/production/admission-controller-patch.yaml (replicas: 3)
- [x] 14.3 Create kustomize/overlays/production/kspm-collector-patch.yaml (replicas: 2)
- [x] 14.4 Create kustomize/overlays/production/sysdig-agent-resources-patch.yaml (high resources: 500m CPU, 512Mi memory)
- [x] 14.5 Create kustomize/overlays/production/admission-controller-resources-patch.yaml (high resources)
- [x] 14.6 Create kustomize/overlays/production/node-analyzer-resources-patch.yaml (high resources)
- [x] 14.7 Create kustomize/overlays/production/configmap-patch.yaml (log level: warning)
- [x] 14.8 Create kustomize/overlays/production/webhook-failurepolicy-patch.yaml (change to Fail after validation)
- [ ] 14.9 Add HorizontalPodAutoscaler for admission controller (optional)
- [x] 14.10 Validate production overlay with: kubectl kustomize kustomize/overlays/production/

## 15. ArgoCD Applications

- [x] 15.1 Create argocd-apps/sysdig-shield-base.yaml (main application for base)
- [x] 15.2 Create argocd-apps/sysdig-shield-dev.yaml referencing kustomize/overlays/dev
- [x] 15.3 Configure dev app with automated sync, prune, and selfHeal
- [x] 15.4 Create argocd-apps/sysdig-shield-staging.yaml referencing kustomize/overlays/staging
- [x] 15.5 Configure staging app with automated sync
- [x] 15.6 Create argocd-apps/sysdig-shield-production.yaml referencing kustomize/overlays/production
- [x] 15.7 Configure production app with manual sync (no automated)
- [x] 15.8 Add health checks for DaemonSets (check pods on all nodes)
- [x] 15.9 Add health checks for Deployments (check replicas ready)
- [x] 15.10 Add health checks for admission controller webhook (check endpoint responding)
- [x] 15.11 Configure sync waves in ArgoCD application manifests
- [ ] 15.12 Add notification annotations for sync events

## 16. Helm Integration (Optional)

- [x] 16.1 Create helm-values/base-values.yaml for sysdig/shield Helm chart
- [x] 16.2 Configure cluster_config and sysdig_endpoint in base values
- [x] 16.3 Enable/disable features (admission_control, posture, vulnerability_management, etc.)
- [x] 16.4 Create helm-values/dev-values.yaml with dev-specific overrides
- [x] 16.5 Create helm-values/staging-values.yaml with staging-specific overrides
- [x] 16.6 Create helm-values/production-values.yaml with production-specific overrides
- [x] 16.7 Pin Helm chart version in ArgoCD application or values file
- [x] 16.8 Document Helm + Kustomize workflow in docs/helm-integration.md
- [x] 16.9 Create example: helm template | kubectl kustomize for hybrid approach

## 17. Documentation

- [x] 17.1 Create docs/installation.md with step-by-step deployment instructions
- [x] 17.2 Document prerequisites (ArgoCD, K8s version, Sysdig account)
- [x] 17.3 Create docs/secrets-management.md with detailed setup for all three approaches
- [x] 17.4 Document External Secrets Operator setup with AWS/Vault examples
- [x] 17.5 Document Sealed Secrets setup with kubeseal examples
- [x] 17.6 Document ArgoCD Vault Plugin configuration
- [x] 17.7 Create docs/configuration.md documenting all ConfigMap and environment variables
- [x] 17.8 Create docs/troubleshooting.md with common issues and solutions
- [x] 17.9 Document admission controller blocking issues and bypass procedures
- [x] 17.10 Document network connectivity troubleshooting
- [x] 17.11 Create docs/upgrade.md with upgrade procedures and rollback steps
- [x] 17.12 Create docs/maintenance.md with RBAC review, secret rotation, and monitoring guidance
- [x] 17.13 Update main README.md with architecture diagram and quick links

## 18. Testing and Validation

- [x] 18.1 Create test/sample-deployment.yaml for testing admission controller
- [x] 18.2 Create test/policy-violation.yaml with known vulnerabilities for testing blocking
- [ ] 18.3 Create test/connectivity-test.yaml for verifying Sysdig backend connectivity
- [x] 18.4 Create test/validate-rbac.sh script to audit RBAC permissions
- [x] 18.5 Create test/validate-network-policies.sh script to test network isolation
- [ ] 18.6 Document pre-deployment validation steps in docs/testing.md
- [ ] 18.7 Document post-deployment verification steps (pod status, agent connectivity, webhook)
- [ ] 18.8 Create test/rollback-test.md with rollback validation procedures
- [ ] 18.9 Test deployment to dev environment and verify all components healthy
- [ ] 18.10 Test admission controller in audit mode, then enforce mode
- [ ] 18.11 Test staging deployment and validate production-like behavior
- [ ] 18.12 Perform dry-run for production deployment and review all manifests

## 19. Security Hardening

- [x] 19.1 Review all RBAC policies to ensure least privilege (no wildcards)
- [x] 19.2 Verify no plaintext secrets in Git repository
- [ ] 19.3 Enable admission controller in enforce mode (failurePolicy: Fail) after validation
- [ ] 19.4 Verify network policies block unauthorized traffic
- [x] 19.5 Configure pod security standards (restricted) for sysdig-shield namespace
- [x] 19.6 Add security context constraints for components
- [ ] 19.7 Enable audit logging for admission controller decisions
- [x] 19.8 Document security review checklist in docs/security.md

## 20. Operational Readiness

- [ ] 20.1 Set up monitoring for Sysdig component health (Prometheus/Grafana)
- [ ] 20.2 Configure alerts for agent disconnections, webhook failures, pod crashes
- [x] 20.3 Create runbook for emergency admission controller bypass
- [x] 20.4 Document incident response procedures in docs/incident-response.md
- [x] 20.5 Schedule quarterly RBAC and network policy reviews
- [x] 20.6 Set up secret rotation schedule and automation
- [ ] 20.7 Configure backup and disaster recovery procedures
- [ ] 20.8 Document on-call procedures and escalation paths
