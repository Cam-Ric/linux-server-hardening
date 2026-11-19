
#!/usr/bin/env bash
set -Eeuo pipefail

# Automated Finance Backup
# Daily backup with integrity checks and concurrency protection.

DESTINO="/backup"
FECHA="$(date +%F)"
ARCHIVO="$DESTINO/finance-$FECHA.tar.gz"
LOG="$DESTINO/backup.log"
LOCK="/run/lock/blackbox-finance-backup.lock"

# Require root privileges.
if [[ "$EUID" -ne 0 ]]; then
    echo "ERROR: este script requiere root." >&2
    exit 1
fi

# Restrict permissions of newly created files.
umask 077

# Verify backup directory.
if [[ ! -d "$DESTINO" || -L "$DESTINO" ]]; then
    echo "ERROR: directorio de backup no valido." >&2
    exit 1
fi

# Prevent concurrent executions.
exec 9>"$LOCK"

if ! flock -n 9; then
    echo "ERROR: ya existe un backup en ejecucion." >&2
    exit 1
fi

registrar() {
    printf '[%s] %s\n' \
        "$(date '+%F %T')" "$1" >> "$LOG"
}

# Ensure required commands exist.
for comando in tar gzip flock; do
    if ! command -v "$comando" >/dev/null 2>&1; then
        registrar "ERROR: comando no disponible: $comando"
        exit 1
    fi
done

# Verify source directories.
for origen in /home/cfo /home/accountant1; do
    if [[ ! -d "$origen" ]]; then
        registrar "ERROR: no existe $origen"
        exit 1
    fi
done

# Never overwrite an existing daily backup.
if [[ -e "$ARCHIVO" ]]; then
    registrar "ERROR: ya existe $ARCHIVO"
    exit 1
fi

TEMPORAL="$(mktemp "$DESTINO/.finance-$FECHA.XXXXXXXX.tar.gz")"

limpiar() {
    rm -f -- "$TEMPORAL"
}

trap limpiar EXIT

registrar "Iniciando backup de finance"

# Create compressed archive.
if ! tar -czf "$TEMPORAL" \
    -C / home/cfo home/accountant1; then
    registrar "ERROR: fallo al crear el backup"
    exit 1
fi

# Verify gzip integrity and tar readability.
if ! gzip -t "$TEMPORAL"; then
    registrar "ERROR: fallo de integridad GZIP"
    exit 1
fi

if ! tar -tzf "$TEMPORAL" >/dev/null; then
    registrar "ERROR: archivo TAR no valido"
    exit 1
fi

chmod 600 "$TEMPORAL"

# Publish without overwriting an existing backup.
if ! ln -- "$TEMPORAL" "$ARCHIVO"; then
    registrar "ERROR: no se pudo publicar el backup"
    exit 1
fi

rm -f -- "$TEMPORAL"

if [[ ! -f "$ARCHIVO" ]]; then
    registrar "ERROR: archivo final no encontrado"
    exit 1
fi

registrar "Backup correcto y verificado: $ARCHIVO"
echo "OK: backup creado y verificado: $ARCHIVO"



# Retention policy: 30 days.
RETENTION_DAYS=30
ENABLE_RETENTION=true

registrar "Iniciando comprobacion de retencion (${RETENTION_DAYS} dias)"


if [[ "$ENABLE_RETENTION" == true ]]; then

    errores_retencion=0
    LISTA_RETENCION="$(mktemp "$DESTINO/.retention.XXXXXXXX")"

    if find "$DESTINO" \
        -maxdepth 1 \
        -type f \
        -name 'finance-????-??-??.tar.gz' \
        ! -name "$(basename "$ARCHIVO")" \
        -mtime "+$((RETENTION_DAYS - 1))" \
        -print0 > "$LISTA_RETENCION"; then

        while IFS= read -r -d '' archivo; do
            if [[ ! -f "$archivo" || -L "$archivo" ]]; then
                registrar "ADVERTENCIA: candidato no valido $archivo"
                errores_retencion=1
            elif rm -- "$archivo"; then
                registrar "RETENCION: eliminado $archivo"
            else
                registrar "ADVERTENCIA: no se pudo eliminar $archivo"
                errores_retencion=1
            fi
        done < "$LISTA_RETENCION"

    else
        registrar "ADVERTENCIA: fallo al buscar backups antiguos"
        errores_retencion=1
    fi

    rm -f -- "$LISTA_RETENCION"

    if [[ "$errores_retencion" -eq 0 ]]; then
        registrar "Retencion completada correctamente"
    else
        registrar "ADVERTENCIA: retencion completada con errores"
    fi

else
    registrar "Retencion en modo simulacion"

    find "$DESTINO" \
        -maxdepth 1 \
        -type f \
        -name 'finance-????-??-??.tar.gz' \
        ! -name "$(basename "$ARCHIVO")" \
        -mtime "+$((RETENTION_DAYS - 1))" \
        -print
fi
