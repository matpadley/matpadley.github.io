---
title: "Stop One-Time Codes Reaching the Log Outside Development"
date: 2026-07-31T09:30:00+01:00
draft: false
description: "The log-only two-factor senders were registered unconditionally, so production would have written every code into the application log. A comment is not a control."
summary: "The log-only two-factor senders were registered unconditionally, so production would have written every code into the application log. A comment is not a control."
tags:
  - club-monitor
  - dotnet
  - security
  - two-factor
  - configuration
source: "2026-07-31-0930-stop-one-time-codes-reaching-the-log.md"
---

## The defect

`Program.cs` registered the log-only senders unconditionally:

```csharp
// Staging and production must register a real provider here...
builder.Services.AddScoped<IEmailSender, LoggingEmailSender>();
builder.Services.AddScoped<ISmsSender, LoggingSmsSender>();
```

Every environment inherited them, so a deployment would have written **every two-factor code into the application log and OpenTelemetry** — defeating the second factor for anyone who could read logs, while appearing to work perfectly. The only safeguard was a comment, and a comment is not a control.

## The fix

Sender selection is now configuration-driven with startup guards in `NotificationExtensions`. The governing idea is that **an unsafe default must be impossible, and any opt-out must be explicit**:

- The `Logging` providers are **refused outside Development** — the application throws at startup with an actionable message rather than booting in a leaking state.
- Outside Development an **unset** provider is an error, not a default. This is the important half: the original bug was a silent fallback, so silence must now fail loudly.
- Delivery can be switched off anywhere, but only by stating `None`. That registers `UnavailableEmailSender`/`UnavailableSmsSender`, which report `IsConfigured = false` and **throw** if invoked — silently discarding a code would lock a user out with no trace.
- `Smtp` is rejected at startup when `Host` or `FromAddress` is missing, since it could never deliver.

`IEmailSender`/`ISmsSender` gained `IsConfigured` so the lockout case is handled properly rather than by exception:

- `ConfigureTwoFactorHandler` refuses to let a user *enable* a factor this deployment cannot deliver.
- `SendTwoFactorCodeHandler` returns a clean validation error instead of letting the unavailable sender throw.

`SmtpEmailSender` was added so there is a real production path, using the BCL SMTP client (no new dependency). Its logging deliberately omits the message body, which contains the code.

## Verification

Unit tests cover the guards (62 total, up from 50), but the guards were also exercised against a real host — the earlier attempt to do this silently ran nothing, because `timeout` does not exist on macOS and the greps matched an empty log. Redone properly:

| Configuration | Result |
|---|---|
| Production + `Logging` (the original bug) | refused to start |
| Production, nothing configured | refused to start |
| Production + explicit `None` | started, health 200 |
| Production + `Smtp` fully configured | started, health 200 |
| Development (defaults to log-only) | started, health 200 |

## Also updated

`infra/main.bicep` gained the notification settings (email provider defaults to `None`, so a deploy is safe but email 2FA is off until an SMTP relay is configured), and `deploy.yml` passes them through. Spec, `CLAUDE.md` and `README` record the rules, including an explicit instruction not to "fix" a startup failure by reintroducing a default.

## Not done

No SMS transport is implemented — there is no BCL equivalent — so text-message two-factor needs a provider (Twilio, Azure Communication Services) behind `ISmsSender`. `SmtpEmailSender` has not been exercised against a real SMTP server; only its selection and configuration validation are tested.

## Files touched

`src/ClubMonitor.Api/Infrastructure/Notifications/*` (interfaces, logging senders, new unavailable senders, new SMTP sender, options, registration), `Program.cs`, `Handlers/Auth/ConfigureTwoFactorHandler.cs`, `Handlers/Auth/SendTwoFactorCodeHandler.cs`, both appsettings files, `infra/main.bicep`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, tests, plus this entry.
