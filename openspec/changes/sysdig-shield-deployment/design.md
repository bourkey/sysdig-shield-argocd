## Context

Sysdig Shield is a comprehensive Kubernetes security platform providing runtime threat detection, compliance monitoring (KSPM), image vulnerability scanning, and admission control. It consists of multiple components that must be deployed in a specific order with proper RBAC, networking, and secrets configuration.

**Current State**: Fresh repository with documentation but no deployment manifests. Target is production-ready GitOps deployment using ArgoCD.

**Constraints**:
- Must support multiple environments (dev, staging, production) with different configurations
- Secrets (Sysdig access keys, TLS certs) cannot be committed to Git
- Sysdig Agent runs on every node (DaemonSet) with elevated privileges for kernel-level security monitoring
- Admission controller webhook must be highly available to prevent cluster lockout
- Deployment order matters: namespace → RBAC → secrets → components

**Stakeholders**: Platform team (deployment), security team (policy configuration), application teams (affected by admission policies)

## Goals / Non-Goals

**Goals:**
- Fully automated GitOps deployment via ArgoCD with zero manual kubectl commands
- Multi-environment support with environment-specific configurations (resource limits, replicas, policies)
- Secure secrets management that never commits sensitive data to Git
- Production-ready with health checks, resource limits, and rollback capability
- Clear deployment order using ArgoCD sync waves to prevent race conditions
- Comprehensive documentation for deployment, troubleshooting, and maintenance

**Non-Goals:**
- Sysdig backend/SaaS infrastructure (using existing Sysdig cloud service)
- Custom Sysdig agent or component modifications (using official container images)
- Multi-cluster deployment from single ArgoCD instance (out of scope for initial implementation)
- Custom admission controller policies beyond Sysdig's built-in capabilities
- Migration from existing Sysdig deployments (greenfield only)

## Decisions

### D1: ArgoCD Application Structure

**Decision**: Create a main ArgoCD Application that references Kustomize bases, with environment-specific Applications for overlays.

**Rationale**:
- Single main application (`sysdig-shield`) deploys shared base configuration
- Environment applications (`sysdig-shield-dev`, `sysdig-shield-prod`) apply overlays
- Enables testing in dev before promoting to production
- Supports independent sync policies per environment (auto-sync in dev, manual in prod)

**Alternatives Considered**:
- Single monolithic application: Less flexible for environment-specific sync policies
- Helm-only approach: More complex templating, Kustomize better for strategic merge patches
- App-of-apps pattern: Over-engineering for this use case with 10 capabilities

### D2: Deployment Strategy (Kustomize vs Helm)

**Decision**: Use Kustomize as primary deployment mechanism with optional Helm values integration.

**Rationale**:
- Kustomize native to ArgoCD and kubectl, no additional tooling required
- Strategic merge patches ideal for environment-specific overrides (replicas, resources, node selectors)
- Plain YAML manifests easier to review and debug than Helm templates
- Sysdig provides official Helm charts, but we control the deployment with Kustomize overlays on rendered manifests

**Alternatives Considered**:
- Pure Helm: More abstraction, harder to see actual deployed manifests
- Plain manifests with duplication: Maintenance nightmare across environments
- Jsonnet: Additional learning curve, less community adoption

### D3: Secrets Management Approach

**Decision**: Support three patterns via documentation, default to External Secrets Operator recommendation.

**Patterns**:
1. **External Secrets Operator** (recommended): Sync from AWS Secrets Manager, Vault, or GCP Secret Manager
2. **Sealed Secrets**: Encrypt secrets with kubeseal, commit encrypted form to Git
3. **ArgoCD Vault Plugin**: Inject secrets at sync time from Vault

**Rationale**:
- External Secrets Operator most flexible, works with existing secret stores, supports secret rotation
- Sealed Secrets good for smaller deployments without external secret infrastructure
- Vault Plugin for organizations already using Vault with ArgoCD
- Document all three, users choose based on infrastructure

**Alternatives Considered**:
- Committing secrets to Git: Security violation, not acceptable
- Manual secret creation: Breaks GitOps automation, error-prone
- SOPS: Good but requires GPG/KMS key management, External Secrets more turnkey

### D4: Component Deployment Order (Sync Waves)

**Decision**: Use ArgoCD sync waves with the following order:
- Wave 0: Namespace, CustomResourceDefinitions (if any)
- Wave 1: RBAC (ServiceAccounts, ClusterRoles, ClusterRoleBindings)
- Wave 2: ConfigMaps, Secrets (external secret references)
- Wave 3: Sysdig Agent DaemonSet, Node Analyzer DaemonSet
- Wave 4: Admission Controller Deployment, KSPM Collector Deployment
- Wave 5: Services, ValidatingWebhookConfiguration, MutatingWebhookConfiguration

**Rationale**:
- Prevents race conditions (e.g., pods starting before RBAC exists)
- Agents and node analyzer first to start security monitoring immediately
- Admission controller last to avoid blocking deployments during initial setup
- Webhook configurations after controller is healthy to prevent cluster lockout

**Alternatives Considered**:
- No sync waves: Risk of transient errors, pods crashlooping until dependencies ready
- Different ordering (admission controller first): Could block legitimate deployments during setup

### D5: Multi-Environment Configuration Strategy

**Decision**: Use Kustomize overlays with strategic merge patches for environment-specific values.

**Environment Differences**:
- **Dev**: Low resources (CPU/memory), 1 replica, auto-sync enabled, permissive policies
- **Staging**: Production-like resources, 2 replicas, auto-sync enabled, production policies
- **Production**: High resources with HPA, 3+ replicas, manual sync, strict policies

**Configuration via Overlays**:
```
kustomize/
├── base/                    # Shared manifests
│   ├── namespace.yaml
│   ├── sysdig-agent/
│   ├── admission-controller/
│   └── kustomization.yaml
└── overlays/
    ├── dev/
    │   ├── kustomization.yaml          # patches: replicas=1, resources.requests low
    │   └── sysdig-agent-patch.yaml
    ├── staging/
    │   └── kustomization.yaml          # patches: replicas=2, resources moderate
    └── production/
        └── kustomization.yaml          # patches: replicas=3, resources high, HPA
```

**Rationale**:
- DRY principle: Common configuration in base, only differences in overlays
- Type-safe: Kustomize validates strategic merge patches
- Easy to see environment differences with `kustomize diff`

### D6: Network Policy Design

**Decision**: Implement restrictive network policies with explicit allow rules.

**Policy Design**:
- Sysdig Agent: Egress to Sysdig backend (app.sysdigcloud.com:443), kube-apiserver
- Admission Controller: Ingress from kube-apiserver (webhook calls), egress to Sysdig backend
- Node Analyzer: Egress to Sysdig backend, container registries (for image scanning)
- KSPM Collector: Egress to Sysdig backend, kube-apiserver

**Rationale**:
- Defense in depth: Even if component compromised, network limited
- Compliance requirement: Many security frameworks require network segmentation
- Minimal permissions principle: Only allow required traffic

**Alternatives Considered**:
- No network policies: Security risk, failed compliance audits
- Single permissive policy: Defeats purpose of network segmentation

### D7: Health Check Configuration

**Decision**: Configure custom health checks for ArgoCD with specific readiness criteria.

**Health Checks**:
- Sysdig Agent: DaemonSet with pods running on all schedulable nodes
- Admission Controller: Deployment ready AND webhook endpoint responding
- Node Analyzer: DaemonSet with minimum 80% nodes ready
- KSPM Collector: Deployment ready AND connected to Sysdig backend

**Rationale**:
- ArgoCD default health checks insufficient for complex apps
- Prevent marking application "healthy" when components not functional
- Enable automated rollback on health check failures

### D8: Resource Allocation Strategy

**Decision**: Set both requests and limits for all components with environment-specific values.

**Resource Profile (Production)**:
- Sysdig Agent (per node): CPU 500m-1000m, Memory 512Mi-1Gi
- Admission Controller: CPU 200m-500m, Memory 256Mi-512Mi, 3 replicas
- Node Analyzer (per node): CPU 250m-500m, Memory 256Mi-512Mi
- KSPM Collector: CPU 100m-300m, Memory 128Mi-256Mi, 2 replicas

**Rationale**:
- Requests ensure scheduling and baseline performance
- Limits prevent resource exhaustion and noisy neighbor issues
- Admission controller critical path, needs guaranteed resources
- Agent and node analyzer per-node overhead must be sustainable

**Alternatives Considered**:
- No limits: Risk of resource exhaustion, cluster instability
- Requests only: Better for burstable workloads, but admission controller needs guarantees

## Risks / Trade-offs

### R1: Admission Controller Single Point of Failure
**Risk**: If admission controller fails, all pod deployments blocked (depending on failure policy).

**Mitigation**:
- High availability: 3 replicas with pod anti-affinity
- Failure policy: Configure `failurePolicy: Ignore` during initial rollout, change to `Fail` after stability proven
- Health checks: ArgoCD monitors health, auto-rollback on degradation
- Bypass mechanism: Document emergency procedure to delete ValidatingWebhookConfiguration

### R2: DaemonSet Resource Overhead on All Nodes
**Risk**: Sysdig Agent and Node Analyzer run on every node, consuming ~750m CPU and 768Mi memory per node at minimum.

**Mitigation**:
- Resource limits prevent runaway consumption
- Node selectors in production overlay to exclude specific node pools (if needed)
- Monitoring: Alert on node resource saturation
- Right-size cluster: Factor security overhead into capacity planning

### R3: Secrets Management Complexity
**Risk**: Multiple secrets management options increase documentation burden and user confusion.

**Mitigation**:
- Clear recommendation (External Secrets Operator) with rationale
- Step-by-step guides for each approach
- Working examples in repository
- Pre-flight checks in documentation to verify secrets exist before deployment

### R4: Admission Controller Policy Impact
**Risk**: Overly strict policies block legitimate deployments, too permissive defeats purpose.

**Mitigation**:
- Start with audit mode (log violations, don't block) in dev/staging
- Gradual policy tightening based on audit logs
- Document common policy violations and fixes
- Per-namespace policy exceptions for trusted workloads

### R5: Network Egress Requirements
**Risk**: Firewall rules may block Sysdig backend communication, breaking functionality.

**Mitigation**:
- Document required egress destinations and ports upfront
- Pre-flight connectivity tests in runbook
- Support proxy configuration for environments with egress restrictions
- Monitor connection status via Sysdig agent health checks

### R6: ArgoCD Sync Failures Due to Ordering
**Risk**: Despite sync waves, transient issues during initial deployment or updates.

**Mitigation**:
- Retry logic: Configure ArgoCD retry with backoff
- Health checks: Wait for dependencies before progressing to next wave
- Idempotent manifests: Safe to apply multiple times
- Rollback strategy: Document manual intervention procedures

## Migration Plan

### Pre-Deployment Checklist
1. ArgoCD installed and accessible (v2.8+)
2. Kubernetes cluster meets requirements (v1.24+, RBAC enabled)
3. Sysdig access key obtained from Sysdig portal
4. Secrets management solution chosen and configured
5. Firewall rules allow egress to app.sysdigcloud.com (or regional backend)
6. kubectl access to cluster with cluster-admin privileges

### Deployment Steps

**Phase 1: Secrets Setup** (one-time per cluster)
```bash
# Example for External Secrets Operator
kubectl apply -f secrets/external-secrets/secret-store.yaml
kubectl apply -f secrets/external-secrets/sysdig-access-key.yaml
```

**Phase 2: ArgoCD Application Creation**
```bash
# Create dev environment first
argocd app create -f argocd-apps/sysdig-shield-dev.yaml
argocd app sync sysdig-shield-dev
argocd app wait sysdig-shield-dev --health
```

**Phase 3: Verification**
```bash
# Check all components healthy
kubectl get pods -n sysdig-shield
kubectl exec -it daemonset/sysdig-agent -n sysdig-shield -- sysdig-agent-check

# Test admission controller (dry-run should show policy evaluation)
kubectl run test-pod --image=nginx --dry-run=server
```

**Phase 4: Production Deployment** (after dev/staging success)
```bash
argocd app create -f argocd-apps/sysdig-shield-prod.yaml
# Manual sync in production
argocd app sync sysdig-shield-prod
argocd app wait sysdig-shield-prod --health
```

### Rollback Strategy

**Automated Rollback** (ArgoCD configured):
- ArgoCD detects health check failures
- Auto-rollback to previous revision if enabled
- Notification sent to platform team

**Manual Rollback**:
```bash
# View history
argocd app history sysdig-shield-prod

# Rollback to specific revision
argocd app rollback sysdig-shield-prod <REVISION>

# Emergency: Delete admission controller webhook
kubectl delete validatingwebhookconfiguration sysdig-admission-controller
kubectl delete mutatingwebhookconfiguration sysdig-admission-controller
```

### Monitoring Post-Deployment

1. **ArgoCD Sync Status**: Dashboard should show "Healthy" and "Synced"
2. **Pod Health**: All pods in Running state, ready checks passing
3. **Sysdig Backend Connectivity**: Check agent connection in Sysdig portal
4. **Admission Controller**: Test policy enforcement with sample deployment
5. **Resource Usage**: Monitor node CPU/memory, ensure within acceptable limits

## Open Questions

1. **Regional Backend Selection**: Should we default to US1 region or make it configurable per environment? (Impacts latency and data residency)

2. **Admission Controller Failure Policy**: Should production use `Fail` (block on controller failure) or `Ignore` (allow deployments when down)? Security vs availability trade-off.

3. **Image Scanning Scope**: Should Node Analyzer scan all images or only new/changed images? Performance vs coverage trade-off.

4. **Policy Enforcement Scope**: Should admission policies apply cluster-wide or exclude system namespaces (kube-system, kube-public)?

5. **Horizontal Pod Autoscaling**: Should admission controller and KSPM collector use HPA in production, or are fixed replicas sufficient?

6. **Certificate Management**: Who provides TLS certificates for admission controller webhook? cert-manager, manual, or Sysdig-provided?

7. **Log Aggregation**: Should Sysdig component logs be shipped to central logging (ELK, Splunk) or rely on Sysdig backend for log aggregation?

8. **Upgrade Strategy**: Rolling updates vs blue-green deployment for Sysdig components? What's acceptable downtime for admission controller?
