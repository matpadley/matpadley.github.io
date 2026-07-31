---
title: "Authentication: Social Sign-In, Two-Factor, and Securing the API"
date: 2026-07-29T17:30:00+01:00
draft: false
description: "ASP.NET Core Identity with JWT bearer tokens, four external providers, and passkeys pressed into service as a second factor — plus the Identity schema-version trap that silently drops the passkey table."
summary: "ASP.NET Core Identity with JWT bearer tokens, four external providers, and passkeys pressed into service as a second factor — plus the Identity schema-version trap that silently drops the passkey table."
tags:
  - club-monitor
  - dotnet
  - aspnet-core-identity
  - authentication
  - security
  - passkeys
source: "2026-07-29-1730-authentication-social-2fa-and-api-security.md"
---

## What changed

Added a login screen and put the whole application behind it. The API is now token-secured and the header-based development identity is gone.

### Spec first
`Docs/main_spec.md` had no authentication section, so one was added (and `CLAUDE.md` updated to match) before writing code, per the working agreement. It records the sign-in methods, the two-factor rules, the token/claims model, and the two deviations described below.

### Identity model — `src/ClubMonitor.Api`
- `User` now extends `IdentityUser<int>`; `ClubMonitorDbContext` extends `IdentityDbContext`. `DisplayName`, `IsSuperAdmin` and `Memberships` stay, plus a new `TwoFactorMethod`.
- New migration `AddIdentityAuthentication` (users/roles/logins/tokens/claims/passkeys). The dev database was dropped and rebuilt.

### Sign-in
- **External providers**: Google, Facebook, X (Twitter) and Apple. Each registers only when its credentials are configured, so the app runs locally with none set and the login screen only shows buttons that will work.
- **Email + password** via Identity, with lockout after 5 failures and a minimum 10-character password.
- **Two-factor** on the password path: **email**, **text (SMS)** or **passkey**. Email/SMS go through swappable `IEmailSender`/`ISmsSender`; local development logs the code instead of sending it.
- **Passwordless passkey sign-in** as well, which is the framework-supported passkey scenario.

### Tokens and tenancy
- `JwtTokenService` issues access tokens carrying user id, active club and the super-admin flag. A correct password with 2FA enabled returns only a short-lived **pending token**, which is rejected everywhere except the two-factor completion endpoints.
- `CurrentUserMiddleware` no longer reads `X-User-Id`/`X-Club-Id`; it builds the tenant context from verified token claims, so a caller can no longer select another tenant by editing a header. Club switching goes through `/api/auth/select-club/{id}`, which re-checks membership server-side.

### Front end — `src/ClubMonitor.App`
- New `LoginPage` (password, 2FA step, passkey, social buttons), `AuthService` owning the session, and passkey WebAuthn interop for the WASM head.
- The app root shows the login screen until a session is confirmed and swaps to the shell on sign-in; a sign-out button was added to the shell.
- `ApiClient` now sends the bearer token and **no longer falls back to invented sample data** — that fallback previously disguised a completely broken API connection, so failures now surface as empty rather than fictional content.

## Two deliberate deviations, both flagged in the spec

1. **Passkey as a second factor is not something ASP.NET Core Identity supports.** Its docs state passkeys are "treated as a primary authentication factor, not as a second factor". The requested behaviour was built directly on `PerformPasskeyAssertionAsync`, and its safety rests on `VerifyPasskeyTwoFactorHandler` asserting the asserted user matches the user who passed the password step — without that check any valid passkey would finish anyone's sign-in. There is a test for it.
2. **Public results stay anonymous-readable.** "Secure the API" conflicts with the existing domain rule that an Admin can publish results as "public (visible to anyone)". The standings and match-list endpoints therefore allow anonymous callers and the handler continues to enforce visibility; everything else requires a token. All *pages* still require sign-in.

## A framework trap worth recording

Identity maps the passkey table only from **schema version 3**; versions 1 and 2 call `Ignore` on the passkey entity, and **version 1 is the default**. The version is read from `IdentityOptions.Stores.SchemaVersion` through the *application service provider*, which a design-time factory does not have — so migrations scaffolded with no passkey table even after the option was set at runtime. Fixed by setting it in `Program.cs` for runtime and giving `DesignTimeDbContextFactory` a service provider via `UseApplicationServiceProvider`. Overriding the `SchemaVersion` property does **not** work: `OnModelCreating` reads the options directly and bypasses it.

## Verification

- **49 NUnit tests** (was 27): registration, password rules, identical responses for unknown-email vs wrong-password, the 2FA flows for email/SMS/passkey, lockout of invalid 2FA configurations, token claim contents, and that a pending token establishes no tenant context.
- **6 Playwright tests** (was 3): the app requests no club data before sign-in, the API returns 401 without a token, and published results are not behind 401.
- **Driven live in a browser** against SQL Server: sign-in → 2FA challenge → code read from the dev log → verified → dashboard loaded with an authenticated `/api/competitions` call.

## Files touched

New `Handlers/Auth/*`, `Infrastructure/Auth/*`, `Infrastructure/Notifications/*`, `Endpoints/AuthEndpoints.cs`, `Endpoints/EndpointResults.cs`; modified `Domain/User.cs`, `Data/*`, `Endpoints/ApiEndpoints.cs`, `Program.cs`, app settings, `infra/main.bicep`, `.github/workflows/deploy.yml`; new `Views/LoginPage.*` and `Services/*` in the app; new tests; `Docs/main_spec.md`, `CLAUDE.md`, `README.md`.
