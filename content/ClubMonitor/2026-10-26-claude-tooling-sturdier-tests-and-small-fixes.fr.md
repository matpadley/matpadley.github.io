---
title: "Outils Claude, tests plus solides et petites corrections"
date: 2026-10-26T13:50:00+00:00
draft: false
description: "ClubMonitor passe ses assistants IA de Copilot à Claude, fiabilise ses vérifications automatiques et corrige plusieurs petits défauts du quotidien."
summary: "ClubMonitor passe ses assistants IA de Copilot à Claude, fiabilise ses vérifications automatiques et corrige plusieurs petits défauts du quotidien."
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

Cette mise à jour concerne surtout l'atelier plutôt que le produit : la manière dont ClubMonitor est construit et vérifié a été rangée, avec quelques petites améliorations visibles au passage.

## Les consignes pour les développeurs passent de Copilot à Claude

Les consignes de codage du projet vivaient dans des fichiers GitHub Copilot. Elles se trouvent maintenant à côté du code, dans de courts guides par dossier que Claude charge automatiquement (commit 7f064c9, `src/CLAUDE.md`). Les anciens fichiers d'instructions et d'agents Copilot ont disparu, et les règles communes sont réunies dans `docs/coding-conventions.md`, une seule source de vérité (commit 19622dc). Parmi les nouveaux assistants : un relecteur de code, un spécialiste de l'accessibilité et un rédacteur de journal des changements (`.claude/agents/code-reviewer.md`).

## Des vérifications automatiques plus stables

Les tests de bout en bout dans le navigateur ont été retravaillés pour ne plus buter sur des questions de timing et d'état des pages (commits aa9bf39, 1eccbee, 7f38e33, `tests/Playwright.Tests/`). La chaîne de build a perdu des étapes défectueuses, gagné l'exécution des tests unitaires du client, et les paquets de test sont figés sur des versions connues (commit 19622dc, `.github/workflows/ci.yml`, `Directory.Packages.props`). Des mises à jour de paquets ont aussi été fusionnées (PR #212).

## Petites corrections que vous remarquerez peut-être

- La page de recherche de clubs ne s'arrête plus à 500 clubs : elle les charge page par page et affiche les plus récents en premier (`src/Client/Components/Pages/Clubs/SearchClubs.razor`). Tout utilisateur connecté peut l'ouvrir, pas seulement le rôle Standard, et le libellé du bouton Rejoindre s'affiche correctement.
- La boîte de dialogue « Ajouter un match » a son propre libellé de bouton et un message clair « Match date is invalid », traduit dans les trois langues (`src/Client/Localization/SharedResource.resx`).
- « Mes clubs » affiche désormais en premier les clubs rejoints le plus récemment (`src/Infrastructure/Clubs/ClubMembershipRepository.cs`).
- La limite de tentatives de connexion peut se régler dans la configuration, avec 10 par minute par défaut (`src/Api/Extensions/ServiceCollectionExtensions.cs`).

## Une mise à niveau de base de données plus sûre

La migration qui a supprimé le multi-tenant modifiait la colonne du thème du club sur place, ce qui ne fonctionne pas de la même façon sur toutes les bases. Elle ajoute maintenant une nouvelle colonne numérique, y reporte les anciens noms de thème (les noms inconnus deviennent Default), puis la met en place (`src/Infrastructure/Persistence/Migrations/20260619135730_RemoveTenantFunctionality.cs`, commit 3d66ca2).

## Sources

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
