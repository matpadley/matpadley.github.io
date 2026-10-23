---
title: "Un seul club, une seule API et un essai local plus simple"
date: 2026-10-23T09:00:00+01:00
draft: false
description: "ClubMonitor sert désormais un seul club, parle à son API via un client généré, fonctionne en local sans Docker et dispose de garde-fous pour le travail assisté par IA."
summary: "ClubMonitor sert désormais un seul club, parle à son API via un client généré, fonctionne en local sans Docker et dispose de garde-fous pour le travail assisté par IA."
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

Depuis la dernière mise à jour, neuf commits ont touché environ 270 fichiers, et le plus gros changement est une simplification : ClubMonitor s'occupe désormais d'un seul club.

## Une correction : fini le multi-locataire

Les articles précédents décrivaient ClubMonitor comme une application multi-locataire, une installation pour plusieurs clubs. Ce n'est plus vrai. Les middlewares de résolution et de statut des locataires, la revendication de locataire et le document du plan multi-locataire ont été supprimés (commit 20c53e1). `CLAUDE.md` énonce désormais clairement la règle du club unique (`CLAUDE.md`). Moins de pièces mobiles, c'est moins de risques de problèmes.

## Les pages parlent maintenant à une API versionnée

Les écrans n'accèdent plus aux entrailles de l'application. Ils appellent l'API HTTP sous `/api/v1/` via un petit client, lui-même généré à partir de la description publiée de l'API (commit 8dd12f1). De nouvelles routes pour les clubs, coupes, membres et profils utilisateurs comblent les derniers manques, avec de nombreux tests à l'appui (commit f17ab6d). Un script met à jour le client généré, et un test échoue s'il est périmé. Un changement incompatible aura sa propre version plutôt qu'une modification de la v1 (`docs/api-versioning.md`).

## Utilisable sans Docker

Pour essayer l'application, il existe maintenant une option SQLite pour le développement et les tests en local. Un seul script lance l'application sur un fichier local avec un club, un championnat et une coupe de démonstration, sans Docker (commit 30cf062, `scripts/run-local-sqlite.sh`). Elle sert uniquement au développement, jamais en production.

## Une aide par IA plus sûre, guidée par les tests

Côté développeurs, deux agents de test ont été ajoutés. L'un cherche les tests manquants, l'autre écrit des tests pour les fichiers que vous venez de modifier (commits 85b47c1, 8bc0496). Un hook les limite aux fichiers sous `tests/`, et la première passe a ajouté environ 1 800 lignes de tests. Un autre hook empêche Claude de valider ou de pousser sur `main` (commit 338c35c). De petits correctifs ont réparé la configuration Docker de la CI et ajouté une compétence de rédaction du README (commit 0f2a359).

## Sources

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
