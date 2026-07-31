---
title: "Apuntar el Repositorio a main y Arreglar los Disparadores de CI"
date: 2026-07-30T10:00:00+01:00
draft: false
description: "Renombrar la rama predeterminada a main dejó ambos flujos de trabajo de GitHub Actions disparándose en una rama que ya no existía — por lo que la red de seguridad del CI nunca había llegado a activarse."
summary: "Renombrar la rama predeterminada a main dejó ambos flujos de trabajo de GitHub Actions disparándose en una rama que ya no existía — por lo que la red de seguridad del CI nunca había llegado a activarse."
tags:
  - club-monitor
  - github-actions
  - ci-cd
---

## Por qué

El repositorio es ahora `matpadley/Club-monitor-uni` (privado) con **`main`** como rama predeterminada; la rama original `feature/initial-application` fue renombrada a `main` y subida. Todo lo escrito antes asumía `master`.

La consecuencia importante no era cosmética: **ambos flujos de trabajo de GitHub Actions se disparaban en `master`**, una rama que ya no existe. Ni `build-test` ni `deploy` habrían llegado a ejecutarse nunca, por lo que la red de seguridad del CI estaba silenciosamente ausente — los flujos de trabajo de hecho nunca han llegado a ejecutarse.

## Qué cambió

- `.github/workflows/build-test.yml`: disparadores `pull_request`/`push` de `master` → `main`.
- `.github/workflows/deploy.yml`: disparador `push` y comentario de cabecera de `master` → `main`.
- `Docs/main_spec.md`, `CLAUDE.md`, `README.md`: las reglas de control de versiones ahora nombran `main`, y la especificación registra que la importación inicial fue directamente a `main` antes de que la regla de PR pudiera aplicarse, con todo lo posterior pasando por un PR.

Se dejó deliberadamente sin cambiar: "master sport catalog" en la especificación (significado no relacionado), la URL de la documentación upstream de Uno en `SharedAssets.md`, y las entradas históricas de `progress/`, que nunca se editan.

## Nota sobre el proceso

Este cambio es en sí mismo el primero en seguir el flujo de trabajo mandatorio — creado desde `main`, subido, y elevado como pull request en lugar de ser confirmado directamente.

La protección de ramas en `main` **aún no está configurada**, por lo que la regla de PR es convención en lugar de aplicación.

## Archivos modificados

`.github/workflows/build-test.yml`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, más esta entrada.
