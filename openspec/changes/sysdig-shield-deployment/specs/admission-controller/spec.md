## ADDED Requirements

### Requirement: Webhook deployment
The system SHALL deploy the Sysdig Admission Controller as a highly available Deployment with multiple replicas.

#### Scenario: High availability deployment
- **WHEN** the admission controller is deployed in production
- **THEN** it MUST have at least 3 replicas
- **AND** it MUST have pod anti-affinity rules to spread replicas across nodes
- **AND** it MUST have a pod disruption budget allowing maximum 1 unavailable pod

#### Scenario: Dev environment deployment
- **WHEN** the admission controller is deployed in dev
- **THEN** it MUST have 1 replica
- **AND** pod anti-affinity MAY be disabled for single-node clusters

### Requirement: ValidatingWebhookConfiguration
The system SHALL create a ValidatingWebhookConfiguration that intercepts pod creation and updates.

#### Scenario: Webhook intercepts pod operations
- **WHEN** a pod is created or updated in the cluster
- **THEN** the webhook MUST be invoked before the pod is admitted
- **AND** the webhook MUST receive the pod specification
- **AND** the webhook MUST return an admission decision within the timeout period

#### Scenario: Webhook failure policy
- **WHEN** the admission controller is unreachable
- **THEN** the webhook MUST use failurePolicy: Ignore during initial rollout
- **AND** the webhook MAY use failurePolicy: Fail after stability is proven
- **AND** the failure policy MUST be configurable per environment

### Requirement: Image scanning policy enforcement
The system SHALL enforce image scanning policies by rejecting pods with vulnerable or non-compliant images.

#### Scenario: Block high-severity vulnerabilities
- **WHEN** a pod uses an image with high or critical severity vulnerabilities
- **THEN** the admission controller MUST deny the pod creation
- **AND** it MUST return a clear error message describing the vulnerabilities
- **AND** it MUST log the policy violation to Sysdig backend

#### Scenario: Allow compliant images
- **WHEN** a pod uses an image that passes all scanning policies
- **THEN** the admission controller MUST allow the pod creation
- **AND** it MUST record the successful policy evaluation

### Requirement: Audit mode support
The system SHALL support audit mode where policy violations are logged but not blocked.

#### Scenario: Audit mode enabled
- **WHEN** audit mode is configured
- **THEN** the admission controller MUST log all policy violations
- **AND** it MUST NOT reject any pod creations
- **AND** it MUST send violation events to Sysdig backend
- **AND** it MUST label audit events as non-blocking

### Requirement: TLS certificate management
The system SHALL use TLS certificates for secure webhook communication.

#### Scenario: TLS certificate configured
- **WHEN** the admission controller webhook is deployed
- **THEN** it MUST have a valid TLS certificate
- **AND** the certificate MUST be trusted by the Kubernetes API server
- **AND** the certificate MUST match the webhook service DNS name

#### Scenario: Certificate rotation
- **WHEN** TLS certificates are near expiration
- **THEN** the system MUST support certificate rotation
- **AND** it MUST allow rotation without webhook downtime

### Requirement: Namespace exclusion
The system SHALL allow exclusion of specific namespaces from admission control policies.

#### Scenario: System namespaces excluded
- **WHEN** the webhook configuration is created
- **THEN** it MUST exclude kube-system namespace by default
- **AND** it MUST exclude kube-public namespace by default
- **AND** it MUST support additional namespace exclusions via configuration

#### Scenario: Namespace label-based exclusion
- **WHEN** a namespace has label "sysdig-admission: skip"
- **THEN** the admission controller MUST skip policy enforcement for that namespace
- **AND** it MUST log the exclusion decision
