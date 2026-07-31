---
title: "Require Authentication on Every Endpoint"
date: 2026-07-29T18:15:00+01:00
draft: false
description: "Making published results anonymously readable had put a visibility clause in the EF Core global query filters — which quietly exposed every public competition to every other club. Both went."
summary: "Making published results anonymously readable had put a visibility clause in the EF Core global query filters — which quietly exposed every public competition to every other club. Both went."
tags:
  - club-monitor
  - dotnet
  - security
  - multi-tenancy
  - ef-core
source: "2026-07-29-1815-require-auth-on-every-endpoint.md"
---

## What changed

The spec previously said published results had to stay anonymously readable. That was corrected: **every API endpoint now requires an access token**, with only the `/api/auth/*` sign-in endpoints and the `/health` probe anonymous. Publicly available league and cup results become a future feature.

- `Docs/main_spec.md` and `CLAUDE.md`: rewrote the API security rules, and recorded public results as *planned* rather than current.
- `Endpoints/ApiEndpoints.cs`: removed `AllowAnonymous` from the standings and match-list endpoints. There are now no anonymous exceptions in this file.
- `Handlers/Competitions/GetStandingsHandler.cs`: dropped the anonymous/visibility check. It was unreachable once the endpoint required a token, and unreachable security code invites false confidence. The handler no longer takes `ITenantContext`.

## Reverted a tenant-isolation weakening

The EF Core query filters for `Competition`, `Match` and `CompetitionEntry` each carried an extra clause:

```csharp
|| c.Visibility == CompetitionVisibility.Public
```

That was added purely to make anonymous public results work. Its real effect was much wider than intended: because it sat in the *global* query filter, any club marked `Public` became readable from **every other club's tenant context**, through every query in the application — a rival club's Admin could list another club's competitions. With anonymous publishing deferred there is no justification for it, so all three clauses were removed and strict `ClubId` isolation restored. Platform-wide competitions (`ClubId == null`) are still shared, which is the documented multi-tenancy design.

The spec and `CLAUDE.md` now both warn that when public results are implemented, it must be done by opening specific published endpoints — not by putting visibility back into the tenant filters.

## Tests

- Replaced `Private_results_are_hidden_from_anonymous_users_until_made_public` with `Results_stay_hidden_outside_the_club_even_when_marked_public`, which pins the new rule.
- Added `A_public_competition_is_not_visible_to_a_different_club`, covering the isolation hole described above.
- Replaced the Playwright test asserting results were anonymously readable with one asserting they return 401, plus `Only_the_sign_in_endpoints_and_health_are_anonymous`, which sweeps the API surface.
- **50 NUnit tests** and **7 Playwright tests** pass. A live sweep confirmed 401 on `/api/sports`, `/api/clubs`, `/api/members`, `/api/competitions`, `/api/competitions/1/standings`, `/api/competitions/1/matches` and `/api/auth/me`; 200 on `/health`; and login still reachable anonymously. The browser sign-in → 2FA → dashboard flow was re-run end to end.

## Note

`/health` was left anonymous deliberately: it returns a fixed status with no application data and is what an Azure App Service probe or load balancer calls. Say the word if it should be locked down too.

## Files touched

`Docs/main_spec.md`, `CLAUDE.md`, `README.md`, `src/ClubMonitor.Api/Data/ClubMonitorDbContext.cs`, `src/ClubMonitor.Api/Endpoints/ApiEndpoints.cs`, `src/ClubMonitor.Api/Handlers/Competitions/GetStandingsHandler.cs`, `tests/ClubMonitor.Api.Tests/MatchAndStandingsTests.cs`, `tests/ClubMonitor.UiTests/LoginTests.cs`, plus this entry.
