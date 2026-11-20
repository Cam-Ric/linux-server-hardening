[🇬🇧 Read in English](README.md)

# Linux Server Hardening

> Laboratorio práctico de administración y securización de servidores Linux que abarca gestión de usuarios, control de accesos, seguridad de contraseñas, automatización con Bash, auditoría del sistema y copias de seguridad.

> **Estado del proyecto: En desarrollo activo.** Los controles de seguridad implementados se documentan con pruebas prácticas y evidencias. Las mejoras previstas se recogen en [Alcance del proyecto y futuras mejoras](#alcance-del-proyecto-y-futuras-mejoras).

---

## 🖥️ Entorno del sistema

![Información del sistema Linux Server Hardening mostrada mediante Fastfetch](screenshots/Tabby_QsrQolBKm3.png)

## Implementación de seguridad y documentación técnica

**Linux Server Hardening** es un laboratorio práctico de administración y seguridad Linux diseñado para simular un entorno empresarial con restricciones de acceso departamentales y acceso controlado a recursos financieros.

Las siguientes secciones describen las configuraciones implementadas y validadas en el servidor, incluyendo las decisiones técnicas, los controles de seguridad y las evidencias correspondientes.

---

# 1. Gestión de usuarios y grupos

### Descripción general

Linux Server Hardening incluye **21 cuentas de usuario locales**, distribuidas entre siete grupos organizativos y administrativos: Finanzas, Dirección, Recursos Humanos, Marketing, Desarrollo, Soporte IT y Administradores.

El modelo de gestión de identidades separa a los usuarios por departamentos y permite asignar y verificar sus pertenencias a los grupos correspondientes.

### Tecnologías y herramientas

`Linux` · `useradd` · `usermod` · `groupadd` · `id` · `getent` · `/etc/passwd`

### Implementación

- Creación y administración de cuentas de usuario locales.
- Organización de usuarios en grupos departamentales y administrativos.
- Configuración de pertenencia a grupos según las responsabilidades organizativas.
- Verificación de identidades y asignaciones mediante herramientas nativas de Linux.

### Validación y evidencias

Las cuentas y pertenencias a grupos se comprobaron mediante comandos como `id`, `getent` y la consulta de `/etc/passwd`.

![Validación del aprovisionamiento de usuarios en Linux Server Hardening](screenshots/user-provisioning-validation.png)

*Figura 1. Validación del aprovisionamiento y administración de cuentas de usuario en Linux Server Hardening.*

### Competencias técnicas demostradas

`Administración de usuarios Linux` · `Gestión de grupos` · `Verificación de identidades` · `Organización departamental` · `Administración de cuentas`

### Documentación técnica

- [Gestión de usuarios y grupos — Español](docs/user-management.es.md)
- [User & Group Management — English](docs/user-management.md)

---

# 2. Control de acceso departamental — SGID y ACL POSIX

### Descripción general

Se implementaron directorios compartidos por departamento bajo `/srv/projects/`, utilizando propietarios y grupos Linux, permisos Unix, SGID y listas de control de acceso POSIX (ACL).

El objetivo es restringir el acceso según las responsabilidades de cada departamento y permitir accesos adicionales expresamente autorizados.

### Tecnologías y herramientas

`Linux` · `chmod` · `chown` · `SGID` · `setfacl` · `getfacl` · `ACL POSIX`

### Implementación

Se verificó la siguiente configuración de directorios departamentales:

| Departamento | Directorio | Permisos | SGID |
|---|---|---|---|
| Finanzas | `/srv/projects/finance` | `2770` + ACL | Activado |
| Dirección | `/srv/projects/management` | `2770` | Activado |
| Recursos Humanos | `/srv/projects/human-resources` | `2770` | Activado |
| Marketing | `/srv/projects/marketing` | `2770` | Activado |
| Desarrollo | `/srv/projects/developers` | `2770` | Activado |

El directorio de Finanzas incorpora una ACL POSIX adicional que permite al CEO leer y recorrer el directorio, sin concederle permisos de escritura.

### Validación y evidencias

Las pruebas de control de acceso confirmaron el siguiente comportamiento:

| Prueba | Comportamiento esperado | Resultado |
|---|---|---|
| CEO → Finanzas | Lectura permitida | SUPERADA |
| CEO → Finanzas | Escritura denegada | SUPERADA |
| Desarrollador → Finanzas | Acceso al directorio denegado | SUPERADA |
| Contable → Finanzas | Escritura permitida | SUPERADA |

Estas pruebas validan el comportamiento de acceso a nivel de directorio. Los permisos de archivos individuales y la herencia de SGID requieren pruebas específicas adicionales.

![Validación de permisos y ACL del departamento financiero](screenshots/finance-acl-validation.png)

*Figura 2. Comprobación de las restricciones de acceso mediante permisos Unix y ACL POSIX.*

### Competencias técnicas demostradas

`Permisos Unix` · `Control de acceso departamental` · `Configuración SGID` · `Administración de ACL POSIX` · `Principio de mínimo privilegio` · `Validación de accesos`

### Documentación técnica

- [Permisos, SGID y ACL POSIX — Español](docs/file-permissions.es.md)
- [File Permissions, SGID & POSIX ACLs — English](docs/file-permissions.md)

---

# 3. Seguridad de contraseñas y automatización de usuarios

### Descripción general

Linux Server Hardening implementa una política centralizada de seguridad de contraseñas mediante PAM, `pam_pwquality` y un diccionario personalizado de CrackLib con términos en inglés, castellano y catalán/valenciano.

Un script de aprovisionamiento en Bash facilita la creación consistente de usuarios, la asignación de grupos departamentales y la configuración del ciclo de vida de las contraseñas.

### Tecnologías y herramientas

`Linux` · `PAM` · `pam_pwquality` · `CrackLib` · `chage` · `Bash` · `/etc/skel`

### Implementación

- Configuración de requisitos de complejidad de contraseñas.
- Implementación de comprobaciones de similitud con el nombre de usuario y validación mediante diccionarios.
- Aplicación de la política de contraseñas al usuario root.
- Creación de un diccionario multilingüe personalizado para la validación.
- Configuración de una **política de caducidad de 1/360/30 días**:
  - Antigüedad mínima: 1 día.
  - Antigüedad máxima: 360 días.
  - Aviso previo a la caducidad: 30 días.
- Configuración del cambio obligatorio de contraseña en el primer inicio de sesión.
- Automatización del aprovisionamiento de usuarios locales y su asignación a grupos mediante Bash.

### Validación y evidencias

Las pruebas incluyeron la validación del rechazo de contraseñas, la configuración de caducidad y el aprovisionamiento de usuarios.

![Validación del rechazo de contraseñas mediante PAM](screenshots/pam-password-rejection.png)

*Figura 3. Prueba de rechazo de contraseñas que incumplen la política de seguridad configurada.*

**Evidencias adicionales:**

- [Configuración de la política de contraseñas PAM](screenshots/pam-password-policy.png)
- [Validación de la caducidad de contraseñas](screenshots/password-aging-validation.png)
- [Diccionarios multilingües de CrackLib](screenshots/cracklib-multilingual-dictionaries.png)

### Competencias técnicas demostradas

`Configuración PAM` · `Aplicación de políticas de contraseñas` · `Securización de autenticación` · `Gestión del ciclo de vida de contraseñas` · `Scripting Bash` · `Automatización de usuarios`

### Documentación técnica

- [Seguridad de contraseñas — Español](docs/password-security.es.md)
- [Password Security Policy — English](docs/password-security.md)
- [Automatización de usuarios — Español](docs/user-automation.es.md)
- [Automated User Provisioning — English](docs/user-automation.md)

---

# 4. Copias de seguridad automatizadas y recuperación

### Descripción general

Se implementó una solución automatizada de copias de seguridad y recuperación para el departamento financiero de **Linux Server Hardening**, centrada en la protección de datos, la fiabilidad operativa y la administración segura del servidor.

El sistema combina un script Bash para la creación y gestión de backups con un validador desarrollado en Python, permitiendo comprobar de forma reproducible la integridad, seguridad y recuperación de las copias.

La ejecución diaria está programada mediante `cron` a las **02:00**, utilizando privilegios administrativos.

### Tecnologías y herramientas

`Linux` · `Bash` · `Python 3` · `cron` · `tar` · `gzip` · `flock` · `find` · `cmp` · `tarfile` · `pathlib` · `tempfile`

### Implementación

- **Automatización diaria:** Copias programadas a las **02:00** mediante el crontab de root.
- **Protección de datos:** Backups de `/home/cfo` y `/home/accountant1`.
- **Verificación de integridad:** Comprobaciones GZIP y TAR antes de publicar cada archivo.
- **Protección contra concurrencia:** Bloqueo exclusivo mediante `flock` para impedir ejecuciones simultáneas.
- **Prevención de sobrescrituras:** Protección frente al reemplazo accidental de copias existentes.
- **Retención de 30 días:** Eliminación automatizada de copias antiguas mediante `find`, validada previamente en un laboratorio aislado.
- **Permisos restrictivos:** Directorio `/backup` con permisos `700` y archivos de backup con permisos `600`.
- **Registro de operaciones:** Logs con marcas de tiempo para registrar ejecuciones, errores y operaciones de retención.
- **Recuperación controlada:** Restauración de archivos y comparación con los originales mediante `cmp`.
- **Validación automatizada:** Script Python independiente para comprobar el sistema sin ejecutar backups de producción ni eliminar archivos existentes.

### Validación y evidencias

#### Validación funcional y recuperación

Se realizaron pruebas manuales para comprobar el funcionamiento del sistema de backups.

| Prueba | Resultado |
|---|---|
| Creación del backup | SUPERADA |
| Verificación de integridad GZIP | SUPERADA |
| Verificación de estructura TAR | SUPERADA |
| Restauración controlada | SUPERADA |
| Comparación de archivos restaurados mediante `cmp` | SUPERADA |
| Prevención de copias duplicadas | SUPERADA |
| Permisos restrictivos | SUPERADA |
| Eliminación por retención en laboratorio aislado | SUPERADA |
| Registro de operaciones de retención en laboratorio | SUPERADA |
| Despliegue del script en producción | COMPLETADO |
| Configuración del cron de root | VERIFICADA |

![Validación de restauración de backups](screenshots/backup-restore-validation.png)

*Figura 4. Restauración controlada y comprobación de archivos recuperados.*

**Evidencia adicional:**

- [Verificación de integridad de backups](screenshots/backup-integrity.png)

#### Validación automatizada con Python

Se desarrolló `tests/backup-validation.py` para automatizar las comprobaciones del sistema de copias de seguridad utilizando exclusivamente bibliotecas estándar de Python.

El validador realiza las siguientes operaciones:

- Comprueba la existencia, permisos de ejecución y sintaxis del script Bash de producción.
- Verifica los directorios de origen y los permisos del almacenamiento.
- Comprueba la disponibilidad de las herramientas necesarias.
- Verifica la configuración de la política de retención de 30 días.
- Selecciona automáticamente el backup de producción más reciente según la fecha de su nombre.
- Comprueba la integridad GZIP y la lectura de la estructura TAR.
- Verifica que el archivo contiene los directorios financieros esperados.
- Revisa las rutas y los tipos de entradas antes de la extracción.
- Realiza una restauración temporal en un directorio aislado.
- Detecta backups que superan el umbral de retención sin eliminarlos.
- Genera resultados `PASS`, `FAIL` y `WARN`, con un código de salida apropiado para automatización.

**Resultados de la ejecución real:**

| Métrica | Resultado |
|---|---|
| Comprobaciones superadas | **21 PASS** |
| Comprobaciones fallidas | **0 FAIL** |
| Advertencias | **2 WARN** |
| Backup validado | `finance-2026-11-15.tar.gz` |
| Integridad GZIP y TAR | SUPERADA |
| Restauración temporal | SUPERADA |

Las dos advertencias identificaron copias antiguas correspondientes al **12 y 17 de octubre de 2026**.

Estos resultados demuestran que el validador detecta archivos que superan el período de retención. La eliminación automática en producción queda pendiente de confirmación mediante una ejecución de la versión actualizada del script.

![Validación automatizada de backups con Python](screenshots/backup-python-validation.png)

*Figura 5. Ejecución del validador Python con 21 comprobaciones correctas y detección de dos backups caducados.*

**Evidencia de detección de retención:**

![Detección de backups caducados](screenshots/backup-retention-detention.png)

*Figura 6. Identificación automática de archivos que superan el umbral de retención de 30 días.*

#### Programación y seguimiento operativo

La tarea está configurada en el crontab de root:

```cron
0 2 * * * /usr/local/sbin/backup_finance.sh
```

Se verificó que el servicio `cron` estaba activo y habilitado, y se confirmó mediante los registros del sistema que ejecutó el comando de backup el **15 de noviembre de 2026 a las 02:00**.

La versión actualizada del script se modificó el **18 de noviembre de 2026**. Por ello, queda pendiente confirmar una ejecución posterior que incluya la limpieza automática de backups caducados.

### Competencias técnicas demostradas

`Administración de backups Linux` · `Automatización Bash` · `Scripting Python` · `Programación cron` · `Verificación de integridad` · `Control de concurrencia` · `Gestión de retención` · `Permisos seguros` · `Recuperación de datos` · `Validación automatizada` · `Diagnóstico mediante logs`

### Documentación técnica

- [Copias de seguridad y recuperación — Español](docs/backup-and-recovery.es.md)
- [Backup & Recovery — English](docs/backup-and-recovery.md)
---

# 5. Auditoría de seguridad — auditd

### Descripción general

Se configuró Linux Audit (`auditd`) para registrar operaciones de escritura y cambios de atributos en seis directorios departamentales bajo `/srv/projects/`. Los eventos permiten identificar la ruta afectada, la operación ejecutada, el usuario y el resultado.

### Tecnologías y herramientas

`Linux` · `auditd` · `auditctl` · `augenrules` · `ausearch` · `/etc/audit/rules.d/`

### Implementación

- Definición de reglas departamentales en `/etc/audit/rules.d/department-monitoring.rules`, utilizando `-p wa` y la clave común `department_changes`.
- Configuración de auditoría para Dirección, Desarrollo, Soporte IT, Finanzas, Recursos Humanos y Marketing.
- Carga y comprobación de reglas activas mediante `augenrules --load` y `auditctl -l`.
- Análisis de eventos con `ausearch` para identificar comandos, rutas, llamadas al sistema, usuarios y resultados.

### Validación y evidencias

Se completaron nueve comprobaciones satisfactorias en cinco departamentos. La regla de Marketing se añadió a la configuración, pero no formó parte de estas pruebas de eventos.

| Departamento | Operaciones verificadas | Resultado |
|---|---|---|
| Dirección | Creación, modificación, cambio de permisos y eliminación | 4/4 SUPERADAS |
| Desarrollo | Creación de archivo (`dev1`) | SUPERADA |
| Soporte IT | Creación y modificación (`it-02`) | 2/2 SUPERADAS |
| Finanzas | Cambio de permisos (`subcfo`) | SUPERADA |
| Recursos Humanos | Eliminación (`hr3`) | SUPERADA |

La comprobación del subsistema de auditoría devolvió `enabled 1`, `lost 0` y `backlog 0`. Las reglas están almacenadas en el directorio de configuración persistente; no se ha probado su carga tras reiniciar.

![Reglas de auditoría departamental activas](screenshots/auditd-department-rules.png)

*Figura 5. Reglas departamentales cargadas en el subsistema de auditoría de Linux.*

**Evidencias adicionales:**

- [Evento de modificación de archivo en Soporte IT](screenshots/auditd-file-modification.png)
- [Evento de eliminación de archivo en Recursos Humanos](screenshots/auditd-file-deletion.png)

### Competencias técnicas demostradas

`Auditoría Linux` · `Configuración de reglas auditd` · `Monitorización de archivos` · `Análisis de eventos de seguridad` · `Trazabilidad de usuarios` · `Recopilación de evidencias`

### Documentación técnica

- [Auditoría de seguridad — Español](docs/security-auditing.es.md)
- [Security Auditing — English](docs/security-auditing.md)

---

## Arquitectura del sistema

Para consultar una visión global del entorno Linux Server Hardening, sus componentes de seguridad y la relación entre los módulos implementados:

- [Arquitectura del sistema — Español](docs/Architecture.es.md)
- [System Architecture — English](docs/Architecture.md)

---

## Alcance del proyecto y futuras mejoras

Linux Server Hardening es un laboratorio práctico de administración y seguridad Linux. Demuestra competencias de configuración, automatización y validación, pero no pretende representar una infraestructura empresarial de producción completa.

Entre las posibles mejoras futuras se encuentran:

- Ampliación de los escenarios de validación de `auditd` y de la cobertura de eventos de seguridad.
- Monitorización y alertas de seguridad centralizadas.
- Copias de seguridad cifradas y almacenadas externamente.
- Notificaciones automáticas ante fallos de backup.
- Pruebas periódicas y programadas de recuperación.
- Comprobaciones adicionales de cumplimiento de seguridad.

Estas mejoras se plantean como trabajo futuro, no como funcionalidades ya implementadas.

---

## Competencias técnicas generales

`Administración de sistemas Linux` · `Gestión de identidades y accesos` · `Securización de sistemas` · `PAM` · `Permisos Unix` · `SGID` · `ACL POSIX` · `Automatización Bash` · `Cron` · `Copias de seguridad y recuperación` · `Auditoría de seguridad` · `auditd` · `Documentación técnica`

---

**Linux Server Hardening — Linux Server Hardening**

*Administración práctica de Linux, implementación de controles de seguridad, automatización y validación técnica.*
