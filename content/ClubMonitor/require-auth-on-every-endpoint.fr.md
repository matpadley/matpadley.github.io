---
title: "Exiger l'Authentification sur Chaque Endpoint"
date: 2026-07-29T18:15:00+01:00
draft: false
description: "Rendre les résultats publiés lisibles anonymement avait ajouté une clause de visibilité dans les filtres de requête globaux EF Core — exposant silencieusement chaque compétition publique à tous les autres clubs. Les deux ont disparu."
summary: "Rendre les résultats publiés lisibles anonymement avait ajouté une clause de visibilité dans les filtres de requête globaux EF Core — exposant silencieusement chaque compétition publique à tous les autres clubs. Les deux ont disparu."
tags:
  - club-monitor
  - dotnet
  - security
  - multi-tenancy
  - ef-core
---

## Ce qui a changé

La spec indiquait auparavant que les résultats publiés devaient rester lisibles anonymement. Cela a été corrigé : **chaque endpoint de l'API requiert désormais un token d'accès**, seuls les endpoints de connexion `/api/auth/*` et la sonde `/health` restant anonymes. Les résultats de ligues et coupes accessibles publiquement deviennent une fonctionnalité future.

- `Docs/main_spec.md` et `CLAUDE.md` : réécriture des règles de sécurité de l'API, et enregistrement des résultats publics comme *planifiés* plutôt que actuels.
- `Endpoints/ApiEndpoints.cs` : suppression de `AllowAnonymous` sur les endpoints de classements et de liste de matchs. Il n'y a désormais plus d'exceptions anonymes dans ce fichier.
- `Handlers/Competitions/GetStandingsHandler.cs` : suppression de la vérification anonyme/visibilité. Elle était inaccessible une fois que l'endpoint nécessitait un token, et du code de sécurité inaccessible invite à une fausse confiance. Le handler ne prend plus `ITenantContext`.

## Annulation d'un affaiblissement de l'isolation de tenant

Les filtres de requête EF Core pour `Competition`, `Match` et `CompetitionEntry` portaient chacun une clause supplémentaire :

```csharp
|| c.Visibility == CompetitionVisibility.Public
```

Cela avait été ajouté uniquement pour faire fonctionner les résultats publics anonymes. Son effet réel était bien plus large que prévu : comme elle était dans le *filtre de requête global*, tout club marqué `Public` devenait lisible depuis **le contexte tenant de tout autre club**, à travers chaque requête de l'application — l'Admin d'un club rival pouvait lister les compétitions d'un autre club. La publication anonyme étant différée, rien ne justifie plus cette clause ; les trois ont donc été supprimées et l'isolation stricte par `ClubId` rétablie. Les compétitions à l'échelle de la plateforme (`ClubId == null`) restent partagées, ce qui correspond à la conception multi-tenancy documentée.

La spec et `CLAUDE.md` avertissent désormais tous les deux que lorsque les résultats publics seront implémentés, cela devra se faire en ouvrant des endpoints publiés spécifiques — pas en remettant la visibilité dans les filtres de tenant.

## Tests

- Remplacement de `Private_results_are_hidden_from_anonymous_users_until_made_public` par `Results_stay_hidden_outside_the_club_even_when_marked_public`, qui fixe la nouvelle règle.
- Ajout de `A_public_competition_is_not_visible_to_a_different_club`, couvrant le trou d'isolation décrit ci-dessus.
- Remplacement du test Playwright qui affirmait que les résultats étaient lisibles anonymement par un qui affirme qu'ils retournent 401, plus `Only_the_sign_in_endpoints_and_health_are_anonymous`, qui balaye la surface API.
- **50 tests NUnit** et **7 tests Playwright** passent. Un balayage en direct a confirmé 401 sur `/api/sports`, `/api/clubs`, `/api/members`, `/api/competitions`, `/api/competitions/1/standings`, `/api/competitions/1/matches` et `/api/auth/me` ; 200 sur `/health` ; et la connexion toujours accessible anonymement. Le flux connexion navigateur → 2FA → tableau de bord a été rejoué de bout en bout.

## Note

`/health` a été laissé anonyme délibérément : il retourne un statut fixe sans données applicatives et c'est ce qu'appelle une sonde Azure App Service ou un équilibreur de charge. Dites-le si cela doit aussi être verrouillé.

## Fichiers modifiés

`Docs/main_spec.md`, `CLAUDE.md`, `README.md`, `src/ClubMonitor.Api/Data/ClubMonitorDbContext.cs`, `src/ClubMonitor.Api/Endpoints/ApiEndpoints.cs`, `src/ClubMonitor.Api/Handlers/Competitions/GetStandingsHandler.cs`, `tests/ClubMonitor.Api.Tests/MatchAndStandingsTests.cs`, `tests/ClubMonitor.UiTests/LoginTests.cs`, plus cette entrée.
