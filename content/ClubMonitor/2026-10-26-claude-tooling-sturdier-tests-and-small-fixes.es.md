---
title: "Herramientas de Claude, pruebas más sólidas y pequeños arreglos"
date: 2026-10-26T13:50:00+00:00
draft: false
description: "ClubMonitor pasa sus asistentes de IA de Copilot a Claude, estabiliza sus comprobaciones automáticas y corrige varios defectos cotidianos."
summary: "ClubMonitor pasa sus asistentes de IA de Copilot a Claude, estabiliza sus comprobaciones automáticas y corrige varios defectos cotidianos."
tags:
  - club-monitor
  - tooling
  - testing
  - migrations
  - claude
source:
  - 3d66ca2
  - 19622dc
  - 5775543
  - aa9bf39
  - 1eccbee
  - 16935fe
  - 7f064c9
  - 7f38e33
---

Esta actualización trata sobre todo del taller más que del producto: la forma en que se construye y se comprueba ClubMonitor se ha ordenado, con algunas pequeñas mejoras que quizá notes por el camino.

## Las guías para desarrolladores pasan de Copilot a Claude

Las instrucciones de programación del proyecto vivían en archivos de GitHub Copilot. Ahora están junto al código, en guías breves por carpeta que Claude carga automáticamente (commit 7f064c9, `src/CLAUDE.md`). Los antiguos archivos de instrucciones y agentes de Copilot han desaparecido, y las reglas comunes están en `docs/coding-conventions.md`, una única fuente de verdad (commit 19622dc). Entre los nuevos ayudantes hay un revisor de código, un especialista en accesibilidad y un redactor del registro de cambios (`.claude/agents/code-reviewer.md`).

## Comprobaciones automáticas más estables

Las pruebas de extremo a extremo en el navegador se rehicieron para que dejen de fallar por problemas de tiempos y de estado de las páginas (commits aa9bf39, 1eccbee, 7f38e33, `tests/Playwright.Tests/`). El proceso de compilación perdió pasos defectuosos, ganó la ejecución de las pruebas unitarias del cliente, y los paquetes de pruebas quedaron fijados a versiones conocidas (commit 19622dc, `.github/workflows/ci.yml`, `Directory.Packages.props`). También se fusionaron actualizaciones de paquetes (PR #212).

## Pequeños arreglos que quizá notes

- La página de búsqueda de clubes ya no se detiene en 500 clubes: los carga página a página y muestra primero los más recientes (`src/Client/Components/Pages/Clubs/SearchClubs.razor`). Cualquier usuario con sesión iniciada puede abrirla, no solo el rol Standard, y la etiqueta del botón Unirse se muestra correctamente.
- El cuadro «Añadir partido» tiene su propio texto de botón y un mensaje claro «Match date is invalid», traducido a los tres idiomas (`src/Client/Localization/SharedResource.resx`).
- «Mis clubes» ahora muestra primero los que te uniste más recientemente (`src/Infrastructure/Clubs/ClubMembershipRepository.cs`).
- El límite de intentos de inicio de sesión se puede configurar, con 10 por minuto por defecto (`src/Api/Extensions/ServiceCollectionExtensions.cs`).

## Una actualización de base de datos más segura

La migración que eliminó el multi-tenant cambiaba la columna del tema del club sobre la marcha, algo que no funciona igual en todas las bases de datos. Ahora añade una columna numérica nueva, traslada los nombres de tema antiguos (los desconocidos pasan a Default) y después la sustituye (`src/Infrastructure/Persistence/Migrations/20260619135730_RemoveTenantFunctionality.cs`, commit 3d66ca2).

## Fuentes

- commit 3d66ca2
- commit 19622dc
- commit 5775543
- commit aa9bf39
- commit 1eccbee
- commit 7f064c9
- commit 7f38e33
- PR #212
- `src/CLAUDE.md`
- `docs/coding-conventions.md`
- `.claude/agents/code-reviewer.md`
- `.github/workflows/ci.yml`
- `Directory.Packages.props`
- `tests/Playwright.Tests/`
- `src/Client/Components/Pages/Clubs/SearchClubs.razor`
- `src/Client/Localization/SharedResource.resx`
- `src/Infrastructure/Clubs/ClubMembershipRepository.cs`
- `src/Api/Extensions/ServiceCollectionExtensions.cs`
- `src/Infrastructure/Persistence/Migrations/20260619135730_RemoveTenantFunctionality.cs`
