# System Architecture

## 1. Project Overview

**BlackBox** is a Linux system administration and server-hardening project designed to simulate the management of a small organization's internal server.

The project demonstrates practical skills in:

- Linux user and group administration
    
- Role-based access control using Unix permissions and ACLs
    
- Password security and PAM configuration
    
- System auditing with `auditd`
    
- Automated backups using Bash and cron
    
- Backup integrity validation and recovery
    
- Secure operational procedures
    

The environment includes departmental user accounts, protected directories, automated administrative tasks, and mechanisms for validating system reliability.

## 2. Architecture Overview

```
                    BLACKBOX LINUX SERVER
                              |
          +-------------------+-------------------+
          |                   |                   |
    Identity & Access     Security & Audit    Backup & Recovery
          |                   |                   |
    Users and Groups       PAM Policies       Bash Automation
    Unix Permissions       Password Aging     tar + gzip
    SGID Directories       auditd             Integrity Checks
    POSIX ACLs             Audit Logs         30-Day Retention
          |                   |                   |
          +-------------------+-------------------+
                              |
                      System Operations
                              |
                    Root Cron Scheduler
                         02:00 Daily
```

This is a logical architecture diagram, not a representation of separate physical servers.

## 3. Identity and Access Management

BlackBox includes **21 user accounts** organized into departmental groups.

Access is managed through several complementary mechanisms:

|Mechanism|Purpose|
|---|---|
|Linux users and groups|Separate identities and departmental responsibilities|
|Unix permissions|Control read, write, and execute access|
|SGID directories|Preserve group ownership for newly created files|
|POSIX ACLs|Provide more granular access permissions|
|PAM|Enforce password-related security policies|
|Password aging|Support password lifecycle management|

A Bash script, `create-user.sh`, supports user provisioning and reduces repetitive administration.

### Design objective

Apply the **principle of least privilege** by limiting access according to each user's responsibilities.

## 4. Authentication Security

The authentication layer uses Linux PAM and password-management controls.

Implemented measures include:

- Password complexity requirements
    
- CrackLib-based password checks
    
- A custom password dictionary supporting English, Spanish, and Catalan
    
- Password aging policies
    
- Mandatory password changes at first login
    

These controls help reduce weak-password usage and improve account lifecycle management.

## 5. Auditing

BlackBox uses `auditd` as part of its system auditing configuration.

The auditing component provides a foundation for tracking security-relevant system activity and investigating administrative events.

Audit logs are distinct from application-specific logs such as the backup execution log.

## 6. Backup and Recovery Architecture

The finance backup subsystem protects data located in:

```
/home/cfo
/home/accountant1
```

Its production configuration uses:

|Component|Configuration|
|---|---|
|Backup script|`/usr/local/sbin/backup_finance.sh`|
|Backup directory|`/backup`|
|Backup format|`.tar.gz`|
|Execution identity|`root`|
|Schedule|Daily at 02:00|
|Scheduler|cron|
|Integrity checks|`gzip -t` and `tar -tzf`|
|Concurrency protection|`flock`|
|Retention policy|30 days, enabled|
|Execution log|`/backup/backup.log`|

The backup directory is restricted to root access.

Backup archives are created with restrictive permissions to reduce unauthorized access.

### Backup workflow

```
Cron Scheduler
      |
      v
Backup Script
      |
      v
Validate Environment
      |
      v
Acquire Execution Lock
      |
      v
Create Temporary Archive
      |
      v
Validate GZIP and TAR
      |
      v
Publish Verified Archive
      |
      v
Record Execution Results
      |
      v
Apply Retention Policy
```

The script is designed to reject an attempt to overwrite an existing backup for the same date.

### Recovery validation

The project includes a controlled restoration test in an isolated directory.

Restored files were compared against their original versions using `cmp` to verify content consistency.

## 7. Security Design Decisions

Several design decisions improve the security and maintainability of the environment.

**Restricted execution:** Administrative scripts and protected backup data are managed through root privileges.

**Separation of responsibilities:** Departmental groups and ACLs support access restrictions.

**Backup integrity:** Archives are validated before being published as completed backups.

**Concurrency protection:** File locking reduces the risk of simultaneous backup executions.

**Retention management:** A configurable retention policy limits the accumulation of old archives.

**Auditability:** Execution logs record backup activity and retention operations.

**Recovery testing:** Restoration and file comparison provide stronger evidence than archive creation alone.

## 8. Project Scope and Limitations

BlackBox is a practical Linux administration project, not a fully redundant production infrastructure.

Current scope includes local backup automation and validation. The documented environment does not establish:

- Off-site or geographically redundant backups
    
- A complete disaster recovery site
    
- Centralized monitoring and alerting
    
- Verified recovery-time or recovery-point objectives
    
- Full production high-availability guarantees
    

The backup v2 implementation passed laboratory tests and was deployed to the production script path. Its cron schedule is configured; successful execution of v2 by cron should be documented separately when corresponding logs are available.

## 9. Related Documentation

- [Security Hardening](security-hardening.md)
    
- [Backup and Recovery](backup-and-recovery.md)
    
- [Testing and Validation](testing-and-validation.md)
    

---

**Project:** Linux Server Hardening  
**Focus:** Linux System Administration · Security · Automation · Backup and Recovery