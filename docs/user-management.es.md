# Gestión de usuarios y grupos

## Descripción general

BlackBox es un laboratorio de servidor Linux que simula la gestión de accesos por departamentos en una organización que maneja información empresarial sensible. Las cuentas locales se asignan a grupos funcionales para organizar la administración y los permisos del sistema de archivos.

Este documento recoge la **configuración realizada**. La automatización del alta de usuarios, la caducidad de contraseñas o las restricciones PAM se hayan probado en esta fase.

## Inventario de cuentas verificado

Se consultó `/etc/passwd` seleccionando UID >= 1000 y excluyendo UID 65534. Es un criterio útil para este laboratorio, pero no define universalmente qué cuentas pertenecen a personas.

| Grupo | Cuentas | Total |
| --- | --- | ---: |
| `marketing` | `mkt1`, `mkt2`, `marketing-lead` | 3 |
| `human-resources` | `hr1`, `hr2`, `hr3` | 3 |
| `finance` | `accountant1`, `accountant2`, `cfo`, `subcfo` | 4 |
| `management` | `manager1`, `manager2`, `manager3`, `ceo` | 4 |
| `developers` | `dev1`, `dev2`, `dev3` | 3 |
| `it-support` | `it-01`, `it-02`, `it-03` | 3 |
| `admins107-13` | `devops` | 1 |
| **Total** | | **21** |

También se observó que `devops` pertenece a los grupos suplementarios `sudo` y `users`.

## Comandos de verificación

Listar las cuentas seleccionadas por UID:

```bash
awk -F: '$3 >= 1000 && $3 != 65534 {print $1 " -> " $6}' /etc/passwd
```

Comprobar los grupos de cada cuenta:

```bash
awk -F: '$3 >= 1000 && $3 != 65534 {print $1}' /etc/passwd | while read -r user; do
    printf '%-20s -> ' "$user"
    id -nG "$user"
done
```

Listar los grupos con GID >= 1000 (revisar el resultado, porque puede incluir grupos del sistema como `nogroup`):

```bash
getent group | awk -F: '$3 >= 1000 {print $1}'
```

## Diseño de seguridad

Los grupos departamentales son la base para restringir el acceso a los recursos compartidos. La pertenencia a un grupo no basta por sí sola: también importan los permisos del directorio y las ACL POSIX. Los controles verificados se documentan en [Permisos de archivos y control de acceso departamental](file-permissions.es.md).

## Alcance y evidencias

**Verificado:** nombres de 21 cuentas, rutas de sus directorios personales y pertenencia a grupos observada.

**Pendiente de validar en esta documentación:** automatización de creación de cuentas, caducidad de contraseñas, restricciones horarias PAM, ciclo de vida de cuentas y política de privilegios sudo.

> Nota para el portafolio: los nombres de las cuentas son ficticios y pertenecen al laboratorio. Revisa las capturas antes de publicarlas para evitar exponer identificadores del equipo o información sensible.
