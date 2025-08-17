#!/bin/bash

# Terraform Secrets Check Script
# Detects hardcoded secrets in Terraform files

set -e

echo "🔍 Checking Terraform files for hardcoded secrets..."

EXIT_CODE=0

if [ ! -d "infrastructure/terraform/" ]; then
    echo "✅ No terraform directory found"
    exit 0
fi

# Check for hardcoded secrets (excluding variables and random resources)
POTENTIAL_SECRETS=$(grep -r "password\|secret\|key\|token" infrastructure/terraform/ \
    --include="*.tf" --include="*.tfvars" \
    | grep -E "(=|:)" \
    | grep -v "var\." \
    | grep -v "random_" \
    | grep -v "data\." \
    | grep -v "local\." \
    | grep -v "# " \
    | grep -v "description" \
    | grep -v "variable \"" || true)

if [ -n "$POTENTIAL_SECRETS" ]; then
    echo "❌ Potential hardcoded secrets found:"
    echo "$POTENTIAL_SECRETS"
    echo ""
    echo "Fix by using variables:"
    echo "  variable \"db_password\" {"
    echo "    description = \"Database password\""
    echo "    type        = string"
    echo "    sensitive   = true"
    echo "  }"
    EXIT_CODE=1
fi

# Check for AWS access keys
AWS_KEYS=$(grep -r "AKIA[0-9A-Z]{16}" infrastructure/terraform/ \
    --include="*.tf" --include="*.tfvars" || true)

if [ -n "$AWS_KEYS" ]; then
    echo "❌ AWS access keys found:"
    echo "$AWS_KEYS"
    echo "Use AWS IAM roles or environment variables instead"
    EXIT_CODE=1
fi

# Check for private keys
PRIVATE_KEYS=$(grep -r "BEGIN.*PRIVATE.*KEY" infrastructure/terraform/ \
    --include="*.tf" --include="*.tfvars" || true)

if [ -n "$PRIVATE_KEYS" ]; then
    echo "❌ Private keys found:"
    echo "$PRIVATE_KEYS"
    echo "Use external key management or variables"
    EXIT_CODE=1
fi

# Check for webhook URLs
WEBHOOK_URLS=$(grep -r "https://hooks\." infrastructure/terraform/ \
    --include="*.tf" --include="*.tfvars" || true)

if [ -n "$WEBHOOK_URLS" ]; then
    echo "❌ Webhook URLs found:"
    echo "$WEBHOOK_URLS"
    echo "Use variables for webhook URLs"
    EXIT_CODE=1
fi

# Check for database connection strings
DB_CONNECTIONS=$(grep -r "://.*:.*@" infrastructure/terraform/ \
    --include="*.tf" --include="*.tfvars" || true)

if [ -n "$DB_CONNECTIONS" ]; then
    echo "❌ Database connection strings found:"
    echo "$DB_CONNECTIONS"
    echo "Use separate variables for host, user, and password"
    EXIT_CODE=1
fi

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ No hardcoded secrets found in Terraform files"
else
    echo "❌ Terraform secrets check failed"
fi

exit $EXIT_CODE
