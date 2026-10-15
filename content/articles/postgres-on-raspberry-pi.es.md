---
title: "Adiós a los archivos JSON: instalar Postgres en una Raspberry Pi para mis aplicaciones pequeñas"
date: 2026-10-09
draft: false
tags: ["postgres", "raspberry-pi", "linux", "databases"]
summary: "Varias de mis aplicaciones pequeñas guardaban sus datos en archivos JSON. Quería una base de datos de verdad sin pagar por una alojada, así que instalé Postgres en una Raspberry Pi. Esta es toda la configuración: instalación, un usuario que puede crear bases de datos y acceso remoto desde mi portátil."
---

## Por qué molestarse

Algunas de mis aplicaciones pequeñas guardan sus datos en archivos JSON. Es un enfoque perfectamente válido para empezar — sin configuración, fácil de leer, fácil de versionar. Pero deja de ser divertido en cuanto quieres consultar los datos, actualizar dos cosas a la vez sin pisar un archivo, o dejar que más de una aplicación (o una máquina) toque los mismos datos.

Tenía una Raspberry Pi parada, y Postgres funciona de maravilla en ella. Una cajita en mi red doméstica, una base de datos por aplicación, y se acabó el bloqueo de archivos casero.

## Instalar Postgres

En Raspberry Pi OS (de 64 bits si es posible), todo viene directamente del gestor de paquetes:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
psql --version
```

La versión que obtienes depende de la versión del sistema — Bookworm trae la 15, Trixie la 17. Para aplicaciones pequeñas, cualquiera de las dos sirve.

Un consejo práctico: si puedes, guarda los datos en un SSD en lugar de en la tarjeta SD. Una base de datos escribe constantemente, y a las tarjetas SD no les gusta nada.

## Crear un usuario administrador que pueda crear bases de datos

Por defecto, solo el superusuario `postgres` puede hacer algo útil. No quería iniciar sesión con él cada vez, así que creé un usuario normal que puede crear bases de datos (y otros usuarios) sin ser superusuario:

```bash
sudo -u postgres psql
```

```sql
CREATE ROLE mat WITH LOGIN PASSWORD 'una-contrasena-larga-y-aleatoria' CREATEDB CREATEROLE;
```

Con eso, `mat` puede ejecutar `CREATE DATABASE` y `CREATE ROLE` por sí mismo. Para cada aplicación creo después una base de datos y un acceso limitado que es propietario solo de esa base de datos:

```sql
CREATE ROLE myapp WITH LOGIN PASSWORD 'otra-contrasena-larga';
CREATE DATABASE myapp OWNER myapp;
```

Cada aplicación tiene sus propias credenciales, así que una contraseña filtrada solo expone una base de datos.

## Permitir conexiones desde mi red

De fábrica, Postgres solo escucha en `localhost`. Dos archivos de configuración controlan el acceso remoto (cambia `15` por tu número de versión — `ls /etc/postgresql` te lo dirá).

En `/etc/postgresql/15/main/postgresql.conf`, establece:

```
listen_addresses = '*'
```

En `/etc/postgresql/15/main/pg_hba.conf`, añade una línea que permita inicios de sesión solo desde tu red doméstica:

```
# TYPE  DATABASE  USER  ADDRESS         METHOD
host    all       all   192.168.1.0/24  scram-sha-256
```

Ajusta la subred a la de tu red. Después reinicia Postgres y abre el puerto solo a la red local:

```bash
sudo systemctl restart postgresql
sudo apt install -y ufw
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw allow OpenSSH
sudo ufw enable
```

## Comprobar que funciona

Desde otra máquina de la red:

```bash
psql -h <direccion-ip-de-la-pi> -U mat -d postgres
```

Introduce la contraseña y deberías llegar a un prompt. Prueba `CREATE DATABASE test;` y luego `DROP DATABASE test;` para confirmar que el usuario administrador cumple su función.

## Usarlo desde una aplicación

Por parte de la aplicación, solo hace falta una cadena de conexión. En una aplicación .NET con Npgsql, por ejemplo:

```csharp
var connString = "Host=<direccion-ip-de-la-pi>;Username=myapp;Password=otra-contrasena-larga;Database=myapp";
await using var conn = new NpgsqlConnection(connString);
await conn.OpenAsync();
```

Donde antes leía y escribía un archivo JSON, ahora ejecuto una consulta. Los mismos datos, pero ahora se pueden filtrar, son seguros ante accesos concurrentes y se comparten entre aplicaciones.

## No lo expongas a Internet

Lo mantuve en mi red doméstica a propósito. Por favor, no redirijas el puerto 5432 en tu router — un puerto de Postgres abierto a Internet recibe intentos de adivinar contraseñas en cuestión de horas. Si necesitas acceso desde fuera, pon la Pi detrás de una VPN como Tailscale, o usa un túnel SSH (`ssh -L 5433:localhost:5432 pi@<direccion-ip-de-la-pi>`) y conéctate a `localhost:5433`.

## No olvides las copias de seguridad

Una Pi no es un centro de datos. Un volcado nocturno con cron basta para empezar:

```bash
0 2 * * * pg_dump -U myapp -h localhost myapp | gzip > /mnt/backup/myapp_$(date +\%F).sql.gz
```

Usa un archivo `~/.pgpass` para que no se detenga a pedir la contraseña, y copia los volcados a algún sitio que no sea la Pi.

## La conclusión

Pasar de archivos JSON a Postgres me llevó una tarde: instalar, un usuario administrador que puede crear bases de datos, una base de datos y un acceso por aplicación, y un par de líneas de configuración para dejar entrar a mi red. La Pi apenas nota la carga de aplicaciones pequeñas, y ya no tengo que preocuparme por un archivo JSON corrupto.
