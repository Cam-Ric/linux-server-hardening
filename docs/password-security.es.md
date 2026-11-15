# Política de Seguridad de Contraseñas

## Descripción general

BlackBox implementa una política centralizada de seguridad de contraseñas mediante Linux PAM (Pluggable Authentication Modules), `pam_pwquality`, CrackLib y la herramienta `chage`.

El objetivo es exigir contraseñas robustas, detectar contraseñas basadas en diccionarios, reducir patrones predecibles y gestionar la caducidad de las contraseñas de las cuentas locales.

Esta política se integra con el sistema automatizado de creación de usuarios.

## Requisitos de complejidad

|Control de seguridad|Configuración|
|---|---|
|Longitud mínima|12 caracteres|
|Letras mayúsculas|Mínimo 2|
|Letras minúsculas|Mínimo 1|
|Números|Mínimo 2|
|Caracteres especiales|Mínimo 2|
|Comprobación de similitud con el usuario|Activada|
|Repetición máxima consecutiva de clases|3|
|Validación mediante diccionarios|Activada|
|Aplicación de la política a root|Activada|

### Configuración de PAM

Archivo:

`/etc/security/pwquality.conf`

Parámetros relevantes:

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

Los valores negativos de los parámetros `credit` indican cantidades mínimas obligatorias de cada tipo de carácter.

`usersubstr` incorpora comprobaciones adicionales contra contraseñas que contienen fragmentos del nombre de usuario.

`maxclassrepeat` limita los caracteres consecutivos pertenecientes a una misma clase.

`enforce_for_root` aplica los controles de calidad cuando el administrador establece contraseñas mediante PAM.

## Integración con PAM

La política se encuentra integrada en la configuración de contraseñas del sistema.

Archivo:

`/etc/pam.d/common-password`

Líneas observadas en BlackBox:

```
password requisite pam_pwquality.so retry=25
password [success=1 default=ignore] pam_unix.so obscure use_authtok try_first_pass yescrypt
```

`pam_pwquality` comprueba la calidad de las contraseñas y `pam_unix` gestiona su actualización en el sistema.

## Protección mediante diccionarios multilingües

BlackBox utiliza un diccionario personalizado de CrackLib construido a partir de tres recursos lingüísticos:

- Inglés: `american-english`
    
- Castellano: `spanish`
    
- Catalán/valenciano: `catalan` (esto ya que Cracklib no incluye un paquete propio del valenciano para su instalacion, me permite el catalán)
    

Archivos originales:

```
/usr/share/dict/american-english
/usr/share/dict/spanish
/usr/share/dict/catalan
```

Para construir el diccionario:

```
sudo mkdir -p /usr/local/share/blackbox-dictionaries

cat /usr/share/dict/american-english \
    /usr/share/dict/spanish \
    /usr/share/dict/catalan \
  | LC_ALL=C sort -u \
  | sudo /usr/sbin/cracklib-packer \
      /usr/local/share/blackbox-dictionaries/es-en-va
```

Se generaron los siguientes archivos:

```
es-en-va.hwm
es-en-va.pwd
es-en-va.pwi
```

La compilación informó de 783.494 entradas procesadas.

Este mecanismo permite detectar contraseñas basadas en vocabulario común de los tres idiomas, aunque no garantiza identificar todas las contraseñas débiles.

## Política de caducidad

La configuración definitiva de BlackBox es:

|Parámetro|Valor|
|---|---|
|Días mínimos entre cambios|1|
|Vigencia máxima|360 días|
|Aviso antes de caducar|30 días|
|Cambio obligatorio en el primer inicio|Sí|

Comandos utilizados:

```
chage -m 1 -M 360 -W 30 "$USERNAME"
chage -d 0 "$USERNAME"
```

El primer comando configura los períodos de vigencia y aviso.

El segundo marca la contraseña como caducada para exigir su modificación en el primer inicio de sesión.

El máximo de 360 días constituye una decisión de configuración del laboratorio y no debe interpretarse como una recomendación universal.

Las recomendaciones modernas desaconsejan la rotación periódica arbitraria sin indicios de compromiso.

Ante una posible filtración, debe facilitarse el cambio inmediato de contraseña, con intervención administrativa si es necesario.

## Validación

### Integración PAM

```
grep -nE 'pam_pwquality|pam_unix' /etc/pam.d/common-password
```

### Parámetros de calidad

```
grep -E '^[[:space:]]*(minlen|ucredit|lcredit|dcredit|ocredit|usercheck|usersubstr|maxclassrepeat|dictcheck|dictpath|enforce_for_root)' \
  /etc/security/pwquality.conf
```

### Diccionario compilado

```
ls -lh /usr/local/share/blackbox-dictionaries/es-en-va.*
```

### Caducidad de contraseñas

```
sudo chage -l test-pam
```

Se utilizó la cuenta temporal `test-pam` para verificar los parámetros de caducidad.

La configuración definitiva establece un mínimo de 1 día, un máximo de 360 días y un aviso de 30 días.

También se comprobó el reconocimiento de palabras mediante CrackLib.

## Consideraciones de seguridad

- La complejidad de las contraseñas no sustituye a la autenticación multifactor.
    
- Los diccionarios no detectan todas las contraseñas comprometidas.
    
- La caducidad no garantiza que una contraseña sea segura.
    
- Nunca deben publicarse contraseñas ni hashes en GitHub.
    
- Los cambios de PAM deben probarse manteniendo una sesión administrativa disponible.
    
- El diccionario compilado es un recurso local del servidor y no necesita publicarse en el repositorio.
    

## Tecnologías utilizadas

Linux · PAM · pam_pwquality · CrackLib · Bash · chage
