
#!/usr/bin/env bash
# Linux Server Hardening - Finance Backup Validation
# Read-only validation of production backups.
# Temporary extraction is automatically cleaned up.

set -Eeuo pipefail

BACKUP_SCRIPT="/usr/local/sbin/backup_finance.sh"
BACKUP_DIR="/backup"
RETENTION_DAYS=30

passed=0
failed=0
warnings=0

pass() {
    printf '[PASS] %s\n' "$1"
    ((passed += 1))
}

fail() {
    printf '[FAIL] %s\n' "$1"
    ((failed += 1))
}

warn() {
    printf '[WARN] %s\n' "$1"
    ((warnings += 1))
}

cleanup() {
    if [[ -n "${RESTORE_DIR:-}" ]]; then
        rm -rf -- "$RESTORE_DIR"
    fi
}

trap cleanup EXIT

if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: Run this script with sudo."
    exit 1
fi

echo "Linux Server Hardening - Backup Validation"
echo "=========================================="

# 1. Validate production script.

if [[ -f "$BACKUP_SCRIPT" && -x "$BACKUP_SCRIPT" ]]; then
    pass "Production backup script exists and is executable"
else
    fail "Production backup script missing or not executable"
fi

if [[ -f "$BACKUP_SCRIPT" ]] &&
   bash -n "$BACKUP_SCRIPT"; then
    pass "Production backup script syntax"
else
    fail "Production backup script syntax"
fi

# 2. Validate source directories.

for source in /home/cfo /home/accountant1; do
    if [[ -d "$source" ]]; then
        pass "Source directory exists: $source"
    else
        fail "Source directory missing: $source"
    fi
done

# 3. Validate backup directory.

if [[ ! -d "$BACKUP_DIR" || -L "$BACKUP_DIR" ]]; then
    fail "Backup directory missing or unsafe"
    exit 1
fi

pass "Backup directory exists and is not a symlink"

permissions=$(stat -c '%a' "$BACKUP_DIR")

if [[ "$permissions" == "700" ]]; then
    pass "Backup directory permissions: 700"
else
    fail "Backup directory permissions: $permissions"
fi

# 4. Verify required commands.

for cmd in tar gzip flock find stat mktemp sort date; do
    if command -v "$cmd" >/dev/null 2>&1; then
        pass "Required command available: $cmd"
    else
        echo "ERROR: Missing required command: $cmd"
        exit 1
    fi
done

# 5. Verify retention configuration.

if [[ -f "$BACKUP_SCRIPT" ]] &&
   grep -Eq '^RETENTION_DAYS=30$' "$BACKUP_SCRIPT" &&
   grep -Eq '^ENABLE_RETENTION=true$' "$BACKUP_SCRIPT"; then
    pass "30-day retention configured"
else
    fail "30-day retention configuration"
fi

# 6. Find latest production backup by filename date.

LATEST_BACKUP=""

while IFS= read -r -d '' file; do
    filename="${file##*/}"
    backup_date="${filename#finance-}"
    backup_date="${backup_date%.tar.gz}"

    # Ignore invalid calendar dates.
    if [[ "$(date -d "$backup_date" +%F 2>/dev/null)" != "$backup_date" ]]; then
        continue
    fi

    if [[ -z "$LATEST_BACKUP" || "$file" > "$LATEST_BACKUP" ]]; then
        LATEST_BACKUP="$file"
    fi
done < <(
    find "$BACKUP_DIR" -maxdepth 1 -type f \
        -name 'finance-????-??-??.tar.gz' -print0
)

if [[ -z "$LATEST_BACKUP" ]]; then
    fail "No production backup archives found"
    exit 1
fi

pass "Latest backup found: ${LATEST_BACKUP##*/}"

# 7. Validate archive permissions and integrity.

permissions=$(stat -c '%a' "$LATEST_BACKUP")

if [[ "$permissions" == "600" ]]; then
    pass "Backup archive permissions: 600"
else
    fail "Backup archive permissions: $permissions"
fi

if gzip -t "$LATEST_BACKUP"; then
    pass "GZIP integrity verification"
else
    fail "GZIP integrity verification"
    exit 1
fi

if tar -tzf "$LATEST_BACKUP" >/dev/null; then
    pass "TAR archive readability"
else
    fail "TAR archive readability"
    exit 1
fi

CONTENTS=$(tar -tzf "$LATEST_BACKUP")

for directory in home/cfo/ home/accountant1/; do
    if grep -Fxq "$directory" <<< "$CONTENTS"; then
        pass "Backup includes: $directory"
    else
        fail "Backup missing: $directory"
    fi
done

# 8. Test recovery in an isolated temporary directory.

RESTORE_DIR=$(mktemp -d)

if tar -xzf "$LATEST_BACKUP" \
    -C "$RESTORE_DIR" \
    --no-same-owner \
    --no-same-permissions; then
    pass "Temporary backup restoration"
else
    fail "Temporary backup restoration"
fi

for directory in home/cfo home/accountant1; do
    if [[ -d "$RESTORE_DIR/$directory" ]]; then
        pass "Restored directory: $directory"
    else
        fail "Restored directory missing: $directory"
    fi
done

# 9. Check retention without deleting anything.

expired_count=0

while IFS= read -r -d '' file; do
    warn "Expired backup detected: ${file##*/}"
    ((expired_count += 1))
done < <(
    find "$BACKUP_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'finance-????-??-??.tar.gz' \
        -mtime "+$((RETENTION_DAYS - 1))" \
        -print0
)

if (( expired_count == 0 )); then
    pass "No expired production backups detected"
fi

# 10. Final report.

echo
echo "Validation summary"
echo "=================="
printf 'Passed:   %d\n' "$passed"
printf 'Failed:   %d\n' "$failed"
printf 'Warnings: %d\n' "$warnings"

if (( failed > 0 )); then
    exit 1
fi

exit 0
