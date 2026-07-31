---
title: "Point the Repo at main, and Un-break the CI Triggers"
date: 2026-07-30T10:00:00+01:00
draft: false
description: "Renaming the default branch to main left both GitHub Actions workflows triggering on a branch that no longer existed — so the CI safety net had never once fired."
summary: "Renaming the default branch to main left both GitHub Actions workflows triggering on a branch that no longer existed — so the CI safety net had never once fired."
tags:
  - club-monitor
  - github-actions
  - ci-cd
source: "2026-07-30-1000-default-branch-main-and-fix-ci-triggers.md"
---

## Why

The repository is now `matpadley/Club-monitor-uni` (private) with **`main`** as the default branch; the original `feature/initial-application` branch was renamed to `main` and pushed. Everything written before that assumed `master`.

The important consequence was not cosmetic: **both GitHub Actions workflows triggered on `master`**, a branch that no longer exists. Neither `build-test` nor `deploy` would ever have fired, so the CI safety net was silently absent — the workflows have in fact never run.

## What changed

- `.github/workflows/build-test.yml`: `pull_request`/`push` triggers `master` → `main`.
- `.github/workflows/deploy.yml`: `push` trigger and the header comment `master` → `main`.
- `Docs/main_spec.md`, `CLAUDE.md`, `README.md`: source-control rules now name `main`, and the spec records that the initial import went straight to `main` before the PR rule could be enforced, with everything after it going through a PR.

Deliberately left alone: "master sport catalog" in the spec (unrelated meaning), the upstream Uno docs URL in `SharedAssets.md`, and the historical `progress/` entries, which are never edited.

## Note on process

This change is itself the first one to follow the mandated workflow — branched off `main`, pushed, and raised as a pull request rather than committed directly.

Branch protection on `main` is **not** yet configured, so the PR rule is convention rather than enforcement.

## Files touched

`.github/workflows/build-test.yml`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, plus this entry.
