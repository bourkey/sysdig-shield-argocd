## ADDED Requirements

### Requirement: Default deny policy
The system SHALL implement a default deny network policy for the sysdig-shield namespace.

#### Scenario: Deny all ingress by default
- **WHEN** the default deny network policy is applied
- **THEN** all ingress traffic to pods in sysdig-shield namespace MUST be blocked by default
- **AND** only explicitly allowed ingress rules MUST permit traffic
- **AND** the policy MUST apply to all pods via empty podSelector

#### Scenario: Deny all egress by default
- **WHEN** the default deny network policy is applied
- **THEN** all egress traffic from pods in sysdig-shield namespace MUST be blocked by default
- **AND** only explicitly allowed egress rules MUST permit traffic
- **AND** DNS egress MUST be explicitly allowed (port 53 UDP/TCP)

### Requirement: Sysdig Agent network policy
The system SHALL create network policies allowing Sysdig Agent to communicate with required endpoints.

#### Scenario: Egress to Sysdig backend
- **WHEN** the Sysdig Agent network policy is applied
- **THEN** agent pods MUST be allowed egress to app.sysdigcloud.com on port 443
- **AND** agent pods MUST be allowed egress to regional backends (e.g., us1.app.sysdig.com)
- **AND** egress MUST be restricted to HTTPS (port 443) only

#### Scenario: Egress to Kubernetes API server
- **WHEN** the Sysdig Agent network policy is applied
- **THEN** agent pods MUST be allowed egress to the Kubernetes API server
- **AND** the policy MUST permit TCP traffic to port 443 or 6443
- **AND** the policy MUST target the Kubernetes service IP or API server endpoint

#### Scenario: No ingress to agent
- **WHEN** the Sysdig Agent network policy is applied
- **THEN** agent pods MUST NOT accept any ingress traffic
- **AND** no other pods MUST be able to connect to agent pods
- **AND** the policy MUST have an empty ingress rule list (deny all)

### Requirement: Admission Controller network policy
The system SHALL create network policies for secure admission controller webhook communication.

#### Scenario: Ingress from Kubernetes API server
- **WHEN** the admission controller network policy is applied
- **THEN** it MUST allow ingress from the Kubernetes API server on the webhook port (typically 443)
- **AND** it MUST use namespaceSelector or IP block to restrict source to API server
- **AND** it MUST deny all other ingress traffic

#### Scenario: Egress to Sysdig backend
- **WHEN** the admission controller network policy is applied
- **THEN** it MUST allow egress to Sysdig backend (app.sysdigcloud.com) on port 443
- **AND** it MUST allow egress to container registries for image scanning (e.g., docker.io, gcr.io, quay.io)
- **AND** egress to other destinations MUST be denied

#### Scenario: Inter-pod communication denied
- **WHEN** the admission controller network policy is applied
- **THEN** admission controller pods MUST NOT communicate with other Sysdig components
- **AND** they MUST NOT accept connections from other namespace pods
- **AND** only API server ingress MUST be allowed

### Requirement: Node Analyzer network policy
The system SHALL create network policies for Node Analyzer to scan images and report results.

#### Scenario: Egress to Sysdig backend
- **WHEN** the Node Analyzer network policy is applied
- **THEN** it MUST allow egress to Sysdig backend on port 443
- **AND** it MUST allow egress to container registries on standard HTTPS port (443)
- **AND** it MUST allow egress to Docker Hub, GCR, ECR, and other common registries

#### Scenario: Egress for image pulls
- **WHEN** Node Analyzer scans images
- **THEN** the network policy MUST permit egress to image registries
- **AND** it MUST support registries with custom ports
- **AND** it MUST allow HTTP (port 80) for registries that use HTTP

#### Scenario: No ingress required
- **WHEN** the Node Analyzer network policy is applied
- **THEN** no ingress rules MUST be defined
- **AND** all ingress traffic MUST be denied by default

### Requirement: KSPM Collector network policy
The system SHALL create network policies for KSPM Collector to communicate with Kubernetes API and Sysdig backend.

#### Scenario: Egress to Kubernetes API server
- **WHEN** the KSPM Collector network policy is applied
- **THEN** it MUST allow egress to Kubernetes API server on port 443/6443
- **AND** it MUST permit continuous API queries for compliance scanning
- **AND** rate limiting MUST be handled at application level, not network policy

#### Scenario: Egress to Sysdig backend
- **WHEN** the KSPM Collector network policy is applied
- **THEN** it MUST allow egress to Sysdig backend on port 443
- **AND** it MUST allow sending compliance scan results
- **AND** all other egress MUST be denied

#### Scenario: No ingress required
- **WHEN** the KSPM Collector network policy is applied
- **THEN** no ingress rules MUST be defined
- **AND** all ingress traffic MUST be blocked

### Requirement: DNS egress policy
The system SHALL allow DNS resolution for all Sysdig components.

#### Scenario: DNS queries allowed
- **WHEN** network policies are applied
- **THEN** all Sysdig component pods MUST be allowed egress to port 53 UDP
- **AND** they MUST be allowed egress to port 53 TCP (for large responses)
- **AND** DNS queries MUST be permitted to the cluster DNS service (typically kube-dns or coredns)

#### Scenario: CoreDNS service targeting
- **WHEN** the cluster uses CoreDNS
- **THEN** the DNS egress policy MUST target the kube-system namespace
- **AND** it MUST target pods with label k8s-app=kube-dns
- **AND** it MUST permit UDP and TCP on port 53

### Requirement: Environment-specific network policies
The system SHALL support environment-specific network policy configurations.

#### Scenario: Development environment relaxed policies
- **WHEN** network policies are deployed to dev environment
- **THEN** they MAY allow broader egress for troubleshooting
- **AND** they MAY allow ingress on debug ports (e.g., pprof)
- **AND** they MUST still follow baseline security requirements

#### Scenario: Production environment strict policies
- **WHEN** network policies are deployed to production
- **THEN** they MUST enforce strict egress rules
- **AND** they MUST deny all ingress except explicitly required
- **AND** they MUST be audited before deployment

### Requirement: Network policy validation
The system SHALL validate network policies to ensure they don't break required communication.

#### Scenario: Connectivity test before enforcement
- **WHEN** network policies are applied
- **THEN** a connectivity test MUST verify Sysdig backend reachability
- **AND** it MUST verify Kubernetes API server connectivity
- **AND** it MUST verify DNS resolution works

#### Scenario: Network policy audit mode
- **WHEN** network policies are first deployed
- **THEN** they MAY be deployed in audit/log mode (if CNI supports)
- **AND** violations MUST be logged for review
- **AND** enforcement MUST be enabled only after validation
