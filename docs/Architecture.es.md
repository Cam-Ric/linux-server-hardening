# Arquitectura del sistema

## 1. Descripción general del proyecto

**Linux server hardening** es un proyecto práctico de administración y securización de servidores Linux (_Linux Server Hardening_), diseñado para simular la gestión de un servidor interno de una pequeña organización.

El proyecto demuestra conocimientos prácticos en:

- Administración de usuarios y grupos de Linux.
    
- Control de acceso basado en permisos Unix y listas de control de acceso (ACL).
    
- Seguridad de contraseñas y configuración de PAM.
    
- Auditoría del sistema mediante `auditd`.
    
- Automatización de copias de seguridad con Bash y cron.
    
- Verificación de integridad y recuperación de copias de seguridad.
    
- Procedimientos de administración seguros.
    

El entorno incluye cuentas de usuario organizadas por departamentos, directorios protegidos, tareas administrativas automatizadas y mecanismos para comprobar la fiabilidad del sistema.

## 2. Visión general de la arquitectura

```
                    SERVIDOR LINUX BLACKBOX
                              |
          +-------------------+-------------------+
          |                   |                   |
    Identidad y acceso   Seguridad y auditoría  Copias y recuperación
          |                   |                   |
    Usuarios y grupos     Políticas PAM         Automatización Bash
    Permisos Unix         Caducidad contraseñas tar + gzip
    Directorios SGID      auditd                Verificación integridad
    ACL POSIX             Registros auditoría   Retención de 30 días
          |                   |                   |
          +-------------------+-------------------+
                              |
                    Operaciones del sistema
                              |
                    Planificador cron (root)
                       Diario a las 02:00
```

Este diagrama representa la arquitectura lógica del proyecto, no una infraestructura formada por varios servidores físicos.

## 3. Gestión de identidades y accesos

BlackBox incluye **21 cuentas de usuario** organizadas en grupos departamentales.

El acceso a los recursos se administra mediante diferentes mecanismos complementarios:

|Mecanismo|Finalidad|
|---|---|
|Usuarios y grupos Linux|Separar identidades y responsabilidades departamentales|
|Permisos Unix|Controlar los accesos de lectura, escritura y ejecución|
|Directorios SGID|Mantener la propiedad de grupo de los archivos nuevos|
|ACL POSIX|Establecer permisos de acceso más específicos|
|PAM|Aplicar políticas de seguridad relacionadas con contraseñas|
|Caducidad de contraseñas|Gestionar el ciclo de vida de las credenciales|

Un script Bash, `create-user.sh`, facilita el aprovisionamiento de usuarios y reduce las tareas administrativas repetitivas.

### Objetivo de diseño

Aplicar el **principio de mínimo privilegio**, limitando el acceso a los recursos según las responsabilidades de cada usuario.

## 4. Seguridad de autenticación

La capa de autenticación utiliza PAM y mecanismos de gestión de contraseñas de Linux.

Las medidas implementadas incluyen:

- Requisitos de complejidad de contraseñas.
    
- Comprobaciones de contraseñas mediante CrackLib.
    
- Diccionario personalizado con términos en inglés, castellano y catalán.
    
- Políticas de caducidad de contraseñas.
    
- Cambio obligatorio de contraseña en el primer inicio de sesión.
    

Estos controles ayudan a reducir el uso de contraseñas débiles y mejoran la gestión de las cuentas durante su ciclo de vida.

## 5. Auditoría del sistema

BlackBox utiliza `auditd` como parte de su configuración de auditoría.

Este componente proporciona una base para registrar actividades relevantes para la seguridad e investigar determinados eventos administrativos.

Los registros de auditoría del sistema son independientes de los registros específicos de otras aplicaciones, como el log de ejecución de las copias de seguridad.

## 6. Arquitectura de copias de seguridad y recuperación

El subsistema de copias de seguridad del departamento financiero protege los datos almacenados en:

```
/home/cfo
/home/accountant1
```

Su configuración de producción utiliza:

|Componente|Configuración|
|---|---|
|Script de backup|`/usr/local/sbin/backup_finance.sh`|
|Directorio de destino|`/backup`|
|Formato|`.tar.gz`|
|Usuario de ejecución|`root`|
|Programación|Diariamente a las 02:00|
|Planificador|cron|
|Comprobaciones de integridad|`gzip -t` y `tar -tzf`|
|Protección contra concurrencia|`flock`|
|Política de retención|30 días, activada|
|Registro de ejecución|`/backup/backup.log`|

El acceso al directorio de copias de seguridad está restringido al usuario root.

Los nuevos archivos de backup se crean con permisos restrictivos para reducir el riesgo de accesos no autorizados.

### Flujo de ejecución del backup

```
Planificador cron
       |
       v
Script de backup
       |
       v
Validar el entorno
       |
       v
Adquirir bloqueo de ejecución
       |
       v
Crear archivo temporal
       |
       v
Verificar integridad GZIP y TAR
       |
       v
Publicar el backup verificado
       |
       v
Registrar los resultados
       |
       v
Aplicar la política de retención
```

El script está diseñado para impedir la sobrescritura de una copia de seguridad existente con la misma fecha.

### Validación de la recuperación

El proyecto incluye una prueba controlada de restauración en un directorio aislado.

Los archivos restaurados se compararon con sus versiones originales mediante `cmp` para verificar la coincidencia de su contenido.

## 7. Decisiones de diseño de seguridad

Las siguientes decisiones contribuyen a mejorar la seguridad y el mantenimiento del entorno.

**Ejecución restringida:** los scripts administrativos y los datos de backup protegidos se gestionan mediante privilegios de root.

**Separación de responsabilidades:** los grupos departamentales y las ACL permiten establecer restricciones de acceso.

**Integridad de las copias:** los archivos se verifican antes de publicarse como backups completados.

**Protección contra concurrencia:** el bloqueo mediante `flock` reduce el riesgo de ejecuciones simultáneas.

**Gestión de retención:** una política configurable limita la acumulación de copias antiguas.

**Trazabilidad:** los registros de ejecución documentan las operaciones de backup y retención.

**Pruebas de recuperación:** restaurar y comparar archivos proporciona una evidencia más sólida que comprobar únicamente la creación del backup.

## 8. Alcance y limitaciones

BlackBox es un proyecto práctico de administración Linux, no una infraestructura de producción con redundancia completa.

El alcance actual incluye la automatización y validación de copias de seguridad locales.

El entorno documentado no contempla:

- Copias de seguridad externas o geográficamente redundantes.
    
- Un entorno completo de recuperación ante desastres.
    
- Monitorización y alertas centralizadas.
    
- Objetivos de tiempo de recuperación (RTO) o punto de recuperación (RPO) verificados.
    
- Garantías de alta disponibilidad propias de una infraestructura empresarial.
    

La versión v2 del sistema de backups superó las pruebas de laboratorio y fue desplegada en la ruta del script de producción.

La tarea de cron está configurada; la ejecución automática correcta de v2 deberá documentarse por separado cuando se disponga de los registros correspondientes.

## 9. Documentación relacionada

### Administración de identidades y seguridad

- [Gestión de usuarios](user-management.es.md)
    
- [Permisos de archivos, grupos y SGID](file-permissions.es.md)
    
- [Seguridad de contraseñas](password-security.es.md)
    
- [Automatización de usuarios](user-automation.es.md)
    

### Arquitectura y recuperación

- [Arquitectura del sistema — English](Architecture.md)
    
- [Copias de seguridad y recuperación](backup-and-recovery.es.md) _(pendiente de publicación)_
    

---

**Proyecto:** BlackBox — Linux Server Hardening

**Áreas técnicas:** Administración Linux · Seguridad · Automatización · Copias de seguridad y recuperación
