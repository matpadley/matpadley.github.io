---
title: "Pointer le Dépôt sur main et Corriger les Déclencheurs CI"
date: 2026-07-30T10:00:00+01:00
draft: false
description: "Renommer la branche par défaut en main a laissé les deux workflows GitHub Actions se déclencher sur une branche qui n'existait plus — le filet de sécurité CI ne s'était donc jamais une seule fois activé."
summary: "Renommer la branche par défaut en main a laissé les deux workflows GitHub Actions se déclencher sur une branche qui n'existait plus — le filet de sécurité CI ne s'était donc jamais une seule fois activé."
tags:
  - club-monitor
  - github-actions
  - ci-cd
---

## Pourquoi

Le dépôt est maintenant `matpadley/Club-monitor-uni` (privé) avec **`main`** comme branche par défaut ; la branche originale `feature/initial-application` a été renommée en `main` et poussée. Tout ce qui avait été écrit avant supposait `master`.

La conséquence importante n'était pas cosmétique : **les deux workflows GitHub Actions se déclenchaient sur `master`**, une branche qui n'existe plus. Ni `build-test` ni `deploy` n'auraient jamais été exécutés, le filet de sécurité CI était donc silencieusement absent — les workflows n'ont en fait jamais tourné une seule fois.

## Ce qui a changé

- `.github/workflows/build-test.yml` : déclencheurs `pull_request`/`push` de `master` → `main`.
- `.github/workflows/deploy.yml` : déclencheur `push` et commentaire d'en-tête de `master` → `main`.
- `Docs/main_spec.md`, `CLAUDE.md`, `README.md` : les règles de contrôle des sources nomment désormais `main`, et la spec note que l'import initial est allé directement sur `main` avant que la règle PR ne puisse être appliquée, tout ce qui suit passant par une PR.

Laissé délibérément inchangé : « master sport catalog » dans la spec (sens sans rapport), l'URL de la doc upstream Uno dans `SharedAssets.md`, et les entrées historiques de `progress/`, qui ne sont jamais modifiées.

## Note sur le processus

Ce changement est lui-même le premier à suivre le flux de travail mandaté — branché depuis `main`, poussé, et soumis comme pull request plutôt que commité directement.

La protection de branche sur `main` **n'est pas encore configurée**, donc la règle PR est une convention plutôt qu'une contrainte.

## Fichiers modifiés

`.github/workflows/build-test.yml`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, plus cette entrée.
