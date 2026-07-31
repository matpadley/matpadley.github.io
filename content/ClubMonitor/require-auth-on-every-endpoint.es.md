---
title: "Requerir Autenticación en Todos los Endpoints"
date: 2026-07-29T18:15:00+01:00
draft: false
description: "Hacer los resultados publicados legibles de forma anónima había añadido una cláusula de visibilidad en los filtros de consulta global de EF Core — lo que silenciosamente exponía cada competición pública a todos los demás clubes. Ambos desaparecieron."
summary: "Hacer los resultados publicados legibles de forma anónima había añadido una cláusula de visibilidad en los filtros de consulta global de EF Core — lo que silenciosamente exponía cada competición pública a todos los demás clubes. Ambos desaparecieron."
tags:
  - club-monitor
  - dotnet
  - security
  - multi-tenancy
  - ef-core
---

## Qué cambió

La especificación anteriormente decía que los resultados publicados debían permanecer legibles de forma anónima. Eso se corrigió: **todos los endpoints de la API ahora requieren un token de acceso**, con solo los endpoints de inicio de sesión `/api/auth/*` y la sonda `/health` siendo anónimos. Los resultados de ligas y copas disponibles públicamente se convierten en una funcionalidad futura.

- `Docs/main_spec.md` y `CLAUDE.md`: se reescribieron las reglas de seguridad de la API, y los resultados públicos se registraron como *planificados* en lugar de actuales.
- `Endpoints/ApiEndpoints.cs`: se eliminó `AllowAnonymous` de los endpoints de clasificaciones y lista de partidos. Ya no hay excepciones anónimas en este archivo.
- `Handlers/Competitions/GetStandingsHandler.cs`: se eliminó la comprobación anónima/visibilidad. Era inalcanzable una vez que el endpoint requería token, y el código de seguridad inalcanzable invita a una falsa confianza. El handler ya no toma `ITenantContext`.

## Se revirtió un debilitamiento del aislamiento de tenants

Los filtros de consulta de EF Core para `Competition`, `Match` y `CompetitionEntry` llevaban cada uno una cláusula extra:

```csharp
|| c.Visibility == CompetitionVisibility.Public
```

Eso se añadió únicamente para que los resultados públicos anónimos funcionaran. Su efecto real era mucho más amplio de lo previsto: porque estaba en el *filtro de consulta global*, cualquier club marcado como `Public` era legible desde **el contexto de tenant de cualquier otro club**, a través de cada consulta en la aplicación — el Admin de un club rival podía listar las competiciones de otro club. Con la publicación anónima diferida no hay justificación para ello, así que las tres cláusulas fueron eliminadas y el aislamiento estricto de `ClubId` fue restaurado. Las competiciones a nivel de plataforma (`ClubId == null`) siguen siendo compartidas, que es el diseño de multitenancy documentado.

La especificación y `CLAUDE.md` ahora advierten que cuando se implementen los resultados públicos, debe hacerse abriendo endpoints publicados específicos — no poniendo la visibilidad de vuelta en los filtros de tenant.

## Pruebas

- Se reemplazó `Private_results_are_hidden_from_anonymous_users_until_made_public` por `Results_stay_hidden_outside_the_club_even_when_marked_public`, que fija la nueva regla.
- Se añadió `A_public_competition_is_not_visible_to_a_different_club`, que cubre el agujero de aislamiento descrito arriba.
- Se reemplazó la prueba Playwright que afirmaba que los resultados eran legibles de forma anónima por una que afirma que devuelven 401, más `Only_the_sign_in_endpoints_and_health_are_anonymous`, que barre la superficie de la API.
- **50 pruebas NUnit** y **7 pruebas Playwright** pasan. Un barrido en vivo confirmó 401 en `/api/sports`, `/api/clubs`, `/api/members`, `/api/competitions`, `/api/competitions/1/standings`, `/api/competitions/1/matches` y `/api/auth/me`; 200 en `/health`; y el login aún es accesible de forma anónima. El flujo de inicio de sesión en el navegador → 2FA → dashboard fue ejecutado de nuevo de extremo a extremo.

## Nota

`/health` se dejó anónimo deliberadamente: devuelve un estado fijo sin datos de la aplicación y es lo que llama una sonda de Azure App Service o un balanceador de carga. Diga la palabra si también debería bloquearse.

## Archivos modificados

`Docs/main_spec.md`, `CLAUDE.md`, `README.md`, `src/ClubMonitor.Api/Data/ClubMonitorDbContext.cs`, `src/ClubMonitor.Api/Endpoints/ApiEndpoints.cs`, `src/ClubMonitor.Api/Handlers/Competitions/GetStandingsHandler.cs`, `tests/ClubMonitor.Api.Tests/MatchAndStandingsTests.cs`, `tests/ClubMonitor.UiTests/LoginTests.cs`, más esta entrada.
