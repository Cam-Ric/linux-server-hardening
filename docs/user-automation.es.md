# Automatización de Creación de Usuarios

## Descripción general

BlackBox incorpora un sistema de aprovisionamiento de usuarios mediante Bash para simplificar la creación de cuentas locales Linux y aplicar controles de acceso departamentales y políticas de seguridad de contraseñas.

La automatización combina la creación de cuentas, asignación de grupos, establecimiento de contraseñas y configuración de su caducidad.

## Script

Ubicación en el repositorio:

`scripts/create-user.sh`

Ejemplo de ejecución:

```
sudo bash scripts/create-user.sh nuevoempleado finance
```

El script requiere privilegios administrativos.

## Departamentos admitidos

La automatización admite los siguientes grupos Linux:

- `finance`
    
- `management`
    
- `human-resources`
    
- `marketing`
    
- `developers`
    
- `it-support`
    

El grupo solicitado se comprueba mediante una lista de departamentos permitidos.

El script no crea automáticamente grupos inexistentes.

## Funcionamiento

El script realiza las siguientes operaciones:

1. Comprueba que se ejecuta con privilegios administrativos.
    
2. Valida el número de argumentos.
    
3. Comprueba el formato del nombre de usuario.
    
4. Valida el departamento solicitado.
    
5. Impide crear usuarios duplicados.
    
6. Comprueba que existe el grupo Linux correspondiente.
    
7. Solicita confirmación al administrador.
    
8. Crea la cuenta y su directorio personal.
    
9. Asigna el grupo principal del departamento.
    
10. Solicita la contraseña inicial mediante `passwd`.
    
11. Configura la política de caducidad.
    
12. Obliga a cambiar la contraseña en el primer inicio de sesión.
    
13. Muestra información de la cuenta para su comprobación.
    

## Creación de cuentas

El script utiliza:

```
useradd -m -k /etc/skel -g "$GROUP" -s /bin/bash "$USERNAME"
```

Este comando crea el directorio personal, utiliza `/etc/skel` como plantilla, asigna el grupo principal y establece Bash como intérprete de comandos.

## Integración con la política PAM

La contraseña inicial se configura mediante:

```
passwd "$USERNAME"
```

La calidad de la contraseña se comprueba utilizando PAM, `pam_pwquality` y el diccionario multilingüe configurado con CrackLib.

La política exige al menos 12 caracteres, dos mayúsculas, dos números, dos símbolos y una minúscula.

También incorpora comprobaciones de similitud con el usuario, repetición consecutiva de clases de caracteres y palabras de diccionario.

## Política de caducidad

La configuración definitiva es:

```
chage -m 1 -M 360 -W 30 "$USERNAME"
chage -d 0 "$USERNAME"
```

|Parámetro|Valor|
|---|---|
|Mínimo entre cambios|1 día|
|Vigencia máxima|360 días|
|Aviso de caducidad|30 días|
|Cambio en el primer inicio|Obligatorio|

El cambio obligatorio en el primer inicio permite sustituir la contraseña temporal establecida durante la creación de la cuenta.

## Validación

Se utilizó la cuenta temporal `test-finance` para comprobar el funcionamiento del aprovisionamiento y el rechazo de nombres de usuario duplicados.

Posteriormente, dicha cuenta fue eliminada.

También se utilizó la cuenta temporal `test-pam` durante las pruebas de seguridad de contraseñas.

Comandos de comprobación:

```
id test-pam
getent passwd test-pam
sudo passwd -S test-pam
sudo chage -l test-pam
```

Se verificaron los parámetros definitivos de caducidad en la cuenta temporal.

## Limitaciones y consideraciones de seguridad

- El script requiere privilegios administrativos.
    
- Los grupos departamentales deben existir previamente.
    
- La creación de cuentas no dispone de una reversión automática completa si falla un paso posterior.
    
- La validación de contraseñas depende de la configuración PAM del sistema.
    
- No deben almacenarse contraseñas en el código ni publicarse en GitHub.
    
- Los cambios del script se aplican a las cuentas nuevas; las cuentas existentes deben actualizarse por separado.
    
- La solución está diseñada para cuentas locales Linux y no sustituye a un sistema centralizado de identidades.
    

## Documentación relacionada

- [Política de seguridad de contraseñas](password-security.es.md)
    
- [Versión en inglés](user-automation.md)
    

## Contexto del proyecto

Este sistema forma parte de **BlackBox — Linux Server Hardening** y demuestra competencias prácticas en scripting Bash, gestión de identidades Linux, integración PAM y automatización administrativa.