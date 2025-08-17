#!/bin/bash

# Kubernetes Secrets Check Script
# Detects hardcoded secrets in Kubernetes manifests

set -e

echo "🔍 Checking Kubernetes manifests for hardcoded secrets..."

EXIT_CODE=0

if [ ! -d "kubernetes/" ]; then
    echo "✅ No kubernetes directory found"
    exit 0
fi

# Check for hardcoded secrets (excluding proper secret references)
POTENTIAL_SECRETS=$(grep -r "password\|secret\|key\|token" kubernetes/ \
    --include="*.yaml" --include="*.yml" \
    | grep -v "secretKeyRef" \
    | grep -v "secretName" \
    | grep -v "valueFrom" \
    | grep -v "name: .*secret" \
    | grep -v "metadata:" \
    | grep -v "kind: Secret" \
    | grep -v "type: Opaque" \
    | grep -E ":.*['\"][^'\"]*['\"]" || true)

if [ -n "$POTENTIAL_SECRETS" ]; then
    echo "❌ Potential hardcoded secrets found:"
    echo "$POTENTIAL_SECRETS"
    echo ""
    echo "Fix by using proper Kubernetes secrets:"
    echo "  valueFrom:"
    echo "    secretKeyRef:"
    echo "      name: my-secret"
    echo "      key: password"
    EXIT_CODE=1
fi

# Check for base64 encoded values that might be secrets
BASE64_SECRETS=$(grep -r "data:" kubernetes/ \
    --include="*.yaml" --include="*.yml" \
    -A 5 | grep -E ":.*[A-Za-z0-9+/]{20,}={0,2}$" || true)

if [ -n "$BASE64_SECRETS" ]; then
    echo "⚠️  Warning: Found base64 encoded data (verify these are not secrets):"
    echo "$BASE64_SECRETS"
    echo ""
fi

# Check for webhooks or API endpoints
WEBHOOK_URLS=$(grep -r "https://hooks\." kubernetes/ \
    --include="*.yaml" --include="*.yml" || true)

if [ -n "$WEBHOOK_URLS" ]; then
    echo "❌ Webhook URLs found in manifests:"
    echo "$WEBHOOK_URLS"
    echo "Move webhook URLs to secrets or configmaps"
    EXIT_CODE=1
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ No hardcoded secrets found in Kubernetes manifests"
else
    echo "❌ Kubernetes secrets check failed"
fi

exit $EXIT_CODE
