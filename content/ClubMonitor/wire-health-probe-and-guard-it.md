---
title: "Wire the Health Probe Up, and Guard It Against Growing"
date: 2026-07-30T09:00:00+01:00
draft: false
description: "Why /health stays anonymous, why it was worth wiring into App Service at all, and how to stop it accreting connection strings the way health endpoints always do."
summary: "Why /health stays anonymous, why it was worth wiring into App Service at all, and how to stop it accreting connection strings the way health endpoints always do."
tags:
  - club-monitor
  - azure
  - bicep
  - security
  - observability
source: "2026-07-30-0900-wire-health-probe-and-guard-it.md"
---

## Why

Follow-up to the question of whether `/health` should be locked down. Decision: **keep it anonymous.**

The endpoint returns a hardcoded `{"status":"healthy"}`, so it discloses nothing an attacker doesn't already learn from the TLS handshake or from getting a 401 off every other route. Meanwhile App Service health checks, load balancer probes and uptime monitors cannot present a bearer token — locking it would delete an operational capability for no security gain, and would leave the health signal ambiguous (some probes read 401 as up, others as down), so real outages would go unnoticed longer.

The genuine risk is not today's endpoint but what health endpoints turn into: they accrete database connectivity, migration state, dependency versions and eventually exception text containing connection strings. So the response was to make the endpoint *earn its keep* and to fence it off from that drift.

## What changed

- **`infra/main.bicep`**: set `healthCheckPath: '/health'` on the API app. It was previously exposed but unprobed — the worst of both worlds. Verified it compiles into the ARM output on the API app only (the web head is static content with no such route). Requires the Basic tier plan or higher, which the template already uses (`B1`).
- **`src/ClubMonitor.Api/Program.cs`**: comment on the endpoint recording why it is anonymous and that the response must stay a fixed string. No behavioural change.
- **`Docs/main_spec.md`** and **`CLAUDE.md`**: added the rule that `/health` must never report database, dependency, migration, configuration or exception detail; a readiness check needing any of that goes on a **separate authenticated route**. Also recorded that if the probe itself must be hidden, that belongs at the **network** layer (App Service access restrictions, or Front Door-only ingress) rather than adding authentication that would break the probe.

## Verification

- Compiled the Bicep to ARM and asserted `healthCheckPath=/health` on the API site and unset on the web site.
- 50 NUnit tests pass. The existing Playwright test `Only_the_sign_in_endpoints_and_health_are_anonymous` already pins the intended behaviour: 401 across the API surface, 200 on `/health`.

## Files touched

`infra/main.bicep`, `src/ClubMonitor.Api/Program.cs`, `Docs/main_spec.md`, `CLAUDE.md`, plus this entry.
