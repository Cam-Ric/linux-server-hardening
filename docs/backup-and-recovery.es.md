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

```text
/home/cfo
/home/accountant1
```

Estos directorios simulan información financiera sensible gestionada por diferentes perfiles de una organización.

### 3.2 Configuración de producción

| Componente | Configuración |
|---|---|
| Servidor | BlackBox Linux |
| Script de backup | `/usr/local/sbin/backup_finance.sh` |
| Directorios de origen | `/home/cfo`, `/home/accountant1` |
| Directorio de destino | `/backup` |
| Formato de archivo | `.tar.gz` |
| Frecuencia | Diaria |
| Hora programada | 02:00 |
| Usuario de ejecución | root |
| Planificador | cron |
| Periodo de retención | 30 días |
| Estado de la retención | Activada |
| Registro de ejecución | `/backup/backup.log` |

### 3.3 Flujo lógico de ejecución

```text
               SERVIDOR LINUX BLACKBOX
                         |
                         v
                Planificador cron
                  Diario a las 02:00
                         |
                         v
                backup_finance.sh
                         |
                         v
             Validar entorno de ejecución
                         |
                         v
             Adquirir bloqueo con flock
                         |
                         v
             Validar directorios de origen
                         |
                         v
              Crear archivo temporal
                         |
                         v
              Verificar integridad GZIP
                         |
                         v
              Verificar estructura TAR
                         |
                         v
              Publicar backup verificado
                         |
                         v
              Registrar la ejecución
                         |
                         v
             Aplicar retención de 30 días
```

## 4. Automatización mediante Bash

El proceso de backup está implementado mediante un script Bash.

El script utiliza un modo de ejecución estricto:

```bash
#!/usr/bin/env bash
set -Eeuo pipefail
```

Esta configuración ayuda a detectar errores de ejecución, variables no definidas y fallos en las tuberías de comandos.

### 4.1 Privilegios de ejecución

El script requiere privilegios de root.

```bash
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: este script requiere root." >&2
    exit 1
fi
```

Este requisito permite que el proceso acceda a los directorios financieros protegidos con los permisos necesarios.

### 4.2 Creación de archivos con permisos restrictivos

El script establece:

```bash
umask 077
```

Esta máscara restringe los permisos de los archivos y directorios creados durante la ejecución.

Además, al archivo final de backup se le asignan explícitamente permisos `600`, de modo que únicamente su propietario pueda leerlo o modificarlo.

### 4.3 Validación de los directorios de origen

Antes de crear la copia, el script comprueba que existen los directorios requeridos.

```bash
for origen in /home/cfo /home/accountant1; do
    if [[ ! -d "$origen" ]]; then
        exit 1
    fi
done
```

Esto evita generar silenciosamente una copia incompleta cuando falta alguno de los directorios.

## 5. Protección frente a ejecuciones simultáneas

La ejecución simultánea de varios procesos podría interferir en la creación de copias o en las operaciones de retención.

BlackBox utiliza `flock` para impedir ejecuciones concurrentes.

```bash
LOCK="/run/lock/blackbox-finance-backup.lock"

exec 9>"$LOCK"

if ! flock -n 9; then
    echo "ERROR: ya existe un backup en ejecucion." >&2
    exit 1
fi
```

El script intenta adquirir un bloqueo exclusivo sin esperar.

Si otro proceso ya mantiene ese bloqueo, la nueva ejecución finaliza sin continuar.

## 6. Creación de archivos y verificación de integridad

### 6.1 Creación de un archivo temporal

El script crea un archivo temporal dentro del directorio de destino.

```bash
TEMPORAL="$(mktemp "$DESTINO/.finance-$FECHA.XXXXXXXX.tar.gz")"
```

El archivo temporal permite evitar que una copia incompleta aparezca con el nombre definitivo.

### 6.2 Compresión mediante TAR y GZIP

La copia se genera utilizando:

```bash
tar -czf "$TEMPORAL" -C / home/cfo home/accountant1
```

La opción `-C /` permite almacenar rutas relativas dentro del archivo:

```text
home/cfo/
home/accountant1/
```

Esto facilita realizar restauraciones controladas en ubicaciones alternativas.

### 6.3 Verificación de integridad GZIP

Una vez creado el archivo, se comprueba la integridad de los datos comprimidos:

```bash
gzip -t "$TEMPORAL"
```

Si la comprobación falla, la copia no se publica como un backup completado correctamente.

### 6.4 Verificación de la estructura TAR

El script también comprueba que se puede listar el contenido del archivo:

```bash
tar -tzf "$TEMPORAL" > /dev/null
```

Estas comprobaciones permiten detectar determinados problemas de corrupción o formato.

No sustituyen las pruebas periódicas de restauración ni garantizan una captura consistente de archivos modificados simultáneamente por otras aplicaciones.

## 7. Prevención de sobrescrituras

BlackBox utiliza nombres de archivo basados en la fecha:

```text
finance-YYYY-MM-DD.tar.gz
```

Por ejemplo:

```text
finance-2026-11-15.tar.gz
```

Antes de iniciar el backup, el script comprueba si ya existe un archivo con el nombre de destino.

El archivo temporal verificado se publica mediante un enlace físico:

```bash
ln -- "$TEMPORAL" "$ARCHIVO"
```

Esta operación evita reemplazar un archivo existente con el mismo nombre.

Posteriormente, se elimina el nombre temporal.

De esta forma, también se evita exponer una copia parcialmente escrita bajo su nombre definitivo.

## 8. Seguridad de las copias de seguridad

Los archivos de backup del departamento financiero pueden contener información confidencial.

Por este motivo, la solución utiliza permisos restrictivos.

| Recurso | Permisos | Finalidad |
|---|---|---|
| `/backup` | `700` | Restringir el acceso al directorio |
| Nuevos archivos de backup creados por v2 | `600` | Restringir lectura y escritura al propietario |
| Script de producción | `700` | Restringir ejecución y modificación |
| Registro de ejecución | Restringidos | Proteger la información operativa |

El script de producción pertenece a `root:root`.

Los permisos pueden comprobarse mediante:

```bash
sudo ls -ld /backup
sudo ls -l /usr/local/sbin/backup_finance.sh
sudo ls -l /backup/
```

**Limitación de seguridad:** los permisos del sistema de archivos no equivalen al cifrado de datos. Una posible mejora sería cifrar los archivos de backup y mantener copias externas.

## 9. Programación automática mediante cron

El script está configurado en el crontab del usuario root.

```cron
0 2 * * * /usr/local/sbin/backup_finance.sh
```

Esta expresión programa su ejecución **todos los días a las 02:00**, según la zona horaria configurada en el servidor.

La configuración puede consultarse mediante:

```bash
sudo crontab -l
```

La versión v2 fue desplegada en la ruta utilizada por cron.

El script superó las pruebas funcionales de laboratorio. La ejecución correcta por parte del planificador debe comprobarse mediante los registros posteriores de producción.

## 10. Política de retención de copias

### 10.1 Objetivo de la retención

El sistema implementa una política configurable destinada a eliminar copias diarias antiguas.

La configuración de producción utiliza:

```bash
RETENTION_DAYS=30
ENABLE_RETENTION=true
```

### 10.2 Selección de archivos antiguos

El script utiliza `find` para localizar archivos que cumplen las condiciones de retención.

La selección se limita a:

- Archivos situados directamente en el directorio de backups.
- Nombres que coincidan con el patrón de copias financieras.
- Archivos que superen el umbral de antigüedad configurado.
- Archivos distintos de la copia recién creada.

Ejemplo de la lógica de selección:

```bash
find "$DESTINO" \
    -maxdepth 1 \
    -type f \
    -name 'finance-????-??-??.tar.gz' \
    ! -name "$(basename "$ARCHIVO")" \
    -mtime "+$((RETENTION_DAYS - 1))" \
    -print
```

La antigüedad se calcula utilizando la fecha de modificación del archivo, no la fecha incluida en su nombre.

La retención se ejecuta después de crear y verificar correctamente la copia.

### 10.3 Pruebas de retención

La funcionalidad se validó utilizando directorios de laboratorio aislados.

Se creó un archivo histórico simulado:

```text
finance-2026-09-01.tar.gz
```

La ejecución final del laboratorio devolvió:

```text
OK: backup creado y verificado
Codigo de salida: 0
```

El registro confirmó que el archivo histórico de prueba fue eliminado y que la copia nueva permaneció intacta.

Fragmento del registro de la prueba:

```text
[2026-11-15 04:58:56] Iniciando backup de finance
[2026-11-15 04:58:56] Backup correcto y verificado: /root/blackbox-v2-test/retention-v3/finance-2026-11-15.tar.gz
[2026-11-15 04:58:56] Iniciando comprobacion de retencion (30 dias)
[2026-11-15 04:58:56] RETENCION: eliminado /root/blackbox-v2-test/retention-v3/finance-2026-09-01.tar.gz
[2026-11-15 04:58:56] Retencion completada correctamente
```

La retención fue activada en el script de producción después de superar estas pruebas.

**Importante:** la retención elimina archivos de forma permanente. Las copias históricas que deban conservarse a largo plazo deben almacenarse fuera del alcance de la eliminación automática.

## 11. Registro de operaciones

El script registra sus operaciones en:

```text
/backup/backup.log
```

Entre los eventos registrados se encuentran:

- Inicio del backup.
- Creación correcta del archivo.
- Resultado de las comprobaciones de integridad.
- Inicio de las comprobaciones de retención.
- Eliminación individual de copias antiguas.
- Errores y advertencias detectados.

Los registros pueden consultarse mediante:

```bash
sudo tail -n 30 /backup/backup.log
```

El registro facilita la resolución de incidencias y la revisión de las operaciones.

Sin embargo, mantener un archivo de log no equivale a disponer de alertas proactivas. La monitorización y las notificaciones de fallos son posibles mejoras futuras.

## 12. Recuperación y pruebas de restauración

Crear una copia de seguridad no es suficiente para demostrar que los datos pueden recuperarse.

BlackBox incluye una prueba de restauración controlada.

### 12.1 Validación del archivo

Se verificó una copia de producción mediante:

```bash
sudo gzip -t /backup/finance-2026-11-15.tar.gz
sudo tar -tzf /backup/finance-2026-11-15.tar.gz
```

Ambas comprobaciones finalizaron correctamente durante el proceso de validación.

### 12.2 Restauración controlada

El archivo se extrajo en un directorio aislado bajo `/root`, evitando sobrescribir los directorios financieros originales.

Se utilizó el siguiente procedimiento:

```bash
sudo mkdir -p /root/blackbox-restore-test

sudo tar -xzf /backup/finance-2026-11-15.tar.gz \
    -C /root/blackbox-restore-test \
    --no-same-owner
```

La opción `--no-same-owner` evita restaurar los propietarios originales almacenados en el archivo.

### 12.3 Comparación de archivos

Los archivos de prueba restaurados se compararon con los originales utilizando:

```bash
cmp ARCHIVO_ORIGINAL ARCHIVO_RESTAURADO
```

La validación incluyó archivos de prueba procedentes de ambos directorios financieros.

Los archivos comparados coincidieron, demostrando la recuperación correcta de los datos seleccionados.

Esta prueba valida el archivo utilizado y los ficheros seleccionados, pero no demuestra que todas las copias históricas hayan sido restauradas correctamente.

## 13. Resultados de las pruebas y validaciones

Durante el desarrollo del proyecto se obtuvieron los siguientes resultados:

| Prueba | Resultado |
|---|---|
| Validación de sintaxis Bash | Superada |
| Creación del backup | Superada |
| Verificación de integridad GZIP | Superada |
| Verificación de estructura TAR | Superada |
| Restauración controlada | Superada |
| Comparación de archivos restaurados | Superada |
| Prevención de backups duplicados | Superada |
| Permisos restrictivos | Superada |
| Simulación de retención | Superada |
| Eliminación por retención en laboratorio aislado | Superada |
| Registro de operaciones de retención | Superada |
| Despliegue de v2 en producción | Completado |
| Configuración del cron de root | Verificada |
| Primera ejecución automática de v2 | Sin evidencia registrada en esta documentación |

### Evidencia de la última prueba

La última prueba aislada se realizó el **15 de noviembre de 2026 a las 04:58:56**.

Resultados observados:

- Creación correcta de la copia de seguridad.
- Código de salida `0`.
- Nuevo archivo de aproximadamente 23 KB.
- Permisos `600`.
- Eliminación del archivo histórico de prueba.
- Finalización de la retención registrada en el log.

## 14. Consideraciones operativas

La implementación actual presenta las siguientes características.

**Ejecuciones durante el mismo día:** el script rechaza una segunda copia si ya existe un archivo con la fecha actual.

**Dependencia de la retención:** la retención se ejecuta después de crear correctamente el backup. Si la copia falla o ya existe un archivo con la misma fecha, no se alcanza la fase de retención.

**Almacenamiento:** las copias se guardan localmente en el servidor BlackBox.

**Consistencia de aplicaciones:** una copia de archivos mediante TAR no garantiza automáticamente la consistencia de datos modificados durante su creación.

**Alcance de las restauraciones:** se ha validado la recuperación de archivos de prueba seleccionados.

**Monitorización:** existen registros operativos, pero no se ha documentado un sistema centralizado de alertas.

## 15. Posibles mejoras futuras

Entre las mejoras que podrían incorporarse se encuentran:

- Cifrado de archivos de backup.
- Replicación de copias en una ubicación externa.
- Notificaciones automáticas ante fallos.
- Monitorización centralizada.
- Pruebas periódicas de restauración programadas.
- Supervisión del espacio disponible en disco.
- Uso de snapshots para mejorar la consistencia.
- Definición de objetivos RPO y RTO.
- Sistemas avanzados de versionado de copias.

Estas funcionalidades se plantean como mejoras futuras y no como características ya implementadas.

## 16. Competencias técnicas demostradas

Este módulo permite demostrar experiencia práctica en:

- Administración de servidores Linux.
- Programación y automatización con Bash.
- Programación de tareas mediante cron.
- Gestión de archivos TAR y GZIP.
- Verificación de integridad.
- Control de concurrencia con `flock`.
- Configuración de permisos restrictivos.
- Gestión de políticas de retención.
- Registro y análisis de operaciones.
- Restauración y validación de copias.
- Procedimientos de despliegue seguros.

## 17. Documentación relacionada

- [Arquitectura del sistema](Architecture.es.md)
- [Gestión de usuarios](user-management.es.md)
- [Permisos de archivos](file-permissions.es.md)
- [Seguridad de contraseñas](password-security.es.md)
- [Automatización de usuarios](user-automation.es.md)
- [English version](backup-and-recovery.md)

---

**Proyecto:** BlackBox — Linux Server Hardening

**Módulo:** Copias de seguridad automatizadas y recuperación

**Áreas técnicas:** Administración Linux · Bash · Cron · Seguridad de backups · Retención · Fundamentos de recuperación ante desastres
