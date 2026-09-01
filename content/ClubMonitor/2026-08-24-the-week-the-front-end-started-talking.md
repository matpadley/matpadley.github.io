---
title: "The Week the Front End Started Talking to the API"
date: 2026-08-28T11:00:00+01:00
draft: false
description: "A permission engine was deleted a week after it was built, nine screens moved onto one design system, the app got a container stack and CI, and sign-in finally called a real API — where Safari blocked it for a reason that only looked like CORS."
summary: "A permission engine was deleted a week after it was built, nine screens moved onto one design system, the app got a container stack and CI, and sign-in finally called a real API — where Safari blocked it for a reason that only looked like CORS."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - docker
  - github-actions
  - design-system
source:
  - 2026-08-24-1300-remove-user-groups-and-enforce-platform-features.md
  - 2026-08-24-1600-development-role-sign-in.md
  - 2026-08-26-1500-friendlier-sign-in-screen.md
  - 2026-08-26-1730-shared-control-styles-across-every-screen.md
  - 2026-08-27-0740-land-friendlier-login-branch.md
  - 2026-08-27-1030-club-admin-gates-on-members-leagues-cups.md
  - 2026-08-27-1450-login-page-register-link.md
  - 2026-08-27-1730-create-club-only-shell-for-new-accounts.md
  - 2026-08-27-1924-github-actions-build-and-test-workflows.md
  - 2026-08-27-1945-dev-api-endpoint-and-container-stack.md
  - 2026-08-27-2015-compose-migrate-service.md
  - 2026-08-27-2040-verify-compose-stack.md
  - 2026-08-28-1035-front-end-auth-calls-the-api.md
  - 2026-08-28-1100-browser-head-served-over-http.md
---

The previous week ended with a permission engine, a redrawn tenancy boundary and a front end that
could not sign in to anything. This week deleted the first, kept the second, and finally closed the
gap on the third — the app now creates real accounts against a real API running in a container.

## Deleting a feature three days after building it

User groups came out. Club authorization is two roles again: `Admin` and `Standard`, with Super Admin
as a platform-only role linked to no club.

Two things settled it. The first is a straightforward design argument — a club league has one or two
admins, and a club Admin already held every permission implicitly, so the bundles solved a delegation
problem this product does not have. The front-end screens for it ran on hardcoded placeholder rows and
nothing consumed them.

The second is the one worth remembering. **`ManageGroups` was a self-escalation path.** A Standard
member holding only `ManageGroups` could edit their own group to add `ManageAdmins`, then promote
themselves to full club Admin — defeating the entire point of "give them authority without making them
an Admin". A permission engine whose weakest grant reconstructs the strongest role is not a finer-grained
model, it is the same model with extra steps.

What was kept, because it is independent of groups: the Super Admin tenancy boundary, tenant domains,
club features, and club self-service. The rule now written down is that if a club genuinely needs finer
delegation later, the answer is a named role, not a permission engine.

The same pass made the **platform feature switches real**. They existed, but the method that checks
them had no caller outside its own test — so a Super Admin could switch off Competitions for a hosted
club, get a `200` back, and change nothing. Gates now sit on creating a league or cup, entering players,
scheduling fixtures, recording results, reading a standings table, every branding write, and joining a
platform-wide competition.

Two details in how those refusals read:

- The competition guard returns a **verdict** — `Allowed`, `NotAdmin` or `FeatureDisabled` — rather than
  a bool, so a switched-off feature reports `FeatureNotEnabled` instead of "you are not an admin".
  Telling a legitimate club Admin they lack authority sends them hunting for a permission problem that
  does not exist.
- **Standings is gated on the club that owns the competition**, not the caller's, so the rule still holds
  for a public reader with no club of their own once anonymous publishing lands.

## Signing in as somebody, before there was anybody to sign in as

Nothing role-dependent could be seen or demoed, because the placeholder auth service accepted any
credential and minted a session with no role at all. So the login page gained a **Development sign-in**
panel: one fake identity per role, pressing one mints a session locally and routes to the shell exactly
as a real sign-in would.

This is the kind of convenience that ships to production by accident, so the guards are layered
deliberately:

- Every identity and the `IsEnabled` flag sit inside `#if DEBUG`. A Release build contains no test
  identities, and the empty list collapses the panel.
- The command **re-checks `IsEnabled`** rather than trusting that the panel was hidden, so a Release
  build cannot be talked into a fake session by invoking it directly.
- The access token is the sentinel `development-sign-in-not-issued-by-the-api` — not shaped like a JWT,
  rejected by the API, so a development session only ever reaches screens drawn from local data.
- A guard test reads the source file back **as text** and fails if an identity moves outside the guard.
  A test run is itself a Debug build, so the Release *behaviour* cannot be executed — only the guard
  that produces it can be checked. Verified by hand too: the fake addresses appear three times in the
  Debug assembly and zero times in the Release one.

The session gained `Role` and `IsSuperAdmin` as two separate fields on purpose. Super Admin is a
platform role held outside any club, so that identity carries a null club role — collapsing them into
one field would have re-created the confusion the previous week spent a day pulling apart.

## The app stopped looking like a form

The sign-in screen was a centred column of unstyled Fluent controls, and it was the first thing anyone
saw. It became a two-part composition: a dark brand panel with the app name, a headline and drawn pitch
markings, beside the sign-in form.

Chosen by width, never by platform — a `ContainerQuery` at 720px, matching the shell's own breakpoint.
Above it, the brand panel is a column docked left; below, the same material collapses into a header band
above the form.

A few decisions in the detail:

- The crest and the eye/eye-off icons are `StreamGeometry` resources drawn in the view, not image assets,
  so they recolour with the theme and stay crisp at any density.
- Pitch markings are anchored to the panel's own centre and edges rather than fixed coordinates, so they
  keep their proportions at any window height.
- The password reveal is **one masked box whose mask character changes** — Avalonia treats `'\0'` as "do
  not mask" — rather than a second box holding a clear-text copy of the password. Signing in re-masks, so
  a revealed password is not left on screen for whoever lands there next.
- The invite hint says accounts start with an invite from a club admin, which is the actual account model,
  rather than a "sign up" link to a flow that did not exist yet. (It did by Thursday. More below.)

Two days later that treatment reached the other nine screens — and the important part is that the system
was **extracted, not replicated**. The sign-in screen had declared its styles in its own `UserControl.Styles`
block, which is fine for one screen and wrong for nine: club branding overrides land as replacements for
the shared brush keys, so a style that hard-codes its values is a screen branding cannot reach. Every
control style and icon geometry moved into `Themes/Controls.axaml`, merged **after** `FluentTheme` because
a styles collection applies in order and these rules exist to beat Fluent's own. Fluent paints a button's
states on its inner `ContentPresenter`, not on the button, so anything that has to survive pointer-over is
set through the template part.

Then twenty `Opacity="0.7"` declarations across nine files became a `muted` class. Opacity dimmed the
element *and* whatever showed through it, so the same secondary line read differently on a row card than
on the page ground. Eight copies of a 28px semibold heading became `pageTitle`; ten text boxes took a
`field` class; read-only values got a class of their own so a value nobody can change stops looking like
one somebody forgot to finish.

Two guardrails came with it. A static test fails on any view that dims text with `Opacity`, declares a
literal hex colour, or sets a display font size — fix a failure by adding the missing class, not by
deleting the assertion. And a render-sheet test renders every screen to PNG at 1200px and 390px using
real Skia pixels, which earned its place immediately: it is how the row cards were caught leaving dead
space under top-aligned content.

## A gate that was never actually closed

`CupsViewModel` had an `IsClubAdmin` property, and it was reachable only from XAML, and only partly. The
row buttons bound `IsVisible="{Binding IsClubAdmin}"` inside a `DataTemplate` — which binds against the
row item, not the page view model, so it resolved to nothing. Compiled bindings are not enabled in this
project, so it failed **silently at runtime** rather than at build time, and the buttons showed for
everyone.

Correcting the binding would not have been enough either. A local `IsVisible` outranks the style setter,
so a per-button binding would have defeated the 500px container query that hides those buttons on narrow
layouts. And the narrow layout reaches edit and delete by tap and swipe, where there is no button to
hide at all — so a view-only gate leaves both routes wide open.

The gate now lives in two places on purpose: on the row-action *wrapper* in XAML, reaching the page view
model through `$parent[ItemsControl]` and leaving the container query in charge of the buttons themselves,
and in the view model commands, which is what closes the gesture routes. Super Admin is deliberately not
a way in — a null role reads as not-admin, with a test per view model pinning it.

## An account, a club, and somewhere to put them

The API had supported self-registration since its register handler landed, and any signed-in user could
create a club and become its first Admin. The front end could reach neither: the only route to an account
was an invite the app could not act on.

Registration landed with a page behind the link — display name, email, password, confirm, and an optional
invite code. One reveal toggle governs both password boxes, because a confirmation the user cannot read
confirms nothing. The brand chrome moved into two shared, data-context-free views so registration wears
the same material without a second copy of it.

Two contract details mattered. `RegisterAsync` returns a sign-in result, because the API signs a newly
created account straight in — so success ends where a sign-in ends rather than bouncing the user back to
retype credentials they just chose. And a blank invite box is sent as `null`, not `""`, because the API
reads a present-but-empty code as a supplied, wrong one.

Which immediately created a new problem: registering creates an account, not a membership, so a brand-new
user landed in a five-section app with nothing behind any section. The shell now builds **only** a Create
club page for such a session, makes it the sole entry in both the sidebar and the burger menu, and
**refuses the club sections in `Navigate` as well as hiding them** — hiding a button is not the same as
closing a route.

The page leads with the message rather than the form: a welcome naming the user, then what is missing and
why. With the rest of the navigation gone, "why is everything missing?" is the first question the screen
has to answer. The sport is picked from the master catalog rather than typed, because the API takes a sport
*id*, and the picker distinguishes "still loading" from "nothing to show".

Creating a club makes the creator its first Admin, so the shell raises an updated session and the whole
shell is rebuilt around it — which is what puts the rest of the navigation on screen.

## CI, containers, and a migration step that is not a startup step

Two build-and-test workflows landed, one per half of the repository, both on pull requests into `main`
and both path-filtered. There is deliberately no `push` trigger: every change reaches `main` through a
PR, so a push-triggered run would only duplicate the one the PR already had.

They name individual project files rather than the solution, because the solution also carries the iOS
and Android heads — iOS needs a macOS runner with a matching Xcode, and Android is not a supported target.
The UI suite runs in **Debug on purpose**: the development sign-in identities are behind `#if DEBUG` and
so are the tests covering them. The Release half of that guard is covered by the desktop head's Release
build in the same job. The browser head is **published**, not just built, because the WebAssembly SDK does
its bundling and native relinking at publish time — and the published output is exactly what App Service
will serve.

One note for later: because both workflows use path filters, a docs-only PR runs neither. If they are made
required status checks, a filtered-out run reports as skipped and can block the PR.

Alongside that, the front end finally learned where its API is. `ApiConfiguration.BaseUrl` resolves a
compiled-in constant first, then the process environment (desktop only), then a localhost default — and
the environment cannot be the only source, because an iOS process inherits none of the launching shell's
environment and the browser has no OS environment at all. An MSBuild target writes the constant from
`CLUBMONITOR_API_URL` at build time.

Two MSBuild details cost a build each and are now commented in place. An `Include` attribute is
glob-aware, so `public const string? Url` — containing a `?` — was read as a single-character wildcard
matching no file, and the line was dropped from the generated output with no warning. And
`IntermediateOutputPath` is not defined until the common targets run, so computing it in the project body
put the generated file in the project directory, where the default glob compiled it a second time.

The API got a container stack: SQL Server, the API, and — after a rethink — migrations as a service of
their own. The first version had the API migrate itself at startup behind a Development-only switch,
because the runtime image carries no SDK. That worked, but it put the schema step inside the API's startup
path: a failed migration surfaced as an API that would not start rather than a step with its own exit
code, and the shipped image *could* migrate a database, one environment variable away from doing so
somewhere it should not.

Now a one-shot `migrate` service runs an EF migrations bundle and exits, and the API depends on it with
`condition: service_completed_successfully`, so a failed migration stops the stack rather than handing out
an API on a half-built schema. The connection string is a YAML anchor shared by both, so the thing that
migrates and the thing that reads cannot drift onto different databases. The startup-migration code was
**deleted** rather than disabled — the guard is the absence of the code path, not an environment check on
it.

Both of those entries closed with "not verified", because Docker was not running when they were written.
It has since been exercised end to end: SQL reaches healthy, `migrate` runs and exits 0, then the API
starts; all eight migrations apply; a second run reports "No migrations were applied" and exits 0; twenty
tables exist in the database according to `sqlcmd`, not just according to the log. And the failure path —
the reason the service exists — exits 1 with a deliberately wrong password, holding the API back.

## Then it actually signed in

`ApiAuthenticationService` replaced the placeholder in every head. Sign-in and registration now post to
the real endpoints at the compiled-in base URL.

Both endpoints answer with the same shape, so both go through one response reader; the differences between
signing in and registering live in the API. The session is built from the answer rather than assumed — the
role stored is the one held in the club the token is **scoped to**, not the first club listed, because a
user in two clubs can hold a different role in each and the token only authorizes in one of them. An
account in no club gets a null role, which is what puts the shell on its create-club-only footing.

Nothing throws at a sign-in button. Every failure comes back as a result carrying a code: the API's own
stable error code when it answered, and four this client raises when it could not be asked —
`NetworkUnavailable`, `TooManyAttempts` for a 429 the rate limiter answers with no body,
`UnexpectedResponse` for a body that did not parse or a 200 missing something a session needs, and
`TwoFactorRequired`. A caller's own cancellation still propagates, because navigating away is not a
rejected credential.

Two-factor is **reported, not completed**. A correct password on a 2FA account yields a pending token and
no access token, and there is no screen to present the challenge on yet, so it surfaces as a readable error
rather than as a session that does not exist.

One quiet bug fell out of the wiring: the login view model mapped an error code the API has never sent, so
a wrong password would have shown the generic "something went wrong" rather than "incorrect credentials".

## And then Safari refused, for a reason that was not CORS

Clicking **Sign in** in the WebAssembly head failed in Safari with:

```
Fetch API cannot load http://localhost:5239/api/auth/login due to access control checks.
```

That reads like CORS, and it is not. The policy was verified against the running container from both
origins — preflight returns `204` with the right allow headers, and a real `POST` gets a normal JSON
response with the CORS headers attached.

The actual block is **mixed content**, client-side, before the request is ever sent. The browser head's
launch profile opened `https://localhost:7169` first, and the API endpoint compiled into the head is
`http://localhost:5239`. The Secure Contexts spec treats `http://localhost` as potentially trustworthy and
Chrome exempts it from mixed-content blocking; WebKit does not, and reports the refusal with its generic
"access control checks" wording. Nothing reaches Kestrel, so no server-side change could have fixed it.

The fix is to serve the browser head over **http** — `http://localhost:5235` now comes first in the launch
profile. That is a fix rather than a workaround: the API has no https listener in the local stack,
`http://localhost` remains a secure context in every browser so passkeys and the rest of the sign-in paths
still work there, and the alternative would have been https on both sides for no gain.

The week ended with 255 API tests and 280 headless UI tests passing, an app that creates real accounts
against a containerised API, and CI running both suites on every pull request.
