## ADDED Requirements

### Requirement: Kustomize base configuration
The system SHALL provide a base Kustomize configuration containing common manifests for all environments.

#### Scenario: Base manifests exist
- **WHEN** the base Kustomize directory is accessed
- **THEN** it MUST contain namespace.yaml
- **AND** it MUST contain ServiceAccount, Role, and RoleBinding manifests
- **AND** it MUST contain DaemonSet and Deployment manifests for all Sysdig components
- **AND** it MUST contain a kustomization.yaml listing all resources

#### Scenario: Base configuration is environment-agnostic
- **WHEN** base manifests are reviewed
- **THEN** they MUST NOT contain environment-specific values (replicas, resource limits, node selectors)
- **AND** they MUST use placeholder values that are overridden by overlays
- **AND** they MUST be valid Kubernetes manifests that can be applied directly (with defaults)

### Requirement: Dev environment overlay
The system SHALL provide a dev environment overlay with minimal resources for development and testing.

#### Scenario: Dev replica configuration
- **WHEN** the dev overlay is applied
- **THEN** admission controller MUST have 1 replica
- **AND** KSPM collector MUST have 1 replica
- **AND** DaemonSets MUST use nodeSelector to run on dev nodes only (if multi-environment cluster)

#### Scenario: Dev resource limits
- **WHEN** the dev overlay is applied
- **THEN** Sysdig Agent MUST request 100m CPU and 256Mi memory
- **AND** admission controller MUST request 100m CPU and 128Mi memory
- **AND** node analyzer MUST request 100m CPU and 128Mi memory
- **AND** KSPM collector MUST request 100m CPU and 128Mi memory

#### Scenario: Dev sync policy
- **WHEN** the dev ArgoCD application is created
- **THEN** it MUST have automated sync enabled (spec.syncPolicy.automated)
- **AND** it MUST have prune enabled to auto-cleanup deleted resources
- **AND** it MUST have selfHeal enabled to auto-correct drift

### Requirement: Staging environment overlay
The system SHALL provide a staging environment overlay with production-like resources for pre-production testing.

#### Scenario: Staging replica configuration
- **WHEN** the staging overlay is applied
- **THEN** admission controller MUST have 2 replicas
- **AND** KSPM collector MUST have 2 replicas
- **AND** DaemonSets MUST run on all staging nodes

#### Scenario: Staging resource limits
- **WHEN** the staging overlay is applied
- **THEN** Sysdig Agent MUST request 300m CPU and 384Mi memory
- **AND** admission controller MUST request 150m CPU and 192Mi memory
- **AND** node analyzer MUST request 150m CPU and 192Mi memory
- **AND** KSPM collector MUST request 100m CPU and 128Mi memory

#### Scenario: Staging sync policy
- **WHEN** the staging ArgoCD application is created
- **THEN** it MUST have automated sync enabled
- **AND** it MUST use production-equivalent policies for validation

### Requirement: Production environment overlay
The system SHALL provide a production environment overlay with high availability and production-grade resources.

#### Scenario: Production replica configuration
- **WHEN** the production overlay is applied
- **THEN** admission controller MUST have 3 replicas
- **AND** KSPM collector MUST have 2 replicas
- **AND** all deployments MUST have pod anti-affinity rules
- **AND** all deployments MUST have PodDisruptionBudgets

#### Scenario: Production resource limits
- **WHEN** the production overlay is applied
- **THEN** Sysdig Agent MUST request 500m CPU and 512Mi memory with limits of 1000m CPU and 1Gi memory
- **AND** admission controller MUST request 200m CPU and 256Mi memory with limits of 500m CPU and 512Mi memory
- **AND** node analyzer MUST request 250m CPU and 256Mi memory with limits of 500m CPU and 512Mi memory
- **AND** KSPM collector MUST request 100m CPU and 128Mi memory with limits of 300m CPU and 256Mi memory

#### Scenario: Production sync policy
- **WHEN** the production ArgoCD application is created
- **THEN** it MUST have manual sync (no spec.syncPolicy.automated)
- **AND** it MUST require explicit approval for each deployment
- **AND** it MUST send notifications to operations team on sync events

### Requirement: Strategic merge patches
The system SHALL use Kustomize strategic merge patches to override base values in overlays.

#### Scenario: Replica count override
- **WHEN** an overlay defines a replica patch
- **THEN** it MUST use strategic merge to update spec.replicas in the deployment
- **AND** it MUST preserve all other deployment fields
- **AND** the patch MUST be minimal (only changed fields)

#### Scenario: Resource patch
- **WHEN** an overlay defines resource patches
- **THEN** it MUST update spec.containers[].resources.requests and limits
- **AND** it MUST target the correct container by name
- **AND** it MUST not affect other containers in the pod

### Requirement: Environment-specific configuration
The system SHALL support environment-specific ConfigMap and Secret values.

#### Scenario: Environment-specific agent configuration
- **WHEN** different log levels are needed per environment
- **THEN** dev overlay MUST set log level to "debug"
- **AND** staging overlay MUST set log level to "info"
- **AND** production overlay MUST set log level to "warning"

#### Scenario: Environment-specific backend URLs
- **WHEN** different Sysdig backends are used per environment
- **THEN** overlays MUST allow overriding the backend URL via patches
- **AND** regional backends MUST be configurable (us1, us2, eu1, au1)
