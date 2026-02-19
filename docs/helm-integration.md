# Helm Integration Guide

This guide explains how to use official Sysdig Helm charts as an alternative to Kustomize-based deployments.

## Overview

While this repository uses Kustomize as the primary deployment method, you can also use the official Sysdig Helm charts with environment-specific values files.

## Helm Chart Information

- **Chart Repository**: https://charts.sysdig.com
- **Chart Name**: `sysdig/shield`
- **Recommended Version**: Pin to specific version (e.g., 1.28.0)
- **Configuration Structure**: Feature-based configuration using `features` key

## Setup

### 1. Add Sysdig Helm Repository

```bash
helm repo add sysdig https://charts.sysdig.com
helm repo update
```

### 2. Install with Environment-Specific Values

#### Dev Environment
```bash
helm install sysdig-shield sysdig/shield \
  --namespace sysdig-shield \
  --create-namespace \
  --version 1.28.0 \
  --values helm-values/base-values.yaml \
  --values helm-values/dev-values.yaml
```

#### Staging Environment
```bash
helm install sysdig-shield sysdig/shield \
  --namespace sysdig-shield \
  --create-namespace \
  --version 1.28.0 \
  --values helm-values/base-values.yaml \
  --values helm-values/staging-values.yaml
```

#### Production Environment
```bash
helm install sysdig-shield sysdig/shield \
  --namespace sysdig-shield \
  --create-namespace \
  --version 1.28.0 \
  --values helm-values/base-values.yaml \
  --values helm-values/production-values.yaml
```

## Feature-Based Configuration

The sysdig/shield chart uses a feature-based configuration structure. Key features include:

### Core Structure
```yaml
cluster_config:
  name: "cluster-name"
  cluster_type: generic
  tags:
    environment: production

sysdig_endpoint:
  region: us1  # or us2, us3, us4, eu1, au1
  access_key_existing_secret: sysdig-agent
```

### Available Features
- **admission_control**: Policy enforcement at deployment time
  - `failure_policy`: Fail (block) or Ignore (audit)
  - `dry_run`: Test policies without enforcement
  - `container_vulnerability_management`: Block vulnerable images
  - `posture`: Enforce posture compliance
  - `supply_chain`: Image signature verification

- **posture**: Security posture assessment
  - `cluster_posture`: Kubernetes configuration scanning
  - `host_posture`: Host OS compliance checks

- **vulnerability_management**: CVE detection
  - `container_vulnerability_management`: Container image scanning
  - `host_vulnerability_management`: Host OS vulnerability scanning
  - `in_use`: Track only in-use packages

- **detections**: Runtime threat detection
  - `drift_control`: Detect executable changes
  - `malware_control`: Malware detection
  - `ml_policies`: ML-based anomaly detection
  - `kubernetes_audit`: Audit log analysis
  - `file_integrity_monitoring`: File change tracking

- **investigations**: Forensics and troubleshooting
  - `activity_audit`: System call auditing
  - `network_security`: Network traffic monitoring
  - `captures`: Packet capture capability

- **respond**: Automated response actions
  - `rapid_response`: Interactive shell access

- **monitor**: Observability features
  - `prometheus`: Metrics export
  - `kubernetes_events`: Event collection
  - `kube_state_metrics`: Cluster state metrics

## Hybrid Approach: Helm + Kustomize

Combine Helm templates with Kustomize patches:

```bash
# Render Helm chart to YAML
helm template sysdig-shield sysdig/shield \
  --version 1.28.0 \
  --values helm-values/base-values.yaml \
  --namespace sysdig-shield | kubectl kustomize kustomize/overlays/production/
```

## Comparison: Helm vs Kustomize

- Use **Helm** for official chart updates and simpler upgrades
- Use **Kustomize** for fine-grained control and custom patches
- Use **Hybrid** for best of both worlds
