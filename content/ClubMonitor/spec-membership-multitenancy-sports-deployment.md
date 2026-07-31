---
title: "Writing Down the Rules: Membership, Multi-Tenancy, Sports and Deployment"
date: 2026-07-29T15:00:00+01:00
draft: false
description: "Before any code, the spec grew a Super Admin role, a club-as-tenant boundary, a database-driven sport catalog, Bicep environments and a PR-only workflow."
summary: "Before any code, the spec grew a Super Admin role, a club-as-tenant boundary, a database-driven sport catalog, Bicep environments and a PR-only workflow."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - multi-tenancy
  - architecture
source: "2026-07-29-1500-spec-membership-multitenancy-sports-deployment.md"
---

## What changed
Expanded `Docs/main_spec.md` and `CLAUDE.md` with several new requirements:

- **Technologies**: added EF Core (code-first) as the ORM, OpenTelemetry-based observability with a swappable exporter/backend, official C# coding conventions reference, and clarified local dev uses a local SQL Server instance.
- **Testing**: unit tests now specified to use the EF Core InMemory database provider.
- **Roles**: introduced a third role, **Super Admin** (platform-level, manages the sport catalog and assigns sports to clubs), alongside existing Admin and Standard roles.
- **Membership & Roles** (new section): documented the invite-by-Admin and request-to-join flows, and that roles are per-club.
- **Multi-tenancy** (new section): Club is the tenant boundary, `ClubId`-based EF Core global query filters, platform-wide leagues span clubs via a join table.
- **Sports** (new section): sports are a database-driven catalog managed by Super Admin; every club must have ≥1 sport; league/cup creation auto-selects the sport if the club has only one, otherwise prompts the user to choose.
- **Deployment & CI/CD**: added Bicep as the IaC tool, defined Local/Staging/Production environments, and required Staging and Production to live in separate Azure subscriptions.
- **Source Control** (new section): all changes must go through a Pull Request; direct commits to `master` are disallowed.

## Why
User requested these additions to flesh out the spec: membership/role flow, multi-tenancy, swappable observability, EF Core, environment/deployment strategy (Bicep, separate subscriptions for staging/prod), InMemory DB for unit tests, coding conventions, database-driven sport catalog with per-club assignment logic, and a PR-only source control workflow.

## Files touched
- `Docs/main_spec.md`
- `CLAUDE.md`
