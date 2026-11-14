
#!/usr/bin/env bash

set -u

DIR="/srv/projects/finance"
failures=0

check_access() {
    local user="$1"
    local permission="$2"
    local expected="$3"
    local description="$4"
    local actual

    if runuser -u "$user" -- test "$permission" "$DIR"; then
        actual=0
    else
        actual=1
    fi

    if [[ "$actual" -eq "$expected" ]]; then
        echo "[PASS] $description"
    else
        echo "[FAIL] $description"
        ((failures+=1))
    fi
}

if [[ "$EUID" -ne 0 ]]; then
    echo "Run this script with sudo."
    exit 2
fi

echo "=== BLACKBOX | FINANCE ACCESS CONTROL ==="

echo
echo "[1] DIRECTORY PERMISSIONS"
ls -ld "$DIR"

echo
echo "[2] POSIX ACL"
getfacl -p "$DIR"

echo
echo "[3] ACCESS VALIDATION"
check_access ceo -r 0 "CEO read permitted"
check_access ceo -w 1 "CEO write denied"
check_access dev1 -x 1 "Developer access denied"
check_access accountant1 -w 0 "Accountant write permitted"

echo
if [[ "$failures" -eq 0 ]]; then
    echo "RESULT: ALL ACCESS TESTS PASSED"
    exit 0
else
    echo "RESULT: $failures TEST(S) FAILED"
    exit 1
fi
