#!/bin/bash
# Network Policy Validation Script

set -e

echo "🔍 Validating Network Policies..."

# Check default deny exists
if kubectl get networkpolicy default-deny-all -n sysdig-shield &>/dev/null; then
    echo "✅ Default deny policy exists"
else
    echo "❌ Default deny policy missing"
    exit 1
fi

# Check component policies
for policy in sysdig-agent-egress admission-controller-ingress admission-controller-egress node-analyzer-egress kspm-collector-egress dns-egress; do
    if kubectl get networkpolicy $policy -n sysdig-shield &>/dev/null; then
        echo "✅ NetworkPolicy $policy exists"
    else
        echo "❌ NetworkPolicy $policy missing"
        exit 1
    fi
done

echo "✅ Network policy validation passed"
