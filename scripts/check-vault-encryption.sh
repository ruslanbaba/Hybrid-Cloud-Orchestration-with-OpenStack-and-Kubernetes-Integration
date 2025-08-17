#!/bin/bash

# Vault Encryption Check Script
# Ensures all Ansible vault files are properly encrypted

set -e

echo "🔍 Checking Ansible Vault encryption..."

EXIT_CODE=0

# Find all vault files
VAULT_FILES=$(find . -name "vault*.yml" -o -name "*vault*" -type f)

if [ -z "$VAULT_FILES" ]; then
    echo "✅ No vault files found"
    exit 0
fi

for file in $VAULT_FILES; do
    if [ -f "$file" ]; then
        # Check if file contains ANSIBLE_VAULT header
        if ! grep -q "ANSIBLE_VAULT" "$file"; then
            echo "❌ ERROR: $file is not encrypted!"
            echo "   Run: ansible-vault encrypt $file"
            EXIT_CODE=1
        else
            echo "✅ $file is properly encrypted"
        fi
        
        # Check if file contains any plaintext secrets patterns
        if grep -qE "(password|secret|key).*:" "$file" | grep -v "vault_encrypted_" | grep -v "ANSIBLE_VAULT"; then
            echo "⚠️  WARNING: $file may contain plaintext secrets"
            EXIT_CODE=1
        fi
    fi
done

if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ All vault files are properly encrypted"
else
    echo "❌ Vault encryption check failed"
    echo ""
    echo "To fix:"
    echo "  1. Encrypt vault files: ansible-vault encrypt <filename>"
    echo "  2. Use encrypted strings: ansible-vault encrypt_string 'secret' --name 'variable_name'"
    echo "  3. Never commit plaintext secrets"
fi

exit $EXIT_CODE
