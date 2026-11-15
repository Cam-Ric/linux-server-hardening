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

```
/home/cfo
/home/accountant1
```

These directories simulate sensitive financial information managed by different organizational roles.

### 3.2 Production Configuration

|Component|Configuration|
|---|---|
|Server|BlackBox Linux|
|Backup script|`/usr/local/sbin/backup_finance.sh`|
|Source directories|`/home/cfo`, `/home/accountant1`|
|Backup destination|`/backup`|
|Archive format|`.tar.gz`|
|Backup frequency|Daily|
|Scheduled execution|02:00|
|Execution account|root|
|Scheduler|cron|
|Retention period|30 days|
|Retention status|Enabled|
|Backup log|`/backup/backup.log`|

### 3.3 Logical Workflow

```
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

```
#!/usr/bin/env bash
set -Eeuo pipefail
```

These settings help detect command failures, unset variables, and pipeline errors.

### 4.1 Execution Privileges

The script requires root privileges.

```
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: this script requires root privileges." >&2
    exit 1
fi
```

This requirement ensures that the backup process runs with the permissions needed to access the protected finance directories.

### 4.2 Restrictive File Creation

The script applies:

```
umask 077
```

This restricts permissions on newly created files and directories.

The final backup archive is explicitly assigned mode `600`, allowing access only to its owner.

### 4.3 Source Validation

Before creating a backup, the script verifies that the required source directories exist.

```
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

```
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

```
TEMPORARY="$(mktemp "$DESTINATION/.finance-$DATE.XXXXXXXX.tar.gz")"
```

The temporary file is used to avoid exposing an incomplete archive under its final filename.

### 6.2 TAR and GZIP

The backup is created using:

```
tar -czf "$TEMPORARY" -C / home/cfo home/accountant1
```

The `-C /` option allows the archive to store relative paths such as:

```
home/cfo/
home/accountant1/
```

This supports controlled restoration into an alternative destination.

### 6.3 GZIP Integrity Check

After archive creation, the script verifies the compressed data:

```
gzip -t "$TEMPORARY"
```

If this check fails, the archive is not published as a successful backup.

### 6.4 TAR Structure Check

The script also checks that the archive can be listed:

```
tar -tzf "$TEMPORARY" > /dev/null
```

These checks detect certain archive corruption and format problems.

They do not replace periodic restoration testing or guarantee that every source file was captured consistently while applications were modifying it.

## 7. Preventing Backup Overwrites

BlackBox generates date-based archive names:

```
finance-YYYY-MM-DD.tar.gz
```

Example:

```
finance-2026-11-15.tar.gz
```

Before creating the