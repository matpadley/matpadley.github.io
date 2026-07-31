---
title: "Initial Application Implementation"
date: 2026-07-29T15:30:00+01:00
draft: false
description: "The first working pass: a .NET 10 Minimal API with EF Core multi-tenancy, a UNO Platform front end with swappable themes, NUnit and Playwright coverage, Bicep infrastructure and CI."
summary: "The first working pass: a .NET 10 Minimal API with EF Core multi-tenancy, a UNO Platform front end with swappable themes, NUnit and Playwright coverage, Bicep infrastructure and CI."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - uno-platform
  - minimal-api
  - bicep
source: "2026-07-29-1530-initial-application-implementation.md"
---

## What changed

Implemented the first working version of the application described in `Docs/main_spec.md`:

### Backend — `src/ClubMonitor.Api` (.NET 10 Minimal API)
- EF Core code-first model: `Sport`, `Club`, `ClubSport`, `User`, `Membership`, `Competition` (league/cup, club-owned or platform-wide), `CompetitionClub`, `CompetitionEntry`, `Match`. Initial migration created (`Migrations/`).
- Multi-tenancy: `Club` is the tenant boundary. EF Core global query filters partition club-scoped data by `ClubId`; Super Admin bypasses the filter; platform-wide competitions (`ClubId == null`) span clubs via `CompetitionClub`; competitions whose results are set to Public are readable by anyone.
- Handler Methodology: one discrete handler class per feature (`Handlers/…`) returning a transport-agnostic `HandlerResult<T>`; endpoints (`Endpoints/ApiEndpoints.cs`) only bind, delegate, and translate to HTTP.
- Domain rules: per-club roles, invite + accept and request-to-join + approve membership flows, promote-to-admin, sport catalog managed by Super Admin, sport auto-select when a club has exactly one sport, admin-only results and visibility (Private/Public), standings computed 3/1/0 with score-difference tiebreak.
- Identity: `CurrentUserMiddleware` resolves the user/club context from `X-User-Id`/`X-Club-Id` headers — a development stand-in for a real auth provider; handlers only see `ITenantContext`.
- Observability: OpenTelemetry traces/metrics/logs with exporter switched by `Telemetry:Exporter` config (`console`/`otlp`/`none`) — swappable per environment without code changes.

### Unit tests — `tests/ClubMonitor.Api.Tests` (NUnit + EF InMemory)
27 tests covering the sport catalog, membership flows, per-club role isolation, sport auto-select rule, platform competitions, visibility, match scheduling/results, and standings computation. All pass.

### Front end — `src/ClubMonitor.App` (UNO Platform, WASM + desktop heads)
- Swappable theme/template architecture: `Themes/OrganicTheme.xaml` and `Themes/NocturneTheme.xaml` define the same resource keys; `ThemeService` swaps the merged dictionary at runtime (Shell has a "Swap theme" button); pages never change.
- Screens per spec: Dashboard (greeting, quick actions, leagues & cups with tags, upcoming matches, standings preview), Members (avatar initials, role/status tags), Leagues, Standings, Player profile.
- Responsive navigation: sidebar on wide (web/desktop), bottom nav bar on narrow (phone/tablet) via `AdaptiveTrigger`.
- `ApiClient` typed client with sample-data fallback so the UI runs standalone.
- **Note:** the UNO app targets `net9.0-browserwasm`/`net9.0-desktop` — the installed Uno.Sdk templates do not support .NET 10 yet. The .NET 10 rule is applied to all backend code. Revisit when Uno ships net10 TFMs.
- Fixed a startup crash (`FpsHelper` type initializer): the Skia renderer's native libraries need `WasmBuildNative=true` plus the `wasm-tools`/`wasm-tools-net9` workloads. Both workloads are installed locally and in CI.

### E2E tests — `tests/ClubMonitor.UiTests` (Playwright + NUnit)
Smoke tests against the running WASM head (app loads without errors, Skia canvas renders, phone/desktop viewport resize). Located via `CLUBMONITOR_APP_URL`; ignored when unset. All 3 pass locally. The Skia renderer draws to a canvas, so assertions are document-level rather than DOM-text queries.

### Infrastructure & CI/CD
- `infra/main.bicep` (+ staging/production `.bicepparam`): App Service plan, API web app, static web app for the UNO head, Azure SQL server + database. Compiles with `az bicep build`. Staging and production deploy to separate subscriptions selected by each GitHub environment's OIDC credentials.
- `.github/workflows/build-test.yml`: build + NUnit on PR/push; separate job boots the WASM app and runs Playwright.
- `.github/workflows/deploy.yml`: OIDC login (no long-lived secrets), Bicep deployment, EF migrations, zip deploy of API and web head. Staging on merge to master; production via manual dispatch with environment protection.

### Source control
Repository initialised (`master` default, no direct commits); all work is on `feature/initial-application` for PR review.

## Why
First implementation pass covering every mandatory rule in `Docs/main_spec.md`.

## Files touched
Everything under `src/`, `tests/`, `infra/`, `.github/workflows/`, `ClubMonitor.slnx`, `.gitignore`, `README.md`, plus this entry.
