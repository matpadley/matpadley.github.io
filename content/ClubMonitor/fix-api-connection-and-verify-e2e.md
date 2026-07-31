---
title: "The Front End Was Never Actually Talking to the API"
date: 2026-07-29T16:15:00+01:00
draft: false
description: "Every earlier \"working\" screenshot was the ApiClient catch block serving sample data. A one-digit port mismatch, and what it took to prove the stack really was wired together."
summary: "Every earlier \"working\" screenshot was the ApiClient catch block serving sample data. A one-digit port mismatch, and what it took to prove the stack really was wired together."
tags:
  - club-monitor
  - dotnet
  - uno-platform
  - debugging
  - testing
source: "2026-07-29-1615-fix-api-connection-and-verify-e2e.md"
---

## What changed

The UNO front end was never actually verified against a running API — every earlier "working" screenshot was silently showing `ApiClient`'s catch-block fallback sample data, not real API responses.

Two real bugs found and fixed:

1. **`src/ClubMonitor.App/Services/ApiClient.cs`** — the default `BaseAddress` was `http://localhost:5210`, but the API's `Properties/launchSettings.json` runs it on `5239`. Every request threw, hit the `catch` block, and returned fallback data. Fixed the default to `5239` (still overridable via `CLUBMONITOR_API_URL`).
2. Confirmed a related trap for local dev: running the API with `dotnet run --no-launch-profile` skips the `ASPNETCORE_ENVIRONMENT=Development` variable set in `launchSettings.json`, so it silently loads `appsettings.json` (blank `ConnectionStrings:ClubMonitor`) instead of `appsettings.Development.json`, producing `InvalidOperationException: The ConnectionString property has not been initialized.` on every DB-touching endpoint. Not a code bug, but documented here since it's an easy way to reintroduce "looks fine, isn't" behavior — always run via `dotnet run --launch-profile http` (or plain `dotnet run`) locally, not `--no-launch-profile`.

## Verification performed

- Started a local SQL Server 2022 container (`docker run ... mcr.microsoft.com/mssql/server:2022-latest`), applied the `InitialCreate` EF Core migration against it.
- Ran the API with its `http` launch profile and hit every layer of the stack for real via `curl`: create sport (Super Admin) → create club (auto-creates the Admin membership) → invite member → accept invite → create competition with no `sportId` (confirmed the sport auto-select rule fires against live DB rows) → add entries → schedule match → record result → fetch standings (confirmed 3/0 points computed server-side from real match rows) → confirmed tenant isolation (a private club competition returns `[]` when queried with no club context).
- Rebuilt and ran the actual UNO WebAssembly head pointed at the corrected port and screenshotted it: the dashboard shows "Winter League" / Alice Admin 3 pts / Mark Member 0 pts — real seeded data, not the old fallback sample list.

## Why

The user asked directly whether the front end was hooked up to the API. It was not, due to the port mismatch above; this session fixed and proved it end-to-end rather than assuming from unit/e2e test results (which use EF InMemory / mocked data and never exercised the real HTTP + SQL path).

## Files touched

`src/ClubMonitor.App/Services/ApiClient.cs` (port fix), this progress entry.
