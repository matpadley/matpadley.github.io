---
title: "Claude tooling, sturdier tests and a few small fixes"
date: 2026-10-26T13:50:00+00:00
draft: false
description: "ClubMonitor moves its AI helpers from Copilot to Claude, gets steadier automated checks, and fixes a handful of everyday rough edges."
summary: "ClubMonitor moves its AI helpers from Copilot to Claude, gets steadier automated checks, and fixes a handful of everyday rough edges."
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

This update is mostly about the workshop rather than the product: how ClubMonitor is built and checked has been tidied, with a few small improvements you may notice along the way.

## Developer guidance moved from Copilot to Claude

The project's coding instructions used to live in GitHub Copilot files. They now live next to the code in short per-folder guides that Claude loads automatically (commit 7f064c9, `src/CLAUDE.md`). The old Copilot instruction and agent files are gone, and the shared rules sit in one place, `docs/coding-conventions.md`, so there is a single source of truth (commit 19622dc). New helpers include a code reviewer, an accessibility specialist and a changelog writer (`.claude/agents/code-reviewer.md`).

## Steadier automated checks

The browser-based end-to-end tests were reworked so they stop tripping over timing and page-state quirks (commits aa9bf39, 1eccbee, 7f38e33, `tests/Playwright.Tests/`). The build pipeline lost some broken steps, gained a run of the client unit tests, and test packages were pinned to known versions (commit 19622dc, `.github/workflows/ci.yml`, `Directory.Packages.props`). Package updates were merged along the way (PR #212).

## Small fixes you might notice

- The club search page no longer stops at 500 clubs; it fetches them page by page and shows the newest first (`src/Client/Components/Pages/Clubs/SearchClubs.razor`). Any signed-in user can now open it, not only those with the Standard role, and the Join button label renders correctly.
- The "Add match" dialog has its own button wording and a clear "Match date is invalid" message, translated into all three languages (`src/Client/Localization/SharedResource.resx`).
- "My clubs" now lists the most recently joined first (`src/Infrastructure/Clubs/ClubMembershipRepository.cs`).
- The login rate limit can be set in configuration, defaulting to 10 attempts a minute (`src/Api/Extensions/ServiceCollectionExtensions.cs`).

## A safer database upgrade

The migration that removed multi-tenancy used to change the club theme column in place, which does not work the same on every database. It now adds a new numeric column, maps the old theme names across (unknown names fall back to Default), then swaps it in (`src/Infrastructure/Persistence/Migrations/20260619135730_RemoveTenantFunctionality.cs`, commit 3d66ca2).

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
