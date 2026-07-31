---
title: "Escribir las Reglas: Membresía, Multitenancy, Deportes y Despliegue"
date: 2026-07-29T15:00:00+01:00
draft: false
description: "Antes de escribir ningún código, la especificación incorporó un rol de Super Admin, el club como frontera de tenant, un catálogo de deportes gestionado por base de datos, entornos Bicep y un flujo de trabajo solo mediante Pull Request."
summary: "Antes de escribir ningún código, la especificación incorporó un rol de Super Admin, el club como frontera de tenant, un catálogo de deportes gestionado por base de datos, entornos Bicep y un flujo de trabajo solo mediante Pull Request."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - multi-tenancy
  - architecture
---

## Qué cambió
Se amplió `Docs/main_spec.md` y `CLAUDE.md` con varios requisitos nuevos:

- **Tecnologías**: se añadió EF Core (code-first) como ORM, observabilidad basada en OpenTelemetry con exportador/backend intercambiable, referencia a las convenciones oficiales de codificación en C#, y se aclaró que el desarrollo local usa una instancia local de SQL Server.
- **Pruebas**: se especificó que las pruebas unitarias usen el proveedor de base de datos InMemory de EF Core.
- **Roles**: se introdujo un tercer rol, **Super Admin** (a nivel de plataforma, gestiona el catálogo de deportes y asigna deportes a los clubes), junto con los roles existentes de Admin y Estándar.
- **Membresía y Roles** (nueva sección): se documentaron los flujos de invitación por Admin y solicitud de unión, y que los roles son por club.
- **Multitenancy** (nueva sección): el Club es la frontera de tenant, filtros de consulta global de EF Core basados en `ClubId`, las ligas a nivel de plataforma abarcan varios clubes mediante una tabla de unión.
- **Deportes** (nueva sección): los deportes son un catálogo gestionado por base de datos administrado por el Super Admin; cada club debe tener ≥1 deporte; la creación de ligas/copas selecciona automáticamente el deporte si el club solo tiene uno, de lo contrario solicita al usuario que elija.
- **Despliegue y CI/CD**: se añadió Bicep como herramienta de IaC, se definieron los entornos Local/Staging/Producción, y se requirió que Staging y Producción estén en suscripciones de Azure independientes.
- **Control de Versiones** (nueva sección): todos los cambios deben pasar por un Pull Request; los commits directos a `master` no están permitidos.

## Por qué
El usuario solicitó estas adiciones para completar la especificación: flujo de membresía/roles, multitenancy, observabilidad intercambiable, EF Core, estrategia de entorno/despliegue (Bicep, suscripciones separadas para staging/producción), BD InMemory para pruebas unitarias, convenciones de codificación, catálogo de deportes gestionado por base de datos con lógica de asignación por club, y un flujo de trabajo de control de versiones solo mediante PR.

## Archivos modificados
- `Docs/main_spec.md`
- `CLAUDE.md`
