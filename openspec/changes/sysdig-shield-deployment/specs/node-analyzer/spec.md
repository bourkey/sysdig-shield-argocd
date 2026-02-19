## ADDED Requirements

### Requirement: DaemonSet deployment for image analysis
The system SHALL deploy Node Analyzer as a DaemonSet to perform image scanning on each node.

#### Scenario: Node analyzer on every node
- **WHEN** the Node Analyzer DaemonSet is deployed
- **THEN** a node analyzer pod MUST run on every schedulable node
- **AND** each pod MUST have access to the node's container runtime socket
- **AND** each pod MUST have access to the node's image storage

#### Scenario: CRI-O runtime support
- **WHEN** a node uses CRI-O container runtime
- **THEN** the node analyzer MUST mount the CRI-O socket (/var/run/crio/crio.sock)
- **AND** it MUST successfully communicate with the CRI-O API

#### Scenario: Containerd runtime support
- **WHEN** a node uses containerd runtime
- **THEN** the node analyzer MUST mount the containerd socket (/run/containerd/containerd.sock)
- **AND** it MUST successfully communicate with the containerd API

### Requirement: Image vulnerability scanning
The system SHALL scan container images for vulnerabilities and report findings to Sysdig backend.

#### Scenario: Scan new image
- **WHEN** a new container image is pulled to a node
- **THEN** the node analyzer MUST detect the new image
- **AND** it MUST scan the image for vulnerabilities within 5 minutes
- **AND** it MUST send scan results to Sysdig backend
- **AND** it MUST cache results to avoid duplicate scans

#### Scenario: Scan cached images
- **WHEN** an image has been previously scanned and is still cached
- **THEN** the node analyzer MUST NOT re-scan the image
- **AND** it MUST use the cached scan results
- **AND** it MUST refresh scan results if vulnerability database is updated

### Requirement: Compliance checking
The system SHALL check container images against compliance benchmarks (CIS, PCI-DSS, etc.).

#### Scenario: CIS Docker benchmark
- **WHEN** an image is scanned
- **THEN** the node analyzer MUST evaluate the image against CIS Docker Benchmark
- **AND** it MUST report compliance score
- **AND** it MUST identify specific compliance violations

#### Scenario: Custom compliance policies
- **WHEN** custom compliance policies are defined in Sysdig backend
- **THEN** the node analyzer MUST evaluate images against those policies
- **AND** it MUST report pass/fail status for each policy

### Requirement: Resource efficiency
The system SHALL perform image scanning efficiently without impacting node performance.

#### Scenario: Resource limits enforced
- **WHEN** node analyzer is deployed in production
- **THEN** CPU requests MUST be 250m
- **AND** CPU limits MUST be 500m
- **AND** memory requests MUST be 256Mi
- **AND** memory limits MUST be 512Mi

#### Scenario: Scan rate limiting
- **WHEN** multiple images need scanning simultaneously
- **THEN** the node analyzer MUST rate-limit scan operations
- **AND** it MUST prioritize scanning of running container images
- **AND** it MUST defer scanning of unused cached images

### Requirement: Host filesystem scanning
The system SHALL scan the host filesystem for runtime anomalies and compliance violations.

#### Scenario: Host filesystem mounted
- **WHEN** the node analyzer pod starts
- **THEN** it MUST mount the host root filesystem at /host
- **AND** it MUST have read-only access to host directories
- **AND** it MUST scan for suspicious files and configurations

#### Scenario: Runtime anomaly detection
- **WHEN** host filesystem scanning is performed
- **THEN** the node analyzer MUST detect unauthorized file changes
- **AND** it MUST identify suspicious binaries
- **AND** it MUST report findings to Sysdig backend
