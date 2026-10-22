---
title: "Eliminar una contraseña commiteada del historial de Git"
date: 2026-10-21T12:00:00+01:00
draft: false
tags: ["git", "security", "secrets", "docker"]
categories: ["articles"]
summary: "Había commiteado una contraseña de base de datos en appsettings.json. Así la moví a un secreto de Docker y la borré del historial con git-filter-repo."
---

Mientras añadía un endpoint protegido con clave de API a un proyecto personal, me di cuenta de que había una cadena de conexión real a la base de datos — contraseña incluida — en `appsettings.json`, commiteada en git. Borrarla en un commit nuevo no basta: la contraseña sigue en todos los commits anteriores. Así arreglé tanto el código actual como el historial.

## Paso 1: evitar que vuelva a pasar

Primero, sacar el secreto del código. En `docker-compose.yml` sustituí el valor en línea por un secreto de Docker leído desde un archivo que nunca se commitea:

```yaml
services:
  app:
    secrets:
      - ConnectionStrings__DefaultConnection

secrets:
  ConnectionStrings__DefaultConnection:
    file: ./secrets/connection_string.txt   # nunca commitear
```

Añade `secrets/` al `.gitignore` y pon la cadena de conexión en ese archivo. ASP.NET Core puede leerla con:

```csharp
builder.Configuration.AddKeyPerFile("/run/secrets/", optional: true);
```

`AddKeyPerFile` convierte el nombre de archivo `ConnectionStrings__DefaultConnection` en la clave de configuración `ConnectionStrings:DefaultConnection`, así que no hace falta cambiar nada más en el código. En `appsettings.json` dejé un valor de relleno inofensivo (`Password=changeme`).

## Paso 2: rotar la contraseña

Hazlo antes que nada. Reescribir el historial no garantiza que nadie tenga una copia — pudo haberse clonado, cacheado o rastreado. Trata la contraseña antigua como comprometida y cámbiala en la base de datos.

## Paso 3: reescribir el historial con git-filter-repo

`git filter-branch` está obsoleto; [`git-filter-repo`](https://github.com/newren/git-filter-repo) es la herramienta recomendada.

Trabaja en un clon espejo nuevo para no tocar tu copia de trabajo:

```bash
git clone --mirror <url-del-repo> myrepo-mirror.git
cd myrepo-mirror.git
brew install git-filter-repo
```

Crea un archivo de reemplazos **fuera del repositorio** (las comillas simples evitan que el shell altere caracteres especiales como `^`):

```bash
printf '%s\n' 'CONTRASEÑA-ANTIGUA==>REMOVED' > ../replacements.txt
```

Después reescribe cada commit de cada rama y etiqueta:

```bash
git filter-repo --replace-text ../replacements.txt
```

Comprueba que la contraseña ha desaparecido — no debería imprimir nada:

```bash
git log --all -p -S'CONTRASEÑA-ANTIGUA' | head
```

## Paso 4: push forzado

Por seguridad, `filter-repo` elimina el remoto `origin`; vuelve a añadirlo y haz push:

```bash
git remote add origin <url-del-repo>
git push --force --all
git push --force --tags
```

Cada commit desde el primero afectado recibe un hash nuevo, así que cualquiera que tenga un clon debe volver a clonar. Si no, puede volver a subir el historial antiguo.

## Paso 5: limpiar el remoto

- GitHub mantiene accesibles los commits antiguos por su hash, en vistas en caché y a través de forks y referencias de pull requests (`refs/pull/*`). Pide al soporte de GitHub que ejecute la recolección de basura y purgue las vistas en caché.
- Revisa los forks y las PR abiertas que aún contengan los commits antiguos.
- Borra tu copia local antigua y vuelve a clonar.
- Borra `replacements.txt` — contiene la contraseña.

## La lección

Reescribir el historial es limpieza, no protección. La solución real es rotar la credencial y asegurarse de que los secretos nunca lleguen al repositorio: en un archivo ignorado o un gestor de secretos, y solo valores de relleno en lo que se commitea.
