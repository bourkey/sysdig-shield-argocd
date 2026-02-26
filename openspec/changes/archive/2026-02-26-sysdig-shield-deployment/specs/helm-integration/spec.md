## ADDED Requirements

### Requirement: Helm values file structure
The system SHALL provide Helm values files for configuring Sysdig deployments via official Sysdig Helm charts.

#### Scenario: Base values file
- **WHEN** the base Helm values file is created
- **THEN** it MUST contain global.sysdig.region setting
- **AND** it MUST contain global.sysdig.accessKey reference (via secret)
- **AND** it MUST enable/disable components (agent, nodeAnalyzer, admissionController, kspmCollector)
- **AND** it MUST be compatible with official sysdig-deploy Helm chart

#### Scenario: Environment-specific values
- **WHEN** environment-specific Helm values are created
- **THEN** dev values MUST override replicas to minimal (1)
- **AND** production values MUST set high availability (3+ replicas)
- **AND** values MUST override resource requests and limits per environment

### Requirement: Sysdig Agent Helm configuration
The system SHALL configure Sysdig Agent settings via Helm values.

#### Scenario: Agent configuration via values
- **WHEN** agent.enabled is true in Helm values
- **THEN** the Helm chart MUST deploy a Sysdig Agent DaemonSet
- **AND** agent.image.tag MUST be configurable
- **AND** agent.resources.requests and agent.resources.limits MUST be configurable
- **AND** agent.ebpf.enabled MUST control eBPF vs kernel module mode

#### Scenario: Agent logging configuration
- **WHEN** agent.logLevel is set in Helm values
- **THEN** the agent MUST use the specified log level (debug, info, warning, error)
- **AND** agent.logPriority MUST control event priority filtering
- **AND** changes MUST propagate to the agent ConfigMap

### Requirement: Admission Controller Helm configuration
The system SHALL configure admission controller settings via Helm values.

#### Scenario: Admission controller enabled
- **WHEN** admissionController.enabled is true in Helm values
- **THEN** the Helm chart MUST deploy admission controller Deployment
- **AND** admissionController.replicas MUST control replica count
- **AND** admissionController.scanner.enabled MUST enable/disable image scanning
- **AND** admissionController.features.k8sAuditDetections MUST control audit logging

#### Scenario: Webhook failure policy
- **WHEN** admissionController.webhook.failurePolicy is set
- **THEN** it MUST accept "Ignore" or "Fail" values
- **AND** it MUST configure the ValidatingWebhookConfiguration accordingly
- **AND** production SHOULD default to "Fail" after validation

### Requirement: Node Analyzer Helm configuration
The system SHALL configure node analyzer settings via Helm values.

#### Scenario: Node analyzer enabled
- **WHEN** nodeAnalyzer.enabled is true in Helm values
- **THEN** the Helm chart MUST deploy node analyzer DaemonSet
- **AND** nodeAnalyzer.imageAnalyzer.enabled MUST control image scanning
- **AND** nodeAnalyzer.hostAnalyzer.enabled MUST control host filesystem scanning
- **AND** nodeAnalyzer.benchmarkRunner.enabled MUST control CIS benchmark scanning

#### Scenario: Runtime scanning configuration
- **WHEN** node analyzer runtime scanning is configured
- **THEN** nodeAnalyzer.runtimeScanner.enabled MUST enable/disable runtime scanning
- **AND** nodeAnalyzer.runtimeScanner.settings.eveEnabled MUST control event scanning
- **AND** resource limits MUST be configurable per scanner type

### Requirement: KSPM Collector Helm configuration
The system SHALL configure KSPM collector settings via Helm values.

#### Scenario: KSPM enabled
- **WHEN** kspmCollector.enabled is true in Helm values
- **THEN** the Helm chart MUST deploy KSPM collector Deployment
- **AND** kspmCollector.replicas MUST control replica count
- **AND** kspmCollector.resources MUST be configurable
- **AND** compliance benchmarks MUST be configurable via kspmCollector.settings

### Requirement: Regional backend configuration
The system SHALL support configuring regional Sysdig backends via Helm values.

#### Scenario: US1 region
- **WHEN** global.sysdig.region is set to "us1"
- **THEN** all components MUST connect to us1.app.sysdig.com
- **AND** the collector URL MUST be ingest-us1.app.sysdig.com

#### Scenario: EU1 region
- **WHEN** global.sysdig.region is set to "eu1"
- **THEN** all components MUST connect to eu1.app.sysdig.com
- **AND** the collector URL MUST be ingest-eu1.app.sysdig.com

#### Scenario: Custom backend
- **WHEN** global.sysdig.apiEndpoint is set to a custom URL
- **THEN** all components MUST connect to the custom backend
- **AND** it MUST override region-based defaults

### Requirement: Secret reference in Helm values
The system SHALL reference Kubernetes Secrets for sensitive values instead of embedding them in Helm values.

#### Scenario: Access key from secret
- **WHEN** Helm values reference the access key
- **THEN** global.sysdig.accessKey MUST NOT contain the actual key value
- **AND** global.sysdig.accessKeySecret MUST reference an existing Secret name
- **AND** the Secret MUST be created before Helm chart installation

#### Scenario: TLS certificate from secret
- **WHEN** admission controller TLS is configured
- **THEN** admissionController.webhook.tls.cert MUST reference a Secret
- **AND** the Secret MUST contain tls.crt and tls.key
- **AND** the Helm chart MUST NOT generate self-signed certificates in production

### Requirement: Helm chart version pinning
The system SHALL pin Helm chart versions to ensure reproducible deployments.

#### Scenario: Chart version specified
- **WHEN** Helm is used via ArgoCD or direct install
- **THEN** the chart version MUST be explicitly specified (e.g., 1.6.10)
- **AND** the chart version MUST NOT use "latest" or floating versions
- **AND** chart upgrades MUST be tested in dev before production

#### Scenario: Chart repository configuration
- **WHEN** the Helm repository is configured
- **THEN** it MUST point to https://charts.sysdig.com
- **AND** the repository MUST be verified as official Sysdig charts
- **AND** repository credentials MUST be used if accessing private charts

### Requirement: Helm values validation
The system SHALL validate Helm values before deployment to prevent misconfigurations.

#### Scenario: Values schema validation
- **WHEN** Helm values are provided
- **THEN** they MUST be validated against the chart's values schema
- **AND** required fields MUST be present
- **AND** invalid field names MUST be rejected with clear error messages

#### Scenario: Dry-run before deployment
- **WHEN** deploying via Helm
- **THEN** a dry-run MUST be performed first (helm template or helm install --dry-run)
- **AND** the rendered manifests MUST be reviewed for correctness
- **AND** deployment MUST proceed only if dry-run succeeds

### Requirement: Kustomize integration with Helm
The system SHALL support using Kustomize to patch Helm-generated manifests.

#### Scenario: Helm template as Kustomize base
- **WHEN** Helm is used with Kustomize
- **THEN** Helm templates MUST be rendered to YAML (helm template)
- **AND** rendered manifests MUST be stored in kustomize/base/
- **AND** Kustomize overlays MUST apply patches to rendered Helm output

#### Scenario: Kustomize overrides Helm values
- **WHEN** Kustomize patches are applied to Helm-generated resources
- **THEN** patches MUST override specific fields (replicas, resources)
- **AND** patches MUST preserve Helm-managed labels and annotations
- **AND** the combination MUST produce valid Kubernetes manifests
