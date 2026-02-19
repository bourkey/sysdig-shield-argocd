# Configuration Guide

## Environment Variables

### Sysdig Agent
- `SYSDIG_AGENT_ACCESS_KEY`: Access key from secret
- `COLLECTOR`: Backend URL (default: collector.sysdigcloud.com)
- `COLLECTOR_PORT`: Backend port (default: 6443)
- `SECURE`: Enable secure connection (default: true)

### Regional Backends
- **US1**: `collector.sysdigcloud.com` (default)
- **US2**: `us2.app.sysdig.com`
- **EU1**: `eu1.app.sysdig.com`
- **AU1**: `au1.app.sysdig.com`

## ConfigMap Settings

### Agent Log Levels
- **Dev**: `debug` - Verbose logging
- **Staging**: `info` - Standard logging
- **Production**: `warning` - Minimal logging

### Admission Controller Policies
- `denyOnError`: false (dev), true (production)
- `bypassNamespaces`: kube-system, kube-public, sysdig-shield

## Resource Limits by Environment

| Component | Dev | Staging | Production |
|-----------|-----|---------|------------|
| Agent (CPU) | 100m-500m | 300m-750m | 500m-1000m |
| Agent (Mem) | 256Mi-512Mi | 384Mi-768Mi | 512Mi-1Gi |
| Admission (CPU) | 100m-300m | 150m-400m | 200m-500m |
| Admission (Mem) | 128Mi-256Mi | 192Mi-384Mi | 256Mi-512Mi |

See overlay patches for complete configuration.
