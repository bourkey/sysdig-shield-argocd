## ADDED Requirements

### Requirement: DaemonSet deployment
The system SHALL deploy Sysdig Agent as a DaemonSet to run on every node in the cluster.

#### Scenario: Agent pod on every node
- **WHEN** the Sysdig Agent DaemonSet is deployed
- **THEN** a Sysdig Agent pod MUST run on every schedulable node
- **AND** each pod MUST mount the host's /var/run/docker.sock or containerd socket
- **AND** each pod MUST have access to the host's /proc filesystem

#### Scenario: Kernel module loading
- **WHEN** a Sysdig Agent pod starts
- **THEN** it MUST successfully load the Sysdig kernel module
- **AND** it MUST verify kernel compatibility
- **AND** it MUST fall back to eBPF mode if kernel module loading fails

### Requirement: Backend connectivity
The system SHALL ensure Sysdig Agents connect to the Sysdig backend for data transmission.

#### Scenario: Successful backend connection
- **WHEN** the Sysdig Agent starts
- **THEN** it MUST connect to the configured Sysdig backend (app.sysdigcloud.com or regional)
- **AND** it MUST authenticate using the provided access key
- **AND** it MUST establish a persistent connection for streaming data

#### Scenario: Connection failure handling
- **WHEN** the backend connection fails
- **THEN** the agent MUST retry with exponential backoff
- **AND** the agent MUST buffer data locally during disconnection
- **AND** the agent MUST report connection status in pod readiness check

### Requirement: Resource limits and requests
The system SHALL define appropriate resource limits and requests for Sysdig Agent pods.

#### Scenario: Production resource allocation
- **WHEN** Sysdig Agent is deployed in production
- **THEN** CPU requests MUST be 500m
- **AND** CPU limits MUST be 1000m
- **AND** memory requests MUST be 512Mi
- **AND** memory limits MUST be 1Gi

#### Scenario: Dev environment resource allocation
- **WHEN** Sysdig Agent is deployed in dev
- **THEN** CPU requests MUST be 100m
- **AND** CPU limits MUST be 500m
- **AND** memory requests MUST be 256Mi
- **AND** memory limits MUST be 512Mi

### Requirement: Configuration management
The system SHALL provide configurable settings for Sysdig Agent via ConfigMap.

#### Scenario: Agent configuration applied
- **WHEN** the agent ConfigMap is created
- **THEN** it MUST include the Sysdig collector address
- **AND** it MUST include agent tags and labels
- **AND** it MUST specify log level (info, debug, warning, error)
- **AND** it MUST define security event capture settings

#### Scenario: Configuration hot reload
- **WHEN** the agent ConfigMap is updated
- **THEN** running agent pods MUST detect the change
- **AND** agents MUST reload configuration without restart (if supported)
- **OR** agents MUST perform a rolling restart to apply changes

### Requirement: Security context
The system SHALL run Sysdig Agent pods with appropriate security contexts for host-level monitoring.

#### Scenario: Privileged security context
- **WHEN** the Sysdig Agent pod is created
- **THEN** it MUST run as privileged or have specific capabilities (SYS_ADMIN, SYS_RESOURCE, SYS_PTRACE)
- **AND** it MUST have hostPID enabled
- **AND** it MUST have hostNetwork enabled
- **AND** it MUST run in the host IPC namespace
