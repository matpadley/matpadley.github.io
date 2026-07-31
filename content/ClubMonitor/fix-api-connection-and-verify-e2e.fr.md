---
title: "Le Frontend n'a Jamais Vraiment Communiqué avec l'API"
date: 2026-07-29T16:15:00+01:00
draft: false
description: "Chaque capture d'écran précédente montrant un \"fonctionnement\" était en réalité le bloc catch de l'ApiClient servant des données d'exemple. Un décalage d'un chiffre dans le port, et ce qu'il a fallu pour prouver que la pile était vraiment connectée."
summary: "Chaque capture d'écran précédente montrant un \"fonctionnement\" était en réalité le bloc catch de l'ApiClient servant des données d'exemple. Un décalage d'un chiffre dans le port, et ce qu'il a fallu pour prouver que la pile était vraiment connectée."
tags:
  - club-monitor
  - dotnet
  - uno-platform
  - debugging
  - testing
---

## Ce qui a changé

L'interface UNO n'a jamais été réellement vérifiée contre une API en cours d'exécution — chaque capture d'écran précédente « fonctionnelle » affichait silencieusement les données d'exemple du bloc catch de repli de l'`ApiClient`, et non de vraies réponses de l'API.

Deux vrais bugs ont été trouvés et corrigés :

1. **`src/ClubMonitor.App/Services/ApiClient.cs`** — la `BaseAddress` par défaut était `http://localhost:5210`, mais le `Properties/launchSettings.json` de l'API la fait tourner sur `5239`. Chaque requête échouait, tombait dans le bloc `catch` et retournait des données de repli. La valeur par défaut a été corrigée à `5239` (toujours remplaçable via `CLUBMONITOR_API_URL`).
2. Un piège connexe en développement local a été confirmé : exécuter l'API avec `dotnet run --no-launch-profile` passe outre la variable `ASPNETCORE_ENVIRONMENT=Development` définie dans `launchSettings.json`, ce qui charge silencieusement `appsettings.json` (`ConnectionStrings:ClubMonitor` vide) au lieu de `appsettings.Development.json`, produisant `InvalidOperationException: The ConnectionString property has not been initialized.` sur chaque endpoint touchant la BD. Ce n'est pas un bug de code, mais il est documenté ici car c'est un moyen facile de réintroduire le comportement « ça a l'air bien, ce ne l'est pas » — toujours lancer l'API localement via `dotnet run --launch-profile http` (ou simplement `dotnet run`), jamais `--no-launch-profile`.

## Vérification effectuée

- Démarrage d'un conteneur SQL Server 2022 local (`docker run ... mcr.microsoft.com/mssql/server:2022-latest`), application de la migration EF Core `InitialCreate` contre lui.
- Exécution de l'API avec son profil de lancement `http` et test de chaque couche de la pile via `curl` pour de vrai : créer un sport (Super Admin) → créer un club (crée automatiquement l'adhésion Admin) → inviter un membre → accepter l'invitation → créer une compétition sans `sportId` (confirmation que la règle de sélection automatique du sport se déclenche sur des lignes réelles en BD) → ajouter des entrées → planifier un match → enregistrer un résultat → récupérer les classements (confirmation que les points 3/0 sont calculés côté serveur à partir de vraies lignes de matchs) → isolation de tenant confirmée (une compétition de club privée retourne `[]` sans contexte de club).
- Reconstruction et exécution du head WebAssembly UNO réel pointé sur le port corrigé et capture d'écran : le tableau de bord affiche « Winter League » / Alice Admin 3 pts / Mark Member 0 pts — données réelles seedées, pas l'ancienne liste d'exemples de repli.

## Pourquoi

L'utilisateur a demandé directement si le frontend était connecté à l'API. Il ne l'était pas, à cause du décalage de port décrit ci-dessus ; cette session a corrigé et prouvé le fonctionnement de bout en bout plutôt que de supposer à partir des résultats des tests unitaires/e2e (qui utilisent EF InMemory / données simulées et n'ont jamais exercé le vrai chemin HTTP + SQL).

## Fichiers modifiés

`src/ClubMonitor.App/Services/ApiClient.cs` (correction du port), cette entrée de progression.
