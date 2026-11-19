
#!/usr/bin/env bash
# Linux Server Hardening - auditd Configuration Validation

set -u

RULES_FILE="/etc/audit/rules.d/department-monitoring.rules"
AUDIT_KEY="department_changes"

DEPARTMENTS=(
    management
    developers
    it-support
    finance
    human-resources
    marketing
)

passed=0
failed=0

pass() {
    printf '[PASS] %s\n' "$1"
    ((passed += 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    ((failed += 1))
}

if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

echo "Linux Server Hardening - auditd Validation"
echo "=========================================="

if ! command -v auditctl >/dev/null 2>&1; then
    echo "ERROR: auditctl is not installed or not in PATH."
    exit 1
fi

status=$(auditctl -s 2>/dev/null) || {
    echo "ERROR: Unable to retrieve auditd status."
    exit 1
}

rules=$(auditctl -l 2>/dev/null) || {
    echo "ERROR: Unable to retrieve loaded audit rules."
    exit 1
}

if grep -q '^enabled 1$' <<< "$status"; then
    pass "Auditing is enabled"
else
    fail "Auditing is not enabled"
fi

if grep -q '^lost 0$' <<< "$status"; then
    pass "No lost audit events reported"
else
    fail "Lost audit events detected or status unavailable"
fi

if [[ -f "$RULES_FILE" ]]; then
    pass "Persistent rules file exists"
else
    fail "Persistent rules file is missing"
fi

for department in "${DEPARTMENTS[@]}"; do
    expected="-w /srv/projects/$department -p wa -k $AUDIT_KEY"

    if grep -Fxq -- "$expected" <<< "$rules"; then
        pass "Loaded rule: $department"
    else
        fail "Loaded rule missing: $department"
    fi

    if [[ -f "$RULES_FILE" ]] &&
       grep -Fxq -- "$expected" "$RULES_FILE"; then
        pass "Persistent rule: $department"
    else
        fail "Persistent rule missing: $department"
    fi
done

echo
echo "Validation summary"
echo "=================="
printf 'Passed: %d\n' "$passed"
printf 'Failed: %d\n' "$failed"

if (( failed > 0 )); then
    exit 1
fi

exit 0
