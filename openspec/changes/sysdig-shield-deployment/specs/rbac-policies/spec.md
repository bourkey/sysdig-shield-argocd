## ADDED Requirements

### Requirement: Namespace-scoped ServiceAccount
The system SHALL create dedicated ServiceAccounts for each Sysdig component in the sysdig-shield namespace.

#### Scenario: Sysdig Agent ServiceAccount
- **WHEN** the Sysdig Agent is deployed
- **THEN** a ServiceAccount named "sysdig-agent" MUST be created
- **AND** it MUST be in the sysdig-shield namespace
- **AND** it MUST be referenced by the Sysdig Agent DaemonSet

#### Scenario: Admission Controller ServiceAccount
- **WHEN** the admission controller is deployed
- **THEN** a ServiceAccount named "sysdig-admission-controller" MUST be created
- **AND** it MUST be in the sysdig-shield namespace
- **AND** it MUST be referenced by the admission controller Deployment

### Requirement: ClusterRole for Sysdig Agent
The system SHALL create a ClusterRole with minimal required permissions for the Sysdig Agent to monitor the cluster.

#### Scenario: Read-only cluster access
- **WHEN** the Sysdig Agent ClusterRole is created
- **THEN** it MUST have get, list, and watch permissions on pods in all namespaces
- **AND** it MUST have get, list, and watch permissions on nodes
- **AND** it MUST have get, list, and watch permissions on namespaces
- **AND** it MUST have get, list, and watch permissions on services
- **AND** it MUST NOT have create, update, delete, or patch permissions on any resources

#### Scenario: Events and metrics access
- **WHEN** the Sysdig Agent needs to collect events
- **THEN** the ClusterRole MUST include get, list, and watch on events
- **AND** it MUST include get and list on metrics.k8s.io API group
- **AND** it MUST include get on /metrics endpoint

### Requirement: ClusterRole for Admission Controller
The system SHALL create a ClusterRole with minimal permissions for the admission controller to evaluate policies.

#### Scenario: Admission controller permissions
- **WHEN** the admission controller ClusterRole is created
- **THEN** it MUST have get and list permissions on namespaces
- **AND** it MUST have get permissions on pods
- **AND** it MUST have create permissions on events (for audit logging)
- **AND** it MUST NOT have permissions to modify pods or deployments

#### Scenario: Webhook configuration access
- **WHEN** the admission controller manages its webhook configuration
- **THEN** the ClusterRole MUST include get and update permissions on validatingwebhookconfigurations
- **AND** it MUST be limited to its own webhook configuration by name
- **AND** it MUST NOT have permissions on other webhook configurations

### Requirement: ClusterRole for KSPM Collector
The system SHALL create a ClusterRole with read-only access to Kubernetes resources for compliance scanning.

#### Scenario: Comprehensive read access
- **WHEN** the KSPM collector ClusterRole is created
- **THEN** it MUST have get, list, and watch on all standard Kubernetes resources
- **AND** it MUST include pods, deployments, replicasets, daemonsets, statefulsets
- **AND** it MUST include services, ingresses, networkpolicies
- **AND** it MUST include configmaps, secrets (metadata only), serviceaccounts
- **AND** it MUST include roles, rolebindings, clusterroles, clusterrolebindings
- **AND** it MUST NOT have any write permissions

#### Scenario: CRD discovery
- **WHEN** the KSPM collector scans for custom resources
- **THEN** the ClusterRole MUST include get and list on apiservices
- **AND** it MUST include get and list on customresourcedefinitions
- **AND** it MUST be able to discover and read custom resources

### Requirement: ClusterRoleBindings
The system SHALL create ClusterRoleBindings to bind ServiceAccounts to their respective ClusterRoles.

#### Scenario: Agent ClusterRoleBinding
- **WHEN** the Sysdig Agent ClusterRoleBinding is created
- **THEN** it MUST bind the sysdig-agent ServiceAccount to the sysdig-agent ClusterRole
- **AND** it MUST specify the namespace as sysdig-shield
- **AND** the binding MUST be cluster-scoped

#### Scenario: Admission Controller ClusterRoleBinding
- **WHEN** the admission controller ClusterRoleBinding is created
- **THEN** it MUST bind the sysdig-admission-controller ServiceAccount to its ClusterRole
- **AND** it MUST enable cluster-wide admission control

### Requirement: Node Analyzer RBAC
The system SHALL create RBAC resources for the Node Analyzer to access container runtime and image information.

#### Scenario: Node Analyzer ServiceAccount
- **WHEN** the Node Analyzer is deployed
- **THEN** a ServiceAccount named "sysdig-node-analyzer" MUST be created
- **AND** it MUST have a ClusterRole with get and list on nodes
- **AND** it MUST have access to container runtime sockets via hostPath (not RBAC-controlled)

### Requirement: Least privilege principle
The system SHALL follow the principle of least privilege by granting only necessary permissions.

#### Scenario: No wildcard permissions
- **WHEN** RBAC policies are reviewed
- **THEN** no ClusterRole MUST use wildcard (*) for resources
- **AND** no ClusterRole MUST use wildcard (*) for verbs
- **AND** permissions MUST be explicitly listed

#### Scenario: No cluster-admin permissions
- **WHEN** RBAC policies are reviewed
- **THEN** no Sysdig ServiceAccount MUST be bound to cluster-admin ClusterRole
- **AND** no Sysdig ServiceAccount MUST have equivalent cluster-admin permissions
- **AND** permissions MUST be scoped to specific resource types and verbs

### Requirement: RBAC policy validation
The system SHALL validate RBAC policies to ensure they meet security requirements.

#### Scenario: Automated RBAC audit
- **WHEN** RBAC manifests are deployed
- **THEN** an automated tool MUST audit the permissions
- **AND** it MUST flag any overly permissive rules
- **AND** it MUST verify compliance with least privilege principle

#### Scenario: Regular RBAC review
- **WHEN** RBAC policies are in production
- **THEN** they MUST be reviewed quarterly for excessive permissions
- **AND** any unused permissions MUST be removed
- **AND** changes MUST be logged and approved
