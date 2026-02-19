#!/bin/bash
# RBAC Validation Script

set -e

echo "🔍 Validating RBAC policies..."

# Check for wildcard permissions
echo "Checking for wildcard permissions..."
WILDCARDS=$(kubectl get clusterroles -o json | jq -r '.items[] | select(.metadata.name | startswith("sysdig")) | select(.rules[]? | select(.resources[]? == "*" or .verbs[]? == "*")) | .metadata.name')

if [ -n "$WILDCARDS" ]; then
    echo "❌ Found wildcard permissions in: $WILDCARDS"
    exit 1
else
    echo "✅ No wildcard permissions found"
fi

# Verify ServiceAccounts exist
echo "Verifying ServiceAccounts..."
for sa in sysdig-agent sysdig-admission-controller sysdig-node-analyzer sysdig-kspm-collector; do
    if kubectl get serviceaccount $sa -n sysdig-shield &>/dev/null; then
        echo "✅ ServiceAccount $sa exists"
    else
        echo "❌ ServiceAccount $sa missing"
        exit 1
    fi
done

echo "✅ RBAC validation passed"
