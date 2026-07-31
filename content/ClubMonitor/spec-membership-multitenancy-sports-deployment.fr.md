---
title: "Écrire les Règles : Adhésion, Multi-Tenancy, Sports et Déploiement"
date: 2026-07-29T15:00:00+01:00
draft: false
description: "Avant d'écrire la moindre ligne de code, la spécification a intégré un rôle Super Admin, le club comme frontière de tenant, un catalogue de sports géré en base de données, des environnements Bicep et un flux de travail basé uniquement sur les Pull Requests."
summary: "Avant d'écrire la moindre ligne de code, la spécification a intégré un rôle Super Admin, le club comme frontière de tenant, un catalogue de sports géré en base de données, des environnements Bicep et un flux de travail basé uniquement sur les Pull Requests."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - multi-tenancy
  - architecture
---

## Ce qui a changé
`Docs/main_spec.md` et `CLAUDE.md` ont été enrichis de plusieurs nouvelles exigences :

- **Technologies** : ajout d'EF Core (code-first) comme ORM, observabilité basée sur OpenTelemetry avec exportateur/backend interchangeable, référence aux conventions officielles de codage C#, et précision que le développement local utilise une instance SQL Server locale.
- **Tests** : les tests unitaires sont désormais spécifiés pour utiliser le fournisseur de base de données InMemory d'EF Core.
- **Rôles** : introduction d'un troisième rôle, **Super Admin** (niveau plateforme, gère le catalogue des sports et assigne les sports aux clubs), aux côtés des rôles Admin et Standard existants.
- **Adhésion & Rôles** (nouvelle section) : documentation des flux d'invitation par un Admin et de demande d'adhésion, et précision que les rôles sont par club.
- **Multi-Tenancy** (nouvelle section) : le Club est la frontière de tenant, filtres de requête globaux EF Core basés sur `ClubId`, les ligues à l'échelle de la plateforme couvrent plusieurs clubs via une table de jointure.
- **Sports** (nouvelle section) : les sports forment un catalogue géré en base de données administré par le Super Admin ; chaque club doit avoir ≥1 sport ; la création d'une ligue/coupe sélectionne automatiquement le sport si le club n'en a qu'un, sinon l'utilisateur est invité à choisir.
- **Déploiement & CI/CD** : ajout de Bicep comme outil d'IaC, définition des environnements Local/Staging/Production, et obligation que Staging et Production résident dans des abonnements Azure séparés.
- **Contrôle des sources** (nouvelle section) : toutes les modifications doivent passer par une Pull Request ; les commits directs sur `master` sont interdits.

## Pourquoi
L'utilisateur a demandé ces ajouts pour compléter la spécification : flux d'adhésion/rôles, multi-tenancy, observabilité interchangeable, EF Core, stratégie d'environnement/déploiement (Bicep, abonnements séparés pour staging/production), BD InMemory pour les tests unitaires, conventions de codage, catalogue de sports géré en base de données avec logique d'attribution par club, et un flux de travail de contrôle des sources uniquement par PR.

## Fichiers modifiés
- `Docs/main_spec.md`
- `CLAUDE.md`
