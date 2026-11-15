[🇬🇧 Read in English](README.md)

#  linux-server-hardening

> Laboratorio de seguridad en servidores Linux centrado en gestión de usuarios, control de acceso, auditoría, automatización en Bash y copias de seguridad.

---

### 🖥️ Entorno del Sistema
![Terminal output showing system specifications with Fastfetch](screenshots/Tabby_QsrQolBKm3.png)

## Implementación de Seguridad y Documentación Técnica

**BlackBox** es un laboratorio de administración y seguridad de sistemas Linux diseñado para simular un entorno corporativo con restricciones de acceso por departamentos y acceso controlado a recursos financieros.

La siguiente documentación describe las configuraciones implementadas y verificadas en el servidor.

# 1. Gestión de Usuarios y Grupos

Se identificaron **21 cuentas de usuario locales**, distribuidas entre siete grupos organizativos y administrativos: Finanzas, Dirección, Recursos Humanos, Marketing, Desarrollo, Soporte Informático y Administradores.

**Competencias técnicas demostradas:**

- Administración de usuarios y grupos en Linux.
- Organización de usuarios por departamentos.
- Gestión de accesos basada en roles mediante grupos Unix.
- Verificación de cuentas y pertenencia a grupos utilizando `id`, `getent` y `/etc/passwd`.

**Documentación:** [Gestión de Usuarios y Grupos](docs/user-management.es.md) | [Versión en inglés](docs/user-management.md)

# 2. Control de Acceso Departamental — SGID y ACLs POSIX

Se configuraron directorios compartidos por departamento en `/srv/projects/`, utilizando propietarios, grupos, permisos Unix, SGID y listas de control de acceso POSIX (ACLs).

**Configuración verificada:**

| Departamento | Directorio | Permisos | SGID |
|---|---|---|---|
| Finanzas | `/srv/projects/finance` | `2770` + ACL | Activado |
| Dirección | `/srv/projects/management` | `2770` | Activado |
| Recursos Humanos | `/srv/projects/human-resources` | `2770` | Activado |
| Marketing | `/srv/projects/marketing` | `2770` | Activado |
| Desarrollo | `/srv/projects/developers` | `2770` | Activado |

El directorio de Finanzas dispone de una ACL POSIX adicional que concede al usuario `ceo` permisos de lectura y recorrido del directorio, sin otorgarle permisos de escritura.

**Resultados de las pruebas de control de acceso:**

| Prueba | Comportamiento esperado | Resultado |
|---|---|---|
| CEO → Finanzas | Lectura permitida | CORRECTO |
| CEO → Finanzas | Escritura denegada | CORRECTO |
| Desarrollador → Finanzas | Acceso al directorio denegado | CORRECTO |
| Contable → Finanzas | Escritura permitida | CORRECTO |

Estas pruebas verifican el comportamiento de los permisos a nivel de directorio. Los permisos de los archivos individuales y la herencia efectiva mediante SGID requieren comprobaciones adicionales.

**Documentación:** [Permisos, SGID y ACLs POSIX](docs/file-permissions.es.md) | [Versión en inglés](docs/file-permissions.md)

### Competencias Técnicas Demostradas

`Administración Linux` · `Gestión de Usuarios y Grupos` · `Permisos Unix` · `SGID` · `ACLs POSIX` · `Control de Acceso` · `Bash` · `Documentación de Seguridad`

# 3. Seguridad de Contraseñas y Automatización de Usuarios

BlackBox implementa una política centralizada de seguridad de contraseñas mediante PAM, `pam_pwquality` y un diccionario personalizado de CrackLib que incluye inglés, castellano y catalán/valenciano.

La configuración incorpora requisitos de complejidad, comprobaciones de similitud con el usuario, validación mediante diccionarios, aplicación de las reglas a root y una política de caducidad de **1/360/30 días**, con cambio obligatorio de contraseña en el primer inicio de sesión.

Un script Bash automatiza la creación de usuarios locales, la asignación de grupos departamentales y la configuración de caducidad.

**Documentación técnica:**

- [Política de seguridad de contraseñas](docs/password-security.es.md)
- [Automatización de usuarios](docs/user-automation.es.md)
- [Password Security Policy — English](docs/password-security.md)
- [Automated User Provisioning — English](docs/user-automation.md)

# 4. Copias de seguridad automatizadas y recuperación

**Tecnologías:** `Linux` · `Bash` · `cron` · `tar` · `gzip` · `flock` · `find` · `cmp`

Implementación de un sistema automatizado de copias de seguridad y recuperación para el departamento financiero de BlackBox, centrado en la protección de datos, la fiabilidad operativa y la administración segura de servidores Linux.

**Características principales:**

- **Automatización diaria:** Copias programadas a las **02:00** mediante el crontab de root.
- **Protección de datos:** Backups de `/home/cfo` y `/home/accountant1`.
- **Verificación de integridad:** Comprobaciones GZIP y TAR antes de publicar cada archivo.
- **Protección contra concurrencia:** Bloqueo exclusivo con `flock` para impedir ejecuciones simultáneas.
- **Prevención de sobrescrituras:** Protección frente al reemplazo accidental de copias existentes.
- **Retención de 30 días:** Eliminación automática de copias antiguas mediante `find`, validada en un laboratorio aislado.
- **Permisos restrictivos:** Directorio de backups con permisos `700` y nuevos archivos con permisos `600`.
- **Pruebas de recuperación:** Restauración controlada y comparación de archivos mediante `cmp`.
- **Registro de operaciones:** Logs con marcas de tiempo para documentar copias, errores y operaciones de retención.

**Validación:** Se superaron las pruebas de creación de backups, integridad, restauración, prevención de duplicados y retención. La nueva versión del script fue desplegada y se verificó la configuración de la tarea diaria de cron.

**Documentación técnica:**

- [Copias de seguridad y recuperación — Español](docs/backup-and-recovery.es.md)
- [Backup & Recovery — English](docs/backup-and-recovery.md)
