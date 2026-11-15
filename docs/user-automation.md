# Automated User Provisioning

## Overview

BlackBox includes a Bash-based user provisioning workflow designed to simplify the creation of local Linux accounts while enforcing departmental access controls and password security requirements.

The automation combines account creation, group assignment, password initialization and password aging configuration.

## Script

Location in the repository:

`scripts/create-user.sh`

The script is intended to be executed with administrative privileges.

Example:

```
sudo bash scripts/create-user.sh newemployee finance
```

## Supported Departments

The provisioning workflow supports the following existing Linux groups:

- `finance`
    
- `management`
    
- `human-resources`
    
- `marketing`
    
- `developers`
    
- `it-support`
    

The script validates the requested group against an allowlist.

It does not automatically create missing departments.

## Provisioning Workflow

The script performs the following operations:

1. Verifies administrative privileges.
    
2. Validates the number of arguments.
    
3. Validates the username format.
    
4. Checks the requested department against an allowlist.
    
5. Rejects duplicate usernames.
    
6. Verifies that the target Linux group exists.
    
7. Requests administrator confirmation.
    
8. Creates the account and home directory.
    
9. Assigns the departmental primary group.
    
10. Invokes `passwd` to initialize the password.
    
11. Applies the password aging policy.
    
12. Forces a password change at first login.
    
13. Displays account information for verification.
    

## Account Creation

The user account is created using:

```
useradd -m -k /etc/skel -g "$GROUP" -s /bin/bash "$USERNAME"
```

This command creates a home directory, initializes it from `/etc/skel`, assigns the departmental primary group and configures Bash as the login shell.

## Password Security Integration

The script invokes:

```
passwd "$USERNAME"
```

Password quality is enforced through the system PAM configuration, including `pam_pwquality` and the configured multilingual CrackLib dictionary.

The policy requires at least 12 characters, two uppercase letters, two digits, two special characters and one lowercase letter.

Additional checks address username similarity, consecutive character-class repetition and dictionary-based passwords.

## Password Aging

The final password aging policy is:

```
chage -m 1 -M 360 -W 30 "$USERNAME"
chage -d 0 "$USERNAME"
```

This configures:

|Setting|Value|
|---|---|
|Minimum password age|1 day|
|Maximum password age|360 days|
|Expiration warning|30 days|
|First-login password change|Required|

The first-login expiration requirement helps ensure that a temporary password assigned during provisioning is replaced by the account owner.

## Validation

The temporary account `test-finance` was used to test the provisioning workflow and duplicate-account rejection.

The account was subsequently deleted.

A separate temporary account, `test-pam`, was used during password security testing.

Useful validation commands:

```
id test-pam
getent passwd test-pam
sudo passwd -S test-pam
sudo chage -l test-pam
```

The final aging settings were checked on the temporary test account.

## Limitations and Security Considerations

- The script requires administrative privileges.
    
- Department groups must exist before provisioning.
    
- Account creation is not automatically rolled back if a later step fails.
    
- The script relies on PAM for password quality checks.
    
- Passwords must not be stored in the script or committed to GitHub.
    
- Password aging settings apply to newly provisioned accounts; existing accounts require separate updates.
    
- The script is intended for local Linux account provisioning, not centralized identity management.
    

## Related Documentation

- [Password Security Policy](password-security.md)
    
- [Spanish version](user-automation.es.md)
    

## Project Context

This workflow is part of **BlackBox — Linux Server Hardening**, demonstrating practical Bash scripting, Linux identity management, PAM integration and administrative automation.