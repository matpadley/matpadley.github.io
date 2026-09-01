---
title: "The Week Club Monitor Became a Repository"
date: 2026-08-22T09:00:00+01:00
draft: false
description: "Seven weeks of uncommitted work finally got a git history, the front end grew navigation and real screens, the OpenAPI pipeline was rebuilt twice, and the Super Admin role was cut in half after it turned out to be reading every club's data."
summary: "Seven weeks of uncommitted work finally got a git history, the front end grew navigation and real screens, the OpenAPI pipeline was rebuilt twice, and the Super Admin role was cut in half after it turned out to be reading every club's data."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - openapi
  - multi-tenancy
  - security
source:
  - 2026-08-19-0930-docs-uno-to-avalonia.md
  - 2026-08-19-1500-fix-browser-session-store-module-path.md
  - 2026-08-19-1630-add-shell-side-nav-burger-menu.md
  - 2026-08-20-1400-cups-header-layout.md
  - 2026-08-20-1500-cups-add-modal.md
  - 2026-08-20-1530-fix-cups-header-grid-not-stretching.md
  - 2026-08-20-1600-cups-list-seeded-from-swagger-model.md
  - 2026-08-20-1600-leagues-members-add-modal.md
  - 2026-08-20-1700-shared-theme-colour-palette.md
  - 2026-08-20-1730-add-swagger.md
  - 2026-08-20-1800-fix-swagger-codegen-path-traversal-false-positive.md
  - 2026-08-20-1900-openapi-typed-responses.md
  - 2026-08-20-1930-fix-swagger-codegen-additionalproperties-bug.md
  - 2026-08-20-1945-no-tests-for-generated-swagger-code.md
  - 2026-08-20-2015-fix-swagger-codegen-jsonconverter-errors.md
  - 2026-08-20-2030-serve-swagger-ui-in-development.md
  - 2026-08-20-2130-migrate-to-builtin-openapi.md
  - 2026-08-21-0830-code-review-and-commit-subagents.md
  - 2026-08-21-0900-initial-import.md
  - 2026-08-21-1030-members-delete-button-and-swipe.md
  - 2026-08-21-1030-screen-builder-subagent.md
  - 2026-08-21-1200-members-edit-button-and-tap.md
  - 2026-08-21-1330-member-edit-page.md
  - 2026-08-21-1500-cups-leagues-edit-and-delete.md
  - 2026-08-21-1630-user-groups-permission-bundles.md
  - 2026-08-21-1800-super-admin-tenancy-boundary.md
  - 2026-08-22-0900-club-self-service-sports-and-creation.md
---

Two quiet weeks, and then the busiest stretch the project has had. Between the 19th and the 22nd of
August, Club Monitor got its first commit, a navigation shell, three working list screens, an OpenAPI
pipeline that was built and then thrown away, and a security fix that took a role apart and put it
back together smaller.

## First, the documents were lying

The front end in this repository has been an **Avalonia 12.1.1** solution for a while. Every governing
document still described an **Uno Platform** single project — and that is not a cosmetic mismatch,
because the two frameworks disagree about almost every API a front-end change touches. Anyone reading
`CLAUDE.md` or the spec would have reached for `x:Uid`, `.resw` files, `AdaptiveTrigger` and
`ApplicationLanguages.PrimaryLanguageOverride`, none of which exist in Avalonia.

So the week opened with a documentation rewrite: `.resx` and `{x:Static}` instead of `.resw` and
`x:Uid`, `ContainerQuery` instead of `AdaptiveTrigger`, one shared library plus one project per head
instead of a single project, and `Avalonia.Headless.NUnit` named as the place UI assertions live.

The localization gotcha needed rewriting rather than translating. Avalonia has no platform
language-override API, so the app applies its own by setting `CultureInfo.DefaultThreadCurrentUICulture`
— after which the ambient culture reports the app's last choice, not the operating system's. The OS
locale has to be captured at startup *before* the override is applied, or it is gone.

Two older documents — the multilingual plan and an August security review — were deliberately **not**
rewritten. They are point-in-time records of work completed against the Uno front end, and turning
their ticked boxes into Avalonia claims would have falsified history. Each got a supersession banner
instead.

## A shell to navigate, and a bug hiding inside Avalonia's value precedence

The app had no post-login navigation at all: sign in, and you landed on a bare Home page with no way
to reach anything else. It now has a persistent Home/Members/Leagues/Standings shell — a sidebar on
wide layouts, a burger button opening a slide-out menu on narrow ones.

The split is made **by window width, never by platform**. A `ContainerQuery` at 720px decides, so a
phone browser gets the phone layout and a narrow desktop window does too.

Except that at first it decided nothing. The sidebar and top bar were written with `IsVisible="True"`
and `IsVisible="False"` as local XAML attributes, and Avalonia's value precedence puts a local value
above any style setter — so the container query's setters were silently no-ops and the layout never
switched at any width. The fix was to move both the default and the queried value into `Style`
setters. The headless test written for the narrow case is what caught it, failing with "Expected
False, but was True" until the local attributes came off.

That test needed somewhere to live, which is how `tests/ClubMonitor.UiTests` came to exist — the
project the rules had been referring to for weeks without anything having created it. It also
surfaced a small process-wide problem: `Avalonia.Headless.NUnit` builds a fresh `App` per test in the
same process, and DevTools' attachment state is process-wide, so the second test threw during
`App.Initialize()` until attachment was guarded behind a static flag.

A separate, sharper bug had already blocked the WebAssembly head entirely. `LocalStorageSessionStore`
imported `"./session-store.js"` and got a 404 on `_framework/session-store.js`, so the app never got
past `Program.Main`. The module specifier in `JSHost.ImportAsync` resolves relative to the *runtime's*
location — `_framework/`, where `dotnet.js` lives — not to the app root. The leading `../` is
load-bearing, and now carries a `<remarks>` note saying so, because it looks exactly like something a
tidy-up would remove.

## Three screens, and the same layout bug twice

Cups, Leagues and Members each gained a header with the title top-left and a "+" button top-right, an
Add dialog, and eventually per-row Edit and Delete.

The dialogs are **in-view overlays**, not `Window`s: the Browser and iOS heads run under
single-view lifetimes with no child-window support, so a `Window`-based dialog would work on desktop
only.

The "+" button spent a while glued to the title instead of sitting at the right edge, despite a
`Grid ColumnDefinitions="*,Auto"` that should have pushed it there. The cause was one attribute on an
ancestor: the content `StackPanel` had `HorizontalAlignment="Left"`, which makes a panel size to its
own content rather than to its `MaxWidth`. Avalonia's `Grid` gives star columns effectively zero width
when measuring its own `DesiredSize` — a star column is resolved during *arrange*, against whatever
final size the parent hands back — so a shrink-to-fit parent left the star column nothing to expand
into. Dropping the alignment fixed it without moving anything visually, because `MaxWidth` already
arranges a capped element as if left-aligned. There is a regression test asserting the button's
`Bounds.Right`, verified to fail at 266 against the old markup and pass at 640 against the fix.

Row actions then landed across all three lists, and the affordance is chosen by width again — this
time at **500px, not 720**. The lists sit in the shell's content area, which is 220px narrower than
the window wherever the sidebar shows; at 720 an ordinary desktop window would have fallen into the
touch-only layout, and `SwipeGestureRecognizer.IsMouseEnabled` is `false` by default, so a mouse user
would have had no way to delete anything at all.

Wide layouts get Edit and Delete buttons. Narrow ones get a **tap** to edit and a **left swipe** to
delete, with a hint line saying so. Three details about Avalonia's gesture recognizers turned out to
matter:

- `SwipeGestureEvent` and `TappedEvent` both **bubble**, so a single handler on the `ItemsControl`
  sees every row — which is what makes this workable, since a `DataTemplate` cannot carry an `x:Name`.
- The recognizer raises `SwipeGesture` **repeatedly** while the finger keeps moving, so the handler
  records `SwipeGestureEventArgs.Id` and ignores repeats of a gesture it already acted on.
- `Delta` is *start minus current*, so a positive X is a finger moving **left**. The code reads
  `SwipeDirection` instead, and a test pins the mapping so the sign does not read as a typo.

By the third copy, two pieces were extracted rather than triplicated: `IEditPage<TItem>`, which lets
`ShellViewModel.OpenEditPage` own open/save/cancel/unsubscribe once, and `RowGestures<TItem>`, which
took `MembersView.axaml.cs` from about seventy lines of handler down to a single `Attach` call and
gave Cups and Leagues the behaviour for free.

Editing also moved out of an overlay and into its own page — with the rule that **the list does not
navigate itself**. `MembersViewModel` raises `EditMemberRequested`; the shell owns the transition.
That keeps the page testable in isolation and keeps navigation knowledge in the one view model that
already has it. The edit page is deliberately not a nav destination: `SelectedNavKey` stays on
Members while it is open, so the sidebar highlight and the burger menu keep behaving.

Alongside that, five views' worth of near-duplicate colour dictionaries were consolidated into a
single `Themes/Theme.axaml` with semantic keys. That is not tidiness for its own sake — club branding
overrides are specified as replacements for exactly these app-level keys, so a view that declares its
own copy is a view branding cannot reach.

## A localization gate that had to be written twice

`LocalizationTests` was added to check that the English, French and Spanish `.resx` files stay in
parity. The first version passed against a deliberately broken French key, which is a good reason to
sabotage your own tests before trusting them: a resource lookup that misses a satellite **falls back
to the neutral resource**, so a missing French translation renders as English and no test going
through `ResourceManager` can see it.

The working version compares the `.resx` files as files, key set against key set. Re-run against the
same sabotage, it names both the untranslated key and the typo'd one.

## The OpenAPI pipeline, built and then replaced

This was the week's longest thread, and it ended somewhere other than where it started.

It began with Swashbuckle and a JWT bearer security scheme, gated to Development — a deployed
instance describing its own routes and DTOs is exactly the internal detail the anonymous `/health`
endpoint is deliberately kept free of.

Then a question about whether a handler needed a separate view model turned up something systemic:
the generated client was producing `public void ApiMembersGet()` for every single route, because no
endpoint declared any OpenAPI response metadata. Every Minimal API route across eight endpoint files
got `.WithName()`, `.WithTags()` and a `ProducesHandlerResult<T>()` extension declaring the success
schema plus a named `ErrorResponse` for 400/401/403/404/409. Tagging by feature also split the
generated output from one ~8,600-line class into one class per feature. The two browser-navigation
redirect routes were excluded from the description entirely — a generated client method calling them
would just follow the redirect.

Then the generator itself started failing, three times over:

1. **A path-traversal false positive.** The vendored swagger-codegen fork rejects any path containing
   `..`, and the script's own `-o ../club_monitor/...` argument tripped it. Fixed by canonicalizing
   the output directory where the CLI argument is stored — not by weakening the traversal check,
   which is legitimate protection against spec-derived filenames escaping during generation.
2. **`Dictionary<String, >` on 44 of 46 generated models.** Every record Swashbuckle reflects over
   gets `additionalProperties: false`, and the generator's C# template emits a `Dictionary` base type
   whenever `additionalProperties` is present at all — leaving the generic argument blank when there
   is no schema to fill it with. Since nothing in the codebase validates request bodies against their
   JSON schema, the flag was informational, and a schema transformer suppressing it cost nothing.
3. **A flood of unresolvable `JsonConverter` references.** The generated project was emitting a
   legacy `.NET Framework 4.5` + `packages.config` layout whose `HintPath` pointed at a folder
   nothing restores. Switching the generator to SDK-style output fixed it, along with a local
   `Directory.Packages.props` shadowing the repo-wide one — NuGet's central package management uses
   the *closest* file walking up and does not merge, so a subtree with inline versions needs its own.

A rule went into `CLAUDE.md` along the way: **never write tests for the generated client**. That tree
is regenerated wholesale on every run — it happened twice in one afternoon — so hand-written tests
against it re-assert generator output and get silently overwritten.

And then the whole Swashbuckle layer came out. ASP.NET Core 10 ships a first-party OpenAPI generator,
so `AddOpenApi`/`MapOpenApi` replaced `AddSwaggerGen`, Scalar replaced the Swagger UI as the
Development-only explorer, and the schema filter was ported to an `IOpenApiSchemaTransformer`. The
bearer scheme became a DI-activated document transformer that discovers the registered JWT scheme
through `IAuthenticationSchemeProvider`. `Microsoft.OpenApi` was pinned explicitly to 2.12.0, because
the version arriving transitively has a known high-severity stack-overflow advisory via circular
schema references.

The result is an OpenAPI 3.1.1 document with 48 schemas, a bearer scheme applied to every operation,
and a clean build with no vulnerable-package warning.

## The repository finally had a repository

On the morning of the 21st, `git log` still failed with an unborn branch and no HEAD. Everything
described above, and everything from the seven weeks before it, existed only on disk.

The initial import committed all 545 files as the first commit, after re-verifying that `.gitignore`
excluded build output and that no `.pfx`, `.env`, publish profile or `secrets.json` had been staged.
Because the repository's git-safety hook denies commits directly on `main` or `master` — and there was
no `main` yet to branch from — the import went onto a branch off the unborn HEAD.

Three project subagents were written around the same time, so that review and landing are separate,
explicitly scoped steps: a read-only `code-reviewer` carrying this repository's specific traps as a
checklist, a `change-committer` that applies findings and opens the PR without routing around the git
hooks, and a `screen-builder` that knows the eight places adding a screen touches — the ones that get
missed being the wiring, not the view.

## Then the authorization model was rebuilt, twice in two days

Membership had exactly two roles, `Standard` and `Admin`, so a club could say "everything" or
"nothing". A club wanting a treasurer had to hand over branding, competitions, members and
subscription along with it.

The first answer was user groups: seven permissions, grants in a child table rather than a bitmask so
they stay readable in migrations, and group membership pointing at `Membership` rather than `User` —
so a group only means something inside its own club, removing someone from a club takes their grants
with them, and "a user from club B in a group in club A" is unrepresentable.

The part worth recording is what *didn't* change. The request was for something that works with
passkeys and third-party auth as well as passwords, and **not one line of sign-in code changed**.
Every path — password, external provider, passkey, both two-factor completions, register, select-club
— funnels into a single factory where the token is minted, and that token carries subject, active
club, security stamp and purpose. No role. No permission. Authority already resolved server-side per
request, so groups inherited credential-agnosticism for free. The work was to *preserve* that
property, which a new test class now pins down three ways.

The next day it turned out something much more serious had been sitting in one line.

`TenantContext.BypassTenantFilter` was defined as `=> IsSuperAdmin`. The platform role and "read every
club's rows" were therefore the same property — so a Super Admin could read any club's roster,
competitions, fixtures and results. That is not what the role is for. A Super Admin manages the
commercial side of clubs hosted on a multi-tenant domain: subscription, domain, features. If a club is
on the main domain, the Super Admin should see nothing but its **name**.

The two properties are now separate. `IsSuperAdmin` is the platform role, granting configuration reach
over clubs on a tenant domain and no data reach anywhere. `BypassTenantFilter` drops every tenant
filter and is set **only** by maintenance with no user behind it — seeding, migrations, tests. Nothing
reachable from an HTTP request sets it.

Four further places were each independently granting Super Admins reach and had to follow: the
permission guard and the competition admin guard both stopped returning true for the role, seed data
gained a main-domain club for the privacy tests to aim at, and the competition query filter gained an
explicit `IsSuperAdmin && ClubId == null` clause.

That last one surfaced a latent bug worth naming. Leaving platform-wide competitions to be matched by
`c.ClubId == tenant.ClubId` relies on null matching null — which happens to hold under the InMemory
provider the tests use, and never in SQL, where `NULL = NULL` is unknown. A provider-dependent
correctness bug, found only because the surrounding code was being rewritten.

A new DTO makes the leak unrepresentable rather than merely checked: every configuration field is
nullable and all of them are null for a main-domain club, and the type carries members, leagues, cups
and standings in no form at all, for any club. Platform-wide competitions now refuse main-domain clubs
outright, since such a competition necessarily exposes a club's entered players.

## Which left two questions, answered on Saturday

If the platform cannot see a club's members, why is it deciding which sports the club plays? And why
can a club not exist without the platform creating it?

Both moved to the club. Sport assignment became a club permission — a real one this time, where it had
previously been removed precisely *because* it was Super Admin-only, making it a permission a club
could grant that would still be refused. The catalog stays platform-owned: a club chooses which sports
it plays, it cannot invent one the platform has never heard of.

Club creation became available to any signed-in user, who becomes the club's first Admin, on the main
domain — which resolves the wrinkle where a Super Admin created a club and then immediately could not
configure it.

The handler that assigns a sport needed a check it never used to: it takes a club id in the request
body, which was harmless when only a Super Admin could call it, and is a cross-tenant hole the moment
the caller holds a club-scoped permission. The body's club is now checked against the token's, with a
test named for exactly that. And `CreateClubRequest` lost its `InitialAdminUserId` field — letting a
caller name the first Admin would let anyone make a stranger the Admin of a club they never asked for,
and a first Admin can invite and promote. Removing the field makes it unrepresentable rather than
merely validated.

The week ended at 268 API tests and 181 front-end tests, all passing.
