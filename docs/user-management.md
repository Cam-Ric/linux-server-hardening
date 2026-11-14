# User and Group Management

## Overview

BlackBox is a Linux server lab that simulates departmental access management in an organization handling sensitive business information. Local user accounts are assigned to functional groups to support role-based administration and filesystem permissions.

This document describes the **observed account and group configuration**. It does not claim that account provisioning, password expiration, or PAM restrictions have been tested here.

## Verified account inventory

The account inventory was obtained from `/etc/passwd` by selecting UIDs >= 1000 and excluding UID 65534. This selection is useful for this lab, but is not a universal definition of a human user account.

| Group | Accounts | Count |
| --- | --- | ---: |
| `marketing` | `mkt1`, `mkt2`, `marketing-lead` | 3 |
| `human-resources` | `hr1`, `hr2`, `hr3` | 3 |
| `finance` | `accountant1`, `accountant2`, `cfo`, `subcfo` | 4 |
| `management` | `manager1`, `manager2`, `manager3`, `ceo` | 4 |
| `developers` | `dev1`, `dev2`, `dev3` | 3 |
| `it-support` | `it-01`, `it-02`, `it-03` | 3 |
| `admins107-13` | `devops` | 1 |
| **Total** | | **21** |

The `devops` account was also observed in the `sudo` and `users` groups. These are supplementary group memberships, not additional accounts.

## Verification commands

List accounts selected by UID:

```bash
awk -F: '$3 >= 1000 && $3 != 65534 {print $1 " -> " $6}' /etc/passwd
```

Inspect each account's group memberships:

```bash
awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read -r user; do
    printf '%-20s -> ' "$user"
    id -nG "$user"
done
```

List locally resolved groups with GID >= 1000 (review results manually; system groups such as `nogroup` can appear):

```bash
getent group | awk -F: '$3 >= 1000 {print $1}'
```

## Security design

Department-specific groups provide a basis for limiting access to shared resources. Group membership is not sufficient by itself: effective access also depends on directory permissions and any POSIX ACLs. The verified filesystem controls are documented in [File Permissions and Departmental Access Control](file-permissions.md).

## Scope and evidence

**Verified:** 21 account names, their home-directory paths, and observed group memberships.

**Not yet validated in this documentation:** account-creation automation, password aging, PAM time restrictions, account lifecycle operations, and least-privilege sudo policy.

> Portfolio note: These are fictional lab account names. Before publishing screenshots, review terminal output for host-specific identifiers or sensitive information.
