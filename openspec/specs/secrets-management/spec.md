## ADDED Requirements

### Requirement: No plaintext secrets in Git
The system SHALL ensure that no plaintext secrets are committed to the Git repository.

#### Scenario: Git repository scan
- **WHEN** the repository is scanned for secrets
- **THEN** it MUST NOT contain any plaintext Sysdig access keys
- **AND** it MUST NOT contain any plaintext TLS certificates or private keys
- **AND** it MUST NOT contain any plaintext credentials

#### Scenario: Secret placeholder
- **WHEN** base manifests reference secrets
- **THEN** they MUST reference Secret resources by name
- **AND** they MUST NOT contain actual secret values
- **AND** they MUST include documentation on how to provide secrets

### Requirement: External Secrets Operator support
The system SHALL support External Secrets Operator for syncing secrets from external secret stores.

#### Scenario: ExternalSecret resource created
- **WHEN** External Secrets Operator is used
- **THEN** an ExternalSecret resource MUST be created for the Sysdig access key
- **AND** it MUST reference a SecretStore or ClusterSecretStore
- **AND** it MUST specify the target Secret name as "sysdig-agent"

#### Scenario: AWS Secrets Manager integration
- **WHEN** AWS Secrets Manager is used as the secret store
- **THEN** the ExternalSecret MUST reference the AWS secret by name or ARN
- **AND** the SecretStore MUST have correct IAM role configuration
- **AND** the synced Secret MUST contain the key "access-key"

#### Scenario: HashiCorp Vault integration
- **WHEN** Vault is used as the secret store
- **THEN** the ExternalSecret MUST reference the Vault path
- **AND** the SecretStore MUST use Kubernetes auth method or token auth
- **AND** the synced Secret MUST be automatically rotated when Vault secret changes

### Requirement: Sealed Secrets support
The system SHALL support Sealed Secrets for encrypting secrets that can be committed to Git.

#### Scenario: SealedSecret resource created
- **WHEN** Sealed Secrets is used
- **THEN** a SealedSecret resource MUST be created for the Sysdig access key
- **AND** it MUST be encrypted with the cluster's sealing key
- **AND** it MUST specify the target Secret name and namespace

#### Scenario: Sealed secret decryption
- **WHEN** a SealedSecret is applied to the cluster
- **THEN** the sealed-secrets controller MUST decrypt it
- **AND** it MUST create a corresponding Secret resource
- **AND** the Secret MUST contain the decrypted access key

### Requirement: ArgoCD Vault Plugin support
The system SHALL support ArgoCD Vault Plugin for injecting secrets at deployment time.

#### Scenario: Vault placeholder in manifest
- **WHEN** ArgoCD Vault Plugin is used
- **THEN** manifests MUST contain Vault path placeholders (e.g., <path:secret/data/sysdig#access-key>)
- **AND** ArgoCD MUST replace placeholders with actual values during sync
- **AND** secrets MUST NOT be stored in ArgoCD's cache

#### Scenario: Vault authentication
- **WHEN** ArgoCD Vault Plugin syncs an application
- **THEN** it MUST authenticate to Vault using Kubernetes auth
- **AND** it MUST have read permissions on the Sysdig secret path
- **AND** it MUST inject the secret value into the Kubernetes Secret manifest

### Requirement: TLS certificate management
The system SHALL provide secure management of TLS certificates for the admission controller webhook.

#### Scenario: cert-manager integration
- **WHEN** cert-manager is available in the cluster
- **THEN** a Certificate resource MUST be created for the admission controller
- **AND** cert-manager MUST provision and rotate the certificate automatically
- **AND** the certificate MUST be stored in a Secret referenced by the webhook

#### Scenario: Manual certificate provisioning
- **WHEN** cert-manager is not available
- **THEN** documentation MUST provide steps for manual certificate generation
- **AND** the certificate MUST be valid for the webhook service DNS name (e.g., sysdig-admission-controller.sysdig-shield.svc)
- **AND** the certificate Secret MUST contain tls.crt and tls.key

### Requirement: Secret rotation support
The system SHALL support secret rotation without service disruption.

#### Scenario: Access key rotation
- **WHEN** the Sysdig access key is rotated in the external secret store
- **THEN** the External Secrets Operator MUST sync the new value within 5 minutes
- **AND** Sysdig Agent pods MUST reload the new access key
- **AND** connectivity to Sysdig backend MUST be maintained during rotation

#### Scenario: TLS certificate rotation
- **WHEN** TLS certificates are rotated
- **THEN** the admission controller MUST reload the new certificate
- **AND** the webhook configuration MUST be updated with the new CA bundle
- **AND** the admission controller MUST continue accepting webhook requests during rotation

### Requirement: Secret validation
The system SHALL validate secrets before deployment to prevent misconfigurations.

#### Scenario: Access key format validation
- **WHEN** the Sysdig access key Secret is created
- **THEN** the system MUST validate it is a valid UUID or API key format
- **AND** it MUST reject empty or malformed values
- **AND** it MUST provide clear error messages for invalid secrets

#### Scenario: Pre-deployment connectivity test
- **WHEN** deploying Sysdig components
- **THEN** a pre-flight check MUST verify the access key can connect to Sysdig backend
- **AND** it MUST fail fast if authentication fails
- **AND** it MUST provide troubleshooting guidance
