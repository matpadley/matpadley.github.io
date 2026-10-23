---
title: "Un club, una API y una forma más fácil de probarlo en local"
date: 2026-10-23T09:00:00+01:00
draft: false
description: "ClubMonitor ahora atiende a un solo club, habla con su API mediante un cliente generado, funciona en local sin Docker y tiene nuevas salvaguardas para el trabajo asistido por IA."
summary: "ClubMonitor ahora atiende a un solo club, habla con su API mediante un cliente generado, funciona en local sin Docker y tiene nuevas salvaguardas para el trabajo asistido por IA."
tags:
  - club-monitor
  - single-club
  - sqlite
  - api
  - testing
source:
  - 8dd12f1
  - f17ab6d
  - 20c53e1
  - 30cf062
  - 85b47c1
  - 338c35c
  - 8bc0496
  - 0f2a359
---

Desde la última actualización, nueve commits tocaron unos 270 archivos, y el mayor cambio es una simplificación: ClubMonitor ahora cuida de un solo club.

## Una corrección: se acabó el multi-inquilino

Los artículos anteriores describían ClubMonitor como una aplicación multi-inquilino, una instalación para varios clubes. Ya no es así. Se han eliminado el middleware de resolución y de estado de inquilino, la reclamación de inquilino y el documento del plan multi-inquilino (commit 20c53e1). Ahora `CLAUDE.md` indica claramente la regla del club único (`CLAUDE.md`). Menos piezas móviles significa menos cosas que pueden fallar.

## Las páginas ahora hablan con una API versionada

Las pantallas ya no acceden a las entrañas de la aplicación. Llaman a la API HTTP bajo `/api/v1/` mediante un pequeño cliente, que a su vez usa uno generado a partir de la descripción publicada de la API (commit 8dd12f1). Nuevas rutas para clubes, copas, miembros y perfiles de usuario cubren los huecos restantes, respaldadas por muchas pruebas (commit f17ab6d). Un script actualiza el cliente generado y una prueba falla si se queda obsoleto. Un cambio incompatible tendrá su propia versión en lugar de modificar la v1 (`docs/api-versioning.md`).

## Ejecutable sin Docker

Para probar la aplicación, ahora hay una opción SQLite para desarrollo y pruebas en local. Un único script arranca la aplicación sobre un archivo local con un club, una liga y una copa de demostración, sin Docker (commit 30cf062, `scripts/run-local-sqlite.sh`). Es solo para desarrollo, nunca para producción.

## Ayuda de IA más segura y guiada por pruebas

Para los desarrolladores se añadieron dos agentes de pruebas. Uno busca las pruebas que faltan y el otro escribe pruebas para los archivos que acabas de cambiar (commits 85b47c1, 8bc0496). Un hook los limita a editar archivos bajo `tests/`, y la primera pasada añadió unas 1800 líneas de pruebas. Otro hook impide que Claude haga commit o push a `main` (commit 338c35c). Pequeños ajustes arreglaron la configuración de Docker en CI y añadieron una habilidad para redactar el README (commit 0f2a359).

## Fuentes

- commit 8dd12f1
- commit f17ab6d
- commit 20c53e1
- commit 30cf062
- commit 85b47c1
- commit 338c35c
- commit 8bc0496
- commit 0f2a359
- `CLAUDE.md`
- `docs/api-versioning.md`
- `scripts/run-local-sqlite.sh`
