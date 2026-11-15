# Automated Backup & Recovery

## 1. Overview

This module implements an automated backup and recovery solution for the finance department of the BlackBox Linux server.

The objective is to protect sensitive departmental data through scheduled backups, integrity verification, restricted permissions, concurrency protection, retention management, and recovery testing.

The solution uses standard Linux tools and Bash scripting rather than relying on a third-party backup platform.

**Technologies:** Linux · Bash · cron · tar · gzip · flock · find · cmp

## 2. Project Objectives

The backup system was designed to meet the following requirements:

- Automatically back up finance department directories.
- Run daily without manual intervention.
- Prevent simultaneous backup executions.
- Avoid overwriting existing backups.
- Verify archive integrity before publishing a backup.
- Restrict access to backup files.
- Maintain execution logs for troubleshooting and auditing.
- Apply a configurable 30-day retention policy.
- Demonstrate successful file restoration.

## 3. Backup Architecture

### 3.1 Protected Directories

The backup system protects two finance-related home directories:

```text
/home/cfo
/home/accountant1
```

These directories simulate sensitive financial information managed by different organizational roles.

### 3.2 Production Configuration

| Component | Configuration |
|---|---|
| Server | BlackBox Linux |
| Backup script | `/usr/local/sbin/backup_finance.sh` |
| Source directories | `/home/cfo`, `/home/accountant1` |
| Backup destination | `/backup` |
| Archive format | `.tar.gz` |
| Backup frequency | Daily |
| Scheduled execution | 02:00 |
| Execution account | root |
| Scheduler | cron |
| Retention period | 30 days |
| Retention status | Enabled |
| Backup log | `/backup/backup.log` |

### 3.3 Logical Workflow

```text
              BLACKBOX LINUX SERVER
                       |
                       v
              Root Cron Scheduler
                  02:00 Daily
                       |
                       v
              backup_finance.sh
                       |
                       v
           Validate Execution Context
                       |
                       v
             Acquire flock Lock
                       |
                       v
           Validate Source Directories
                       |
                       v
            Create Temporary Archive
                       |
                       v
            Verify GZIP Integrity
                       |
                       v
             Verify TAR Structure
                       |
                       v
           Publish Verified Backup
                       |
                       v
             Write Execution Log
                       |
                       v
          Apply 30-Day Retention Policy
```

## 4. Backup Automation with Bash

The backup process is implemented using a Bash script.

The script uses strict error handling:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

These settings help detect command failures, unset variables, and pipeline errors.

### 4.1 Execution Privileges

The script requires root privileges.

```bash
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: this script requires root privileges." >&2
    exit 1
fi
```

This requirement ensures that the backup process runs with the permissions needed to access the protected finance directories.

### 4.2 Restrictive File Creation

The script applies:

```bash
umask 077
```

This restricts permissions on newly created files and directories.

The final backup archive is explicitly assigned mode `600`, allowing access only to its owner.

### 4.3 Source Validation

Before creating a backup, the script verifies that the required source directories exist.

```bash
for source in /home/cfo /home/accountant1; do
    if [[ ! -d "$source" ]]; then
        exit 1
    fi
done
```

This prevents the script from silently creating an incomplete backup when a required directory is missing.

## 5. Concurrency Protection

Simultaneous executions could interfere with backup creation or retention operations.

BlackBox uses `flock` to prevent concurrent executions.

```bash
LOCK="/run/lock/blackbox-finance-backup.lock"

exec 9>"$LOCK"

if ! flock -n 9; then
    echo "ERROR: another backup is already running." >&2
    exit 1
fi
```

The script attempts to acquire a non-blocking exclusive lock.

If another process already holds the lock, the new execution exits instead of continuing.

## 6. Archive Creation and Integrity Verification

### 6.1 Temporary Archive Creation

The script creates a temporary archive inside the backup destination.

```bash
TEMPORARY="$(mktemp "$DESTINATION/.finance-$DATE.XXXXXXXX.tar.gz")"
```

The temporary file is used to avoid exposing an incomplete archive under its final filename.

### 6.2 TAR and GZIP

The backup is created using:

```bash
tar -czf "$TEMPORARY" -C / home/cfo home/accountant1
```

The `-C /` option allows the archive to store relative paths such as:

```text
home/cfo/
home/accountant1/
```

This supports controlled restoration into an alternative destination.

### 6.3 GZIP Integrity Check

After archive creation, the script verifies the compressed data:

```bash
gzip -t "$TEMPORARY"
```

If this check fails, the archive is not published as a successful backup.

### 6.4 TAR Structure Check

The script also checks that the archive can be listed:

```bash
tar -tzf "$TEMPORARY" > /dev/null
```

These checks detect certain archive corruption and format problems.

They do not replace periodic restoration testing or guarantee that every source file was captured consistently while applications were modifying it.

## 7. Preventing Backup Overwrites

BlackBox generates date-based archive names:

```text
finance-YYYY-MM-DD.tar.gz
```

Example:

```text
finance-2026-11-15.tar.gz
```

Before creating the backup, the script checks whether the destination filename already exists.

The verified temporary archive is published using a hard link:

```bash
ln -- "$TEMPORARY" "$ARCHIVE"
```

Because the destination must not already exist, this operation prevents replacing an existing backup with the same name.

The temporary filename is then removed.

This approach also avoids exposing a partially written archive under the final filename.

## 8. Backup Security

Financial backup archives may contain confidential information.

The solution applies restrictive filesystem permissions.

| Resource | Permissions | Purpose |
|---|---|---|
| `/backup` | `700` | Restrict directory access to root |
| Backup archives created by v2 | `600` | Restrict file access to root |
| Production backup script | `700` | Restrict execution and modification |
| Backup execution log | Restricted | Protect operational information |

The production script is owned by `root:root`.

Example verification commands:

```bash
sudo ls -ld /backup
sudo ls -l /usr/local/sbin/backup_finance.sh
sudo ls -l /backup/
```

**Security limitation:** filesystem permissions do not provide encryption. A future improvement would be to encrypt backup archives and maintain an off-site copy.

## 9. Automated Scheduling with Cron

The backup script is configured in the root user's crontab.

```cron
0 2 * * * /usr/local/sbin/backup_finance.sh
```

This expression schedules execution every day at **02:00**, according to the server's configured time zone.

The configuration can be inspected using:

```bash
sudo crontab -l
```

The production script was deployed to the path referenced by cron.

The v2 script passed functional laboratory tests. Successful execution by the scheduler itself should be confirmed using subsequent production logs.

## 10. Backup Retention Policy

### 10.1 Retention Objective

The backup system implements a configurable retention policy intended to remove old daily archives.

The production configuration uses:

```bash
RETENTION_DAYS=30
ENABLE_RETENTION=true
```

### 10.2 Retention Selection

The script searches for matching backup files using `find`.

The selection is restricted to:

- The configured backup destination.
- Files located directly inside that directory.
- Names matching the finance backup naming pattern.
- Files older than the configured retention threshold.
- Files other than the newly created backup.

Example selection logic:

```bash
find "$DESTINATION" \
    -maxdepth 1 \
    -type f \
    -name 'finance-????-??-??.tar.gz' \
    ! -name "$(basename "$ARCHIVE")" \
    -mtime "+$((RETENTION_DAYS - 1))" \
    -print
```

The policy is based on filesystem modification time, not the date embedded in the filename.

The retention process runs after successful backup creation and integrity verification.

### 10.3 Retention Testing

The retention feature was validated in isolated laboratory directories.

A simulated historical archive was created:

```text
finance-2026-09-01.tar.gz
```

The final laboratory execution produced:

```text
OK: backup created and verified
Exit code: 0
```

The execution log confirmed that the historical test archive was deleted and the new backup was preserved.

Example translated log sequence:

```text
Starting finance backup
Backup successfully created and verified
Starting retention check (30 days)
RETENTION: deleted finance-2026-09-01.tar.gz
Retention completed successfully
```

The retention policy was enabled in the production script after laboratory validation.

**Important:** retention removes files permanently. Historical archives requiring long-term preservation should be stored outside the automated deletion scope.

## 11. Backup Logging

The script records operations in:

```text
/backup/backup.log
```

Logged events include:

- Backup start.
- Successful archive creation.
- Integrity verification outcome.
- Retention checks.
- Individual retention deletions.
- Detected errors and warnings.

Example inspection:

```bash
sudo tail -n 30 /backup/backup.log
```

Logging supports troubleshooting and operational review.

However, a log file alone does not provide proactive alerting. Monitoring and failure notifications remain possible future improvements.

## 12. Recovery and Restoration Testing

Creating a backup is not sufficient to prove that data can be recovered.

BlackBox includes a controlled restoration test.

### 12.1 Archive Validation

A production backup was checked using:

```bash
sudo gzip -t /backup/finance-2026-11-15.tar.gz
sudo tar -tzf /backup/finance-2026-11-15.tar.gz
```

Both checks completed successfully during the validation process.

### 12.2 Controlled Restoration

The archive was extracted into an isolated directory under `/root` rather than overwriting the original finance directories.

The restoration process used the following approach:

```bash
sudo mkdir -p /root/blackbox-restore-test

sudo tar -xzf /backup/finance-2026-11-15.tar.gz \
    -C /root/blackbox-restore-test \
    --no-same-owner
```

The `--no-same-owner` option avoids restoring archived file ownership.

### 12.3 File Comparison

Restored test files were compared against their originals using:

```bash
cmp ORIGINAL_FILE RESTORED_FILE
```

The validation included test files from both protected finance directories.

The compared files matched, demonstrating successful recovery of the selected test data.

This test validates the tested archive and selected files; it does not establish that every historical backup has been restored successfully.

## 13. Testing and Validation Results

The following results were obtained during the project.

| Test | Result |
|---|---|
| Bash syntax validation | Passed |
| Backup creation | Passed |
| GZIP integrity verification | Passed |
| TAR structure verification | Passed |
| Controlled restoration | Passed |
| Restored file comparison | Passed |
| Duplicate backup prevention | Passed |
| Restrictive archive permissions | Passed |
| Retention dry run | Passed |
| Retention deletion in isolated laboratory | Passed |
| Retention operation logging | Passed |
| Production v2 deployment | Completed |
| Root cron configuration | Verified |
| First scheduled production execution of v2 | Not yet evidenced in this documentation |

### Final Laboratory Evidence

The final isolated test was executed on **November 15, 2026, at 04:58:56**.

Observed results:

- Successful backup creation.
- Exit code `0`.
- New archive size approximately 23 KB.
- Archive permissions `600`.
- Historical test archive removed.
- Retention completion recorded in the log.

## 14. Operational Considerations

The current implementation has several important operational characteristics.

**Same-day execution:** The script rejects a second backup using an existing date-based filename.

**Retention dependency:** Retention runs after successful backup creation. If the backup fails or the same-day archive already exists, the retention stage is not reached.

**Storage scope:** Backups are stored locally on the BlackBox server.

**Application consistency:** TAR-based filesystem backups do not automatically provide application-consistent snapshots of files being actively modified.

**Restore scope:** Controlled restoration was validated for selected test files.

**Monitoring:** Logs are available, but centralized alerting is not part of the documented implementation.

## 15. Future Improvements

Potential enhancements include:

- Encrypted backup archives.
- Off-site backup replication.
- Automated notifications on backup failures.
- Centralized monitoring and log collection.
- Periodic scheduled restoration tests.
- Disk-space monitoring.
- Filesystem snapshots for improved consistency.
- Defined recovery objectives (RPO and RTO).
- More advanced backup versioning.

These features are proposed improvements, not implemented functionality.

## 16. Skills Demonstrated

This module demonstrates practical experience with:

- Linux server administration
- Bash scripting and automation
- Cron scheduling
- TAR and GZIP archive management
- File integrity verification
- Concurrency control with `flock`
- Secure filesystem permissions
- Backup retention management
- Operational logging
- Backup restoration and validation
- Safe deployment practices

## 17. Related Documentation

- [System Architecture](Architecture.md)
- [User Management](user-management.md)
- [File Permissions](file-permissions.md)
- [Password Security](password-security.md)
- [User Automation](user-automation.md)

---

**Project:** BlackBox — Linux Server Hardening

**Module:** Automated Finance Backup & Recovery

**Focus:** Linux Administration · Bash · Cron · Backup Security · Retention · Disaster Recovery Fundamentals
