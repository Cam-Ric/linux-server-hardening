# Password Security Policy

## Overview

BlackBox implements a centralized password security policy using Linux PAM (Pluggable Authentication Modules), `pam_pwquality`, CrackLib and the `chage` utility.

The objective is to enforce password complexity, detect dictionary-based passwords, reduce predictable password patterns and manage password expiration for local Linux accounts.

The policy is integrated with the automated user provisioning workflow.

## Password Complexity Requirements

|Security control|Configuration|
|---|---|
|Minimum password length|12 characters|
|Uppercase letters|At least 2|
|Lowercase letters|At least 1|
|Digits|At least 2|
|Special characters|At least 2|
|Username similarity checks|Enabled|
|Maximum consecutive character-class repetition|3|
|Dictionary validation|Enabled|
|Root password quality enforcement|Enabled|

### PAM Configuration

Configuration file:

`/etc/security/pwquality.conf`

Relevant settings:

```
minlen = 12
ucredit = -2
lcredit = -1
dcredit = -2
ocredit = -2

usercheck = 1
usersubstr = 3
maxclassrepeat = 3

dictcheck = 1
dictpath = /usr/local/share/blackbox-dictionaries/es-en-va

enforce_for_root
```

Negative credit values require a minimum number of characters from the corresponding category.

The `usersubstr` setting provides additional checks against password content derived from the username.

The `maxclassrepeat` setting limits consecutive characters belonging to the same character class.

The `enforce_for_root` option enforces password quality checks when passwords are assigned by the system administrator.

## PAM Integration

The password policy is integrated into the system's PAM password stack.

Configuration file:

`/etc/pam.d/common-password`

Relevant entries observed on BlackBox:

```
password requisite pam_pwquality.so retry=25
password [success=1 default=ignore] pam_unix.so obscure use_authtok try_first_pass yescrypt
```

The `pam_pwquality` module validates password quality, while `pam_unix` manages local password updates using the configured hashing mechanism.

## Multilingual Dictionary Protection

BlackBox uses a custom CrackLib dictionary compiled from three language resources:

- English: `american-english`
    
- Spanish: `spanish`
    
- Catalan/Valencian: `catalan`
    

Source wordlists:

```
/usr/share/dict/american-english
/usr/share/dict/spanish
/usr/share/dict/catalan
```

The combined dictionary is generated using:

```
sudo mkdir -p /usr/local/share/blackbox-dictionaries

cat /usr/share/dict/american-english \
    /usr/share/dict/spanish \
    /usr/share/dict/catalan \
  | LC_ALL=C sort -u \
  | sudo /usr/sbin/cracklib-packer \
      /usr/local/share/blackbox-dictionaries/es-en-va
```

The compilation produced the following dictionary files:

```
es-en-va.hwm
es-en-va.pwd
es-en-va.pwi
```

The compilation reported 783,494 processed dictionary entries.

This multilingual configuration improves detection of passwords based on common vocabulary across the three languages. It does not guarantee detection of every weak or predictable password.

## Password Aging Policy

BlackBox uses the following account password aging policy:

|Parameter|Value|
|---|---|
|Minimum days between changes|1|
|Maximum password age|360 days|
|Expiration warning period|30 days|
|Password change at first login|Required|

Configuration commands:

```
chage -m 1 -M 360 -W 30 "$USERNAME"
chage -d 0 "$USERNAME"
```

The first command configures password aging. The second marks the password as expired, requiring a change at the first login.

The 360-day maximum is a laboratory policy decision, not a universal security recommendation. Modern guidance generally discourages arbitrary periodic password changes without evidence of compromise.

A suspected compromised password must be changed promptly, with administrator intervention when necessary.

## Validation

### PAM integration

```
grep -nE 'pam_pwquality|pam_unix' /etc/pam.d/common-password
```

### Password quality configuration

```
grep -E '^[[:space:]]*(minlen|ucredit|lcredit|dcredit|ocredit|usercheck|usersubstr|maxclassrepeat|dictcheck|dictpath|enforce_for_root)' \
  /etc/security/pwquality.conf
```

### Compiled dictionary

```
ls -lh /usr/local/share/blackbox-dictionaries/es-en-va.*
```

### Password aging

```
sudo chage -l test-pam
```

The temporary account `test-pam` was used to verify password aging settings.

The final configuration uses a minimum of 1 day, maximum of 360 days and a 30-day warning period.

Dictionary word detection was also tested using CrackLib.

## Security Considerations

- Password quality enforcement does not replace multi-factor authentication.
    
- Dictionary checks do not detect all compromised or predictable passwords.
    
- Password aging does not guarantee password confidentiality.
    
- Passwords and password hashes must never be committed to GitHub.
    
- PAM configuration changes should be tested while maintaining administrative access.
    
- The compiled CrackLib dictionary is a locally generated system artifact and is not required in the repository.
    

## Technologies

Linux · PAM · pam_pwquality · CrackLib · Bash · chage

## Project Context

This implementation forms part of **BlackBox — Linux Server Hardening**, a practical Linux system administration and security portfolio project.