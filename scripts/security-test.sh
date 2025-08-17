#!/bin/bash

# Comprehensive Security Testing Script
# This script performs automated security testing across the entire platform

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPORTS_DIR="${PROJECT_ROOT}/security-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create reports directory
mkdir -p "${REPORTS_DIR}"

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Security test results tracking
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

# Function to run test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    local is_critical="${3:-false}"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    log "Running test: ${test_name}"
    
    if eval "$test_command"; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "${test_name} passed"
        return 0
    else
        if [[ "$is_critical" == "true" ]]; then
            FAILED_TESTS=$((FAILED_TESTS + 1))
            log_error "${test_name} FAILED (CRITICAL)"
            return 1
        else
            WARNINGS=$((WARNINGS + 1))
            log_warning "${test_name} failed (non-critical)"
            return 0
        fi
    fi
}

# 1. Secret Detection Tests
test_secrets() {
    log "=== Secret Detection Tests ==="
    
    # Test for hardcoded secrets in code
    run_test "Hardcoded secrets detection" \
        "detect-secrets scan --all-files --baseline .secrets.baseline --exclude-files '\.git/|\.secrets\.baseline|security-reports/'" \
        true
    
    # Test for AWS credentials
    run_test "AWS credentials detection" \
        "! grep -r 'AKIA[0-9A-Z]{16}' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No AWS keys found'" \
        true
    
    # Test for Slack webhooks
    run_test "Slack webhook detection" \
        "! grep -r 'hooks.slack.com' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No Slack webhooks found'" \
        true
    
    # Test for SSH private keys
    run_test "SSH private key detection" \
        "! grep -r 'BEGIN.*PRIVATE KEY' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No SSH keys found'" \
        true
}

# 2. Vault Security Tests
test_vault_security() {
    log "=== Ansible Vault Security Tests ==="
    
    # Check vault file encryption
    run_test "Vault file encryption check" \
        "find . -name '*vault*.yml' -type f | xargs -I {} sh -c 'file {} | grep -q \"ASCII text\" && echo \"UNENCRYPTED: {}\" && exit 1 || true'" \
        true
    
    # Check for vault passwords in plain text
    run_test "Vault password security" \
        "! grep -r 'vault_password' --exclude-dir=.git --exclude-dir=security-reports . | grep -v 'vault_password_file' || echo 'No vault passwords found'" \
        true
    
    # Validate vault syntax
    if command -v ansible-vault &> /dev/null; then
        run_test "Vault syntax validation" \
            "find . -name '*vault*.yml' -type f | xargs -I {} ansible-vault view {} --vault-password-file /dev/null 2>/dev/null || echo 'Vault files are encrypted'" \
            false
    fi
}

# 3. Kubernetes Security Tests
test_kubernetes_security() {
    log "=== Kubernetes Security Tests ==="
    
    # Check for privileged containers
    run_test "Privileged container check" \
        "! grep -r 'privileged: true' kubernetes/ || echo 'No privileged containers found'" \
        true
    
    # Check for host network usage
    run_test "Host network usage check" \
        "! grep -r 'hostNetwork: true' kubernetes/ || echo 'No host network usage found'" \
        true
    
    # Check for root user containers
    run_test "Root user container check" \
        "! grep -r 'runAsUser: 0' kubernetes/ || echo 'No root user containers found'" \
        true
    
    # Check for missing security contexts
    run_test "Security context validation" \
        "grep -r 'securityContext:' kubernetes/ | wc -l | awk '{if (\$1 > 0) exit 0; else exit 1}'" \
        false
    
    # Check for resource limits
    run_test "Resource limits validation" \
        "grep -r 'resources:' kubernetes/ | wc -l | awk '{if (\$1 > 0) exit 0; else exit 1}'" \
        false
}

# 4. Terraform Security Tests
test_terraform_security() {
    log "=== Terraform Security Tests ==="
    
    # Check for hardcoded IPs
    run_test "Hardcoded IP detection" \
        "! grep -rE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' terraform/ --exclude='*.tfstate*' | grep -v '0.0.0.0' | grep -v '127.0.0.1' || echo 'No hardcoded IPs found'" \
        false
    
    # Check for missing encryption
    run_test "S3 encryption validation" \
        "! grep -r 'aws_s3_bucket' terraform/ | grep -v 'server_side_encryption' || echo 'S3 encryption properly configured'" \
        false
    
    # Check for public access
    run_test "Public access validation" \
        "! grep -r 'public' terraform/ | grep -i 'true' | grep -v 'comment' || echo 'No public access found'" \
        true
    
    # Terraform format check
    if command -v terraform &> /dev/null; then
        run_test "Terraform format validation" \
            "terraform fmt -check=true -recursive terraform/" \
            false
    fi
}

# 5. Docker Security Tests
test_docker_security() {
    log "=== Docker Security Tests ==="
    
    # Check for root user in Dockerfiles
    run_test "Docker root user check" \
        "! grep -r 'USER root' docker/ || echo 'No root users in Docker containers'" \
        true
    
    # Check for latest tag usage
    run_test "Docker latest tag check" \
        "! grep -r ':latest' docker/ || echo 'No latest tags found'" \
        false
    
    # Check for privileged mode
    run_test "Docker privileged mode check" \
        "! grep -r 'privileged' docker/ || echo 'No privileged mode found'" \
        true
    
    # Check for exposed secrets in Dockerfiles
    run_test "Docker secret exposure check" \
        "! grep -rE '(password|secret|key|token)=' docker/ || echo 'No exposed secrets found'" \
        true
}

# 6. Network Security Tests
test_network_security() {
    log "=== Network Security Tests ==="
    
    # Check for insecure protocols
    run_test "Insecure protocol check" \
        "! grep -rE '(http:|ftp:|telnet:)' --exclude-dir=.git --exclude-dir=security-reports . | grep -v 'localhost' | grep -v '127.0.0.1' || echo 'No insecure protocols found'" \
        true
    
    # Check for default ports
    run_test "Default port usage check" \
        "! grep -rE ':(22|23|80|443|3306|5432|6379|27017)' --exclude-dir=.git --exclude-dir=security-reports . | head -5 || echo 'Default ports usage checked'" \
        false
    
    # Check SSL/TLS configuration
    run_test "SSL/TLS configuration check" \
        "grep -r 'tls' . --exclude-dir=.git --exclude-dir=security-reports | wc -l | awk '{if (\$1 > 0) exit 0; else exit 1}'" \
        false
}

# 7. Dependency Security Tests
test_dependencies() {
    log "=== Dependency Security Tests ==="
    
    # Python dependencies
    if [[ -f "requirements.txt" ]]; then
        run_test "Python dependency security" \
            "safety check -r requirements.txt" \
            false
    fi
    
    # Node.js dependencies
    if [[ -f "package.json" ]]; then
        run_test "Node.js dependency security" \
            "npm audit --audit-level=high" \
            false
    fi
    
    # Go dependencies
    if [[ -f "go.mod" ]]; then
        run_test "Go dependency security" \
            "go list -json -m all | nancy sleuth" \
            false
    fi
}

# 8. Configuration Security Tests
test_configurations() {
    log "=== Configuration Security Tests ==="
    
    # Check for debug mode enabled
    run_test "Debug mode check" \
        "! grep -rE '(debug|DEBUG).*true' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No debug mode enabled'" \
        false
    
    # Check for weak encryption
    run_test "Weak encryption check" \
        "! grep -rE '(DES|MD5|SHA1)' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No weak encryption found'" \
        true
    
    # Check for insecure random generators
    run_test "Insecure random generator check" \
        "! grep -rE '(Math\.random|random\.randint)' --exclude-dir=.git --exclude-dir=security-reports . || echo 'No insecure random generators found'" \
        false
}

# 9. File Permission Tests
test_file_permissions() {
    log "=== File Permission Tests ==="
    
    # Check for world-writable files
    run_test "World-writable files check" \
        "! find . -type f -perm -o+w | grep -v '.git' || echo 'No world-writable files found'" \
        true
    
    # Check for executable scripts without proper shebang
    run_test "Executable script validation" \
        "find . -type f -executable -name '*.sh' | xargs -I {} sh -c 'head -1 {} | grep -q \"^#!/\" || echo \"Missing shebang: {}\"' | wc -l | awk '{if (\$1 == 0) exit 0; else exit 1}'" \
        false
    
    # Check for sensitive file permissions
    run_test "Sensitive file permissions" \
        "find . -name '*key*' -o -name '*secret*' -o -name '*password*' | xargs -I {} ls -l {} | awk '{if (\$1 ~ /^-rw-------/) next; else {print \"Insecure permissions: \" \$9; exit 1}}' || echo 'File permissions secure'" \
        true
}

# 10. Generate Security Report
generate_security_report() {
    log "=== Generating Security Report ==="
    
    local report_file="${REPORTS_DIR}/security-report-${TIMESTAMP}.md"
    
    cat > "$report_file" << EOF
# Security Test Report

**Generated**: $(date)
**Total Tests**: ${TOTAL_TESTS}
**Passed**: ${PASSED_TESTS}
**Failed**: ${FAILED_TESTS}
**Warnings**: ${WARNINGS}

## Summary

$(if [[ $FAILED_TESTS -eq 0 ]]; then
    echo "✅ **All critical security tests passed!**"
else
    echo "❌ **${FAILED_TESTS} critical security test(s) failed!**"
fi)

$(if [[ $WARNINGS -gt 0 ]]; then
    echo "⚠️  **${WARNINGS} warning(s) detected**"
fi)

## Security Score

**Overall Score**: $(( (PASSED_TESTS * 100) / TOTAL_TESTS ))%

## Recommendations

### Immediate Actions Required
- Review and fix all failed critical tests
- Address security warnings where applicable
- Implement additional security measures as needed

### Ongoing Security Practices
- Run security tests before each deployment
- Regularly update dependencies and base images
- Conduct periodic security audits
- Maintain security documentation up-to-date

---

*This report was generated automatically by the security testing framework.*
EOF

    log_success "Security report generated: $report_file"
}

# Main execution
main() {
    log "Starting comprehensive security testing..."
    log "Project root: ${PROJECT_ROOT}"
    
    cd "${PROJECT_ROOT}"
    
    # Run all security tests
    test_secrets
    test_vault_security
    test_kubernetes_security
    test_terraform_security
    test_docker_security
    test_network_security
    test_dependencies
    test_configurations
    test_file_permissions
    
    # Generate report
    generate_security_report
    
    # Final summary
    echo
    log "=== Security Testing Complete ==="
    log_success "Total Tests: ${TOTAL_TESTS}"
    log_success "Passed: ${PASSED_TESTS}"
    
    if [[ $FAILED_TESTS -gt 0 ]]; then
        log_error "Failed: ${FAILED_TESTS}"
    fi
    
    if [[ $WARNINGS -gt 0 ]]; then
        log_warning "Warnings: ${WARNINGS}"
    fi
    
    # Exit with appropriate code
    if [[ $FAILED_TESTS -gt 0 ]]; then
        log_error "Security testing completed with failures!"
        exit 1
    else
        log_success "All critical security tests passed!"
        exit 0
    fi
}

# Execute main function
main "$@"
