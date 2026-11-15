# Copias de seguridad automatizadas y recuperación

## 1. Descripción general

Este módulo implementa una solución automatizada de copias de seguridad y recuperación para el departamento financiero del servidor Linux BlackBox.

El objetivo es proteger los datos sensibles del departamento mediante copias programadas, comprobaciones de integridad, permisos restrictivos, protección frente a ejecuciones simultáneas, gestión de retención y pruebas de restauración.

La solución utiliza herramientas estándar de Linux y scripts Bash, sin depender de una plataforma externa de copias de seguridad.

**Tecnologías utilizadas:** Linux · Bash · cron · tar · gzip · flock · find · cmp

## 2. Objetivos del proyecto

El sistema de copias de seguridad se diseñó para cumplir los siguientes requisitos:

- Realizar automáticamente copias de seguridad de los directorios del departamento financiero.
    
- Ejecutarse diariamente sin intervención manual.
    
- Impedir ejecuciones simultáneas del proceso.
    
- Evitar la sobrescritura de copias existentes.
    
- Verificar la integridad de los archivos antes de publicarlos como copias válidas.
    
- Restringir el acceso a los archivos de backup.
    
- Mantener registros de ejecución para facilitar el diagnóstico y la auditoría.
    
- Aplicar una política configurable de retención de 30 días.
    
- Demostrar la recuperación de archivos mediante pruebas de restauración.
    

## 3. Arquitectura del sistema de copias

### 3.1 Directorios protegidos

El sistema realiza copias de seguridad de dos directorios del departamento financiero:

```
/home/cfo
/home/accountant1
```

Estos directorios simulan información financiera sensible gestionada por diferentes perfiles de una organización.

### 3.2 Configuración de producción

|Componente|Configuración|
|---|---|
|Servidor|BlackBox Linux|
|Script de backup|`/usr/local/sbin/backup_finance.sh`|
|Directorios de origen|`/home/cfo`, `/home/accountant1`|
|Directorio de destino|`/backup`|
|Formato de archivo|`.tar.gz`|
|Frecuencia|Diaria|
|Hora programada|02:00|
|Usuario de ejecución|root|
|Planificador|cron|
|Periodo de retención|30 días|
|Estado de la retención|Activada|
|Registro de ejecución|`/backup/backup.log`|

### 3.3 Flujo lógico de ejecución