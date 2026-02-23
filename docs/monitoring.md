# Monitoring Guide

## Sysdig Component Health Monitoring

### Overview

This guide covers setting up Prometheus/Grafana monitoring for Sysdig Shield components and configuring alerts for critical failure scenarios.

## Prometheus Monitoring

### Metrics Endpoints

Sysdig Shield components expose Prometheus metrics on the following ports:

| Component | Port | Path |
|-----------|------|------|
| sysdig-agent | 24231 | /metrics |
| admission-controller | 8080 | /metrics |
| node-analyzer | 8080 | /metrics |
| kspm-collector | 8080 | /metrics |

### ServiceMonitor Configuration

If using the Prometheus Operator, create ServiceMonitors to scrape component metrics:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: sysdig-shield
  namespace: sysdig-shield
  labels:
    app.kubernetes.io/part-of: sysdig-shield
spec:
  selector:
    matchLabels:
      app.kubernetes.io/part-of: sysdig-shield
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

### Key Metrics to Monitor

**Agent Metrics:**
- `sysdig_agent_connected` — 1 when connected to backend, 0 when disconnected
- `sysdig_agent_events_total` — Total security events generated
- `sysdig_agent_cpu_usage_ratio` — Agent CPU usage (alert if > 0.8)
- `sysdig_agent_memory_bytes` — Agent memory usage

**Admission Controller Metrics:**
- `admission_controller_requests_total` — Total webhook requests
- `admission_controller_requests_denied_total` — Denied requests (policy violations)
- `admission_controller_request_duration_seconds` — Request latency
- `admission_controller_errors_total` — Internal errors

**Node Analyzer Metrics:**
- `node_analyzer_scans_total` — Total image scans completed
- `node_analyzer_scan_errors_total` — Failed scans
- `node_analyzer_queue_depth` — Scan queue depth

## Alert Configuration

### Critical Alerts

```yaml
groups:
- name: sysdig-shield-critical
  rules:

  # Agent disconnected from backend
  - alert: SysdigAgentDisconnected
    expr: sysdig_agent_connected == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Sysdig agent disconnected on {{ $labels.node }}"
      description: "Agent has been disconnected for 5+ minutes. Security monitoring is impaired."
      runbook: "https://github.com/your-org/sysdig-shield-argocd/blob/main/docs/troubleshooting.md"

  # Admission controller not responding
  - alert: SysdigAdmissionControllerDown
    expr: up{job="sysdig-admission-controller"} == 0
    for: 2m
    labels:
      severity: critical
    annotations:
      summary: "Sysdig admission controller is down"
      description: "No admission controller pods responding. Policy enforcement may be affected."

  # Admission controller high error rate
  - alert: SysdigAdmissionControllerErrors
    expr: rate(admission_controller_errors_total[5m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Sysdig admission controller high error rate"
      description: "Error rate > 10% over 5 minutes."

  # Webhook latency too high
  - alert: SysdigWebhookHighLatency
    expr: histogram_quantile(0.99, rate(admission_controller_request_duration_seconds_bucket[5m])) > 5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Sysdig admission controller webhook latency high"
      description: "P99 webhook latency exceeds 5s. Deployments may timeout."

  # Pod crash looping
  - alert: SysdigPodCrashLooping
    expr: |
      increase(kube_pod_container_status_restarts_total{
        namespace="sysdig-shield"
      }[1h]) > 3
    for: 0m
    labels:
      severity: critical
    annotations:
      summary: "Sysdig pod crash looping: {{ $labels.pod }}"
      description: "Pod {{ $labels.pod }} has restarted more than 3 times in the last hour."

  # Agent high CPU usage
  - alert: SysdigAgentHighCPU
    expr: sysdig_agent_cpu_usage_ratio > 0.85
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Sysdig agent high CPU on {{ $labels.node }}"
      description: "Agent CPU usage above 85% for 10 minutes. Consider adjusting resource limits."
```

### Add Alerts to Prometheus

```bash
# If using Prometheus Operator, create a PrometheusRule
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: sysdig-shield-alerts
  namespace: sysdig-shield
  labels:
    prometheus: kube-prometheus
    role: alert-rules
$(cat <<'RULES'
spec:
  groups:
    # Paste the alert groups from above
RULES
)
EOF
```

## Grafana Dashboard

### Import Pre-built Dashboards

Sysdig publishes official Grafana dashboards. Import them using the dashboard IDs:

```bash
# Import via Grafana API
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"dashboard": {"id": null, "uid": null}, "folderId": 0, "overwrite": false}' \
  http://admin:password@grafana:3000/api/dashboards/import
```

### Key Dashboard Panels

1. **Agent Status** — Map of connected/disconnected agents per node
2. **Events Rate** — Security events generated per minute
3. **Admission Decisions** — Allow/deny/error rates over time
4. **Webhook Latency** — P50/P95/P99 request duration
5. **Component Uptime** — Availability by component

## Health Checks

### Readiness and Liveness

Verify all components have healthy probes:

```bash
kubectl describe pods -n sysdig-shield | grep -A5 "Liveness\|Readiness"
```

### ArgoCD Health Integration

ArgoCD applications are configured with custom health checks (see [argocd-apps/](../argocd-apps/)). Monitor application health via:

```bash
argocd app list | grep sysdig
```

## On-Call Quick Reference

For alert response procedures, see [incident-response.md](incident-response.md).

For component-specific troubleshooting, see [troubleshooting.md](troubleshooting.md).
