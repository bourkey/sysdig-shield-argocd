## ADDED Requirements

### Requirement: ArgoCD Application manifest creation
The system SHALL create ArgoCD Application manifests that reference Kustomize bases and overlays for deploying Sysdig Shield components.

#### Scenario: Main application created
- **WHEN** the ArgoCD application manifest is generated
- **THEN** it MUST include metadata.name as "sysdig-shield"
- **AND** it MUST reference the Git repository source
- **AND** it MUST specify the target namespace as "sysdig-shield"

#### Scenario: Source repository configured
- **WHEN** the application manifest is created
- **THEN** it MUST include spec.source.repoURL pointing to the Git repository
- **AND** it MUST include spec.source.path pointing to the Kustomize base or overlay directory
- **AND** it MUST specify spec.source.targetRevision for the Git branch or tag

### Requirement: Environment-specific applications
The system SHALL support environment-specific ArgoCD Applications for dev, staging, and production with different configurations.

#### Scenario: Dev application with auto-sync
- **WHEN** the dev environment application is created
- **THEN** it MUST have spec.syncPolicy.automated.prune set to true
- **AND** it MUST have spec.syncPolicy.automated.selfHeal set to true
- **AND** it MUST reference the kustomize/overlays/dev path

#### Scenario: Production application with manual sync
- **WHEN** the production environment application is created
- **THEN** it MUST NOT have spec.syncPolicy.automated configured
- **AND** it MUST reference the kustomize/overlays/production path
- **AND** it MUST include manual approval requirements

### Requirement: Sync wave configuration
The system SHALL configure ArgoCD sync waves to ensure components are deployed in the correct order.

#### Scenario: Sync waves defined
- **WHEN** manifests are annotated with sync waves
- **THEN** namespace and CRDs MUST be in wave 0
- **AND** RBAC resources MUST be in wave 1
- **AND** ConfigMaps and Secrets MUST be in wave 2
- **AND** DaemonSets MUST be in wave 3
- **AND** Deployments MUST be in wave 4
- **AND** Services and Webhooks MUST be in wave 5

### Requirement: Health check configuration
The system SHALL configure custom health checks for Sysdig components in ArgoCD.

#### Scenario: DaemonSet health check
- **WHEN** Sysdig Agent DaemonSet is deployed
- **THEN** ArgoCD MUST verify pods are running on all schedulable nodes
- **AND** ArgoCD MUST check that all pods are in Ready state

#### Scenario: Admission controller health check
- **WHEN** Admission Controller deployment is deployed
- **THEN** ArgoCD MUST verify the deployment is ready
- **AND** ArgoCD MUST verify the webhook endpoint is responding

### Requirement: Rollback capability
The system SHALL support rollback to previous versions via ArgoCD revision history.

#### Scenario: Successful rollback
- **WHEN** a user initiates a rollback to a previous revision
- **THEN** ArgoCD MUST revert all resources to the specified revision
- **AND** ArgoCD MUST maintain the rollback operation in the history
- **AND** all Sysdig components MUST return to the previous state
