[🇪🇸 Leer en Español](README.es.md)

# linux-server-hardening

>  Linux server hardening lab covering user management, access control, system auditing, Bash automation, and backups.  

---

### 🖥️ System Environment / Entorno del Sistema
![Terminal output showing system specifications with Fastfetch](screenshots/Tabby_QsrQolBKm3.png)


## Security Implementation & Technical Documentation

BlackBox is a Linux system administration and security lab designed to simulate a corporate environment with departmental access restrictions and controlled access to financial resources.

The following documentation describes configurations implemented and validated on the server.

### 1. User & Group Management

**21 local user accounts** were identified across seven organizational and administrative groups, including Finance, Management, Human Resources, Marketing, Developers, IT Support, and Administrators.

Key concepts demonstrated:

- Linux user and group administration
- Department-based group membership
- Role-based access organization using Unix groups
- Account and group verification using `id`, `getent`, and `/etc/passwd`

**Documentation:** [User & Group Management](docs/user-management.md) | [Versión en español](docs/user-management.es.md)

### 2. Departmental Access Control — SGID & POSIX ACLs

Implemented departmental shared directories under `/srv/projects/` using Linux ownership, permissions, SGID, and POSIX Access Control Lists.

**Verified configuration:**

| Department | Directory | Permissions | SGID |
|---|---|---|---|
| Finance | `/srv/projects/finance` | `2770` + ACL | Enabled |
| Management | `/srv/projects/management` | `2770` | Enabled |
| Human Resources | `/srv/projects/human-resources` | `2770` | Enabled |
| Marketing | `/srv/projects/marketing` | `2770` | Enabled |
| Developers | `/srv/projects/developers` | `2770` | Enabled |

The Finance directory includes an additional POSIX ACL granting the CEO read and traversal permissions without granting write access.

**Access validation results:**

| Test | Expected behavior | Result |
|---|---|---|
| CEO → Finance | Read permitted | PASS |
| CEO → Finance | Write denied | PASS |
| Developer → Finance | Directory traversal denied | PASS |
| Accountant → Finance | Write permitted | PASS |

These tests validate directory-level access behavior. Individual file permissions and SGID inheritance behavior require separate testing.

**Documentation:** [File Permissions, SGID & POSIX ACLs](docs/file-permissions.md) | [Versión en español](docs/file-permissions.es.md)

### Technical Skills Demonstrated

`Linux Administration` · `User & Group Management` · `Unix Permissions` · `SGID` · `POSIX ACLs` · `Access Control Validation` · `Bash` · `Security Documentation`
