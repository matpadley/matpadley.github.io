---
title: "One club, one API, and an easier way to try it locally"
date: 2026-10-23T09:00:00+01:00
draft: false
description: "ClubMonitor now serves a single club, talks to its API through a generated client, runs locally without Docker, and has new safety rails for AI-assisted work."
summary: "ClubMonitor now serves a single club, talks to its API through a generated client, runs locally without Docker, and has new safety rails for AI-assisted work."
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

Since the last update, nine commits touched about 270 files, and the biggest change is a simplification: ClubMonitor now looks after one club.

## A correction: no more multi-tenancy

Earlier articles described ClubMonitor as a multi-tenant app, one installation serving many clubs. That is no longer true. The tenant-resolution and tenant-status middleware, the tenant claim and the multi-tenancy plan document have all been removed (commit 20c53e1). `CLAUDE.md` now states the single-club rule plainly (`CLAUDE.md`). Fewer moving parts means fewer ways for things to go wrong.

## The pages now talk to a versioned API

Screens no longer reach into the application's internals. They call the HTTP API under `/api/v1/` through a small client wrapper, which in turn uses a client generated from the API's published description (commit 8dd12f1). New routes for clubs, cups, members and user profiles filled the remaining gaps, backed by a long set of tests (commit f17ab6d). A script refreshes the generated client, and a test fails if it goes stale. Breaking changes will get a new version rather than an edit to v1 (`docs/api-versioning.md`).

## Runnable without Docker

For trying things out, there is now a SQLite option for local development and testing. One script starts the app on a local file with a demo club, league and cup, no Docker needed (commit 30cf062, `scripts/run-local-sqlite.sh`). It is for Development only and never used in production.

## Safer, test-first help from AI agents

For developers, two testing agents were added. One audits the project for missing tests, the other writes tests for the files you just changed (commits 85b47c1, 8bc0496). A hook restricts them to editing files under `tests/`, and the first run added about 1,800 lines of new tests. Another hook stops Claude from committing or pushing to `main` (commit 338c35c). Small follow-ups fixed the Docker setup in CI and added a README-writing skill (commit 0f2a359).

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
