---
title: "No Hardcoded Strings: Localizing an Uno Platform Front End"
date: 2026-08-01T09:00:00+01:00
draft: false
description: "A missing translation falls back silently to English, so a green build proves nothing. The guarantees had to be lints — and testing a UI that renders entirely into one canvas meant asserting on stored culture and pixels rather than text."
summary: "A missing translation falls back silently to English, so a green build proves nothing. The guarantees had to be lints — and testing a UI that renders entirely into one canvas meant asserting on stored culture and pixels rather than text."
tags:
  - club-monitor
  - uno-platform
  - localization
  - xaml
  - playwright
  - testing
  - ci
source:
  - "2026-07-31-1700-multilingual-phase-4-frontend-groundwork.md"
  - "2026-07-31-1800-multilingual-phase-5-pages-off-hardcoded-strings.md"
  - "2026-07-31-1900-multilingual-phase-6-tests-and-ci.md"
  - "2026-08-01-0900-multilingual-phase-7-documentation.md"
---

With the API's failure contract made machine-readable, the interesting half of going multilingual moved to the Uno Platform front end. That work had three parts: deciding what language the app should be in, getting every user-facing string out of the markup, and finding something that could actually catch a missing translation.

## Deciding what language to show

The negotiation order is short but every clause earns its place:

1. An explicit on-device override, if one exists.
2. Otherwise the OS locale, clamped to a supported culture.
3. Otherwise English.

On sign-in, a device with no override yet adopts the account's stored `PreferredLanguage` — but an existing override is never silently replaced. The in-app picker writes the override immediately and best-effort syncs the account.

The clamp matters more than it looks. A device set to `fr-CA` or `es-419` should get French or Spanish, not fall all the way to English because the exact regional tag isn't in the supported set. `SupportedCultures.Clamp` reduces a regional tag to its language before giving up.

Two implementation details are easy to get wrong. **Culture is applied before the first window exists** — `CultureService.Initialize()` is the first line of `OnLaunched` — and **changing language rebuilds the app root**, because resource lookups resolve as visuals are built. Setting `PrimaryLanguageOverride` alone leaves everything already on screen in the old language. The shell already rebuilt the root on a theme swap and remembered the current page across it, so a language change reuses exactly that path and the user stays where they were.

One thing deliberately not built: a prompt at sign-in asking which wins when the device override and the account language disagree. The spec says the device override always wins and sign-in never silently replaces it. Mid-sign-in is a poor place to ask a question the spec doesn't need answered.

## Getting the strings out of the markup

The resource files went from a single entry to 142 per culture. Most of that is the mechanical part — `x:Uid` on every control, across the login screen, dashboard, members, leagues, standings and player profile.

Some of it isn't mechanical at all, and those cases are where localization actually lives:

- **Text chosen at runtime.** The two-factor prompts, passkey failures, the time-of-day greeting, a standings title built from a format string — `x:Uid` cannot express any of these. They go through a `LocalizedStrings` lookup instead. The login screen's dynamic prompts lived entirely in code-behind, which the "no literals in XAML" rule says nothing about.
- **Enum values arriving from the API.** Roles, statuses, competition types, visibility and match status come over the wire as English enum names — `Admin`, `Active`, `League`, `Public`, `Scheduled`. They are data, not literals, so a markup sweep never touches them. Left alone they keep the Members and Leagues lists visibly English on an otherwise French screen. `EnumLabels` translates them, and an unrecognised value renders as-is so a new enum member the app hasn't been taught degrades to English rather than to a blank tag.
- **Text between element tags.** The fixture line was two inline `Run` elements with a literal ` vs ` between them. `x:Uid` cannot reach a bare text node — and hardcoding the separator also hardcodes the word order, which belongs to the translator. `Match_Fixture` is `{0} vs {1}`, so a language that orders it differently can.
- **Abbreviated column headers.** `P/W/D/L` on the standings table is not cosmetic: it becomes `J/G/N/P` in French and `PJ/G/E/P` in Spanish.

The language picker lists English / Français / Español as endonyms — each in its own language, in every culture, as language pickers conventionally are. The resource comments say so explicitly, because identical values across three cultures otherwise look exactly like a missing translation.

## The only thing that catches a missing translation

A resource absent from one culture falls back silently to the default language at runtime. The app looks perfectly healthy while showing English to a French user. A green build proves nothing.

So the guarantees are lints, and they run as ordinary unit tests that read the `.resw` files straight from the repository — no browser, no Uno workload, no running app:

- Every culture defines exactly the same keys, and none has a blank value.
- Every `ErrorCode` member has a message in every culture. The test project references the API, so it reads the enum itself rather than a copied list of names.
- No `ErrorCode_*` entry refers to a code that no longer exists, and a generic `Error_Unknown` fallback exists everywhere.
- No literal `Text`/`Content`/`PlaceholderText`/`Header` attribute in any app XAML, and no literal text between element tags.
- **Every `x:Uid` is backed by a resource entry.** This is the one that matters most: a typo'd or unbacked `x:Uid` does not fail the build, the control just renders blank at runtime.
- No `.Text = "literal"` in page code-behind.

Each lint was verified by introducing the violation it targets and confirming the suite went red, then reverting — a lint that scans the wrong directory passes just as quietly as a clean codebase does.

These were initially reachable only from the end-to-end CI job, which needs SQL Server, the API and the web head. They now also run in the fast build-and-test job via `--filter TestCategory=Static`: nine tests in about a tenth of a second, no browser launched, so a missing translation or a hardcoded string fails a pull request immediately.

## Testing a UI you cannot query

The plan had asked for the existing Playwright fixtures to stop asserting on literal English text and switch to `AutomationProperties.AutomationId`. Neither half applied.

They never asserted on English text in the first place — the login tests assert on which API paths the app calls and on HTTP status; the smoke tests assert on the canvas element, HTTP status and the absence of page errors. Both were already language-independent, so translating the app broke nothing.

And switching to `AutomationId` is not possible. The Uno WebAssembly head draws with Skia into a single `<canvas>`. Probing a running app confirmed the entire document is `DIV/CANVAS/INPUT` with empty `innerText` — no rendered string and no `AutomationId` is reachable from Playwright at all. Rather than invent work, both fixtures now record the constraint in their doc comments so the next person doesn't spend an afternoon rediscovering it. The `AutomationId`s stay in the XAML; they serve native and desktop automation, just not the browser head.

What *is* observable from outside the canvas turns out to be enough. The end-to-end language tests drive the real browser locale — `en-US`, `fr-FR`, `es-ES`, plus `de-DE` to prove an unsupported language falls back and `fr-CA` to prove a regional tag clamps — and assert on two things:

1. **The culture the app resolved.** Uno persists `ApplicationLanguages.PrimaryLanguageOverride` to local storage, so the test reads the resolved language back by name rather than inferring it.
2. **The rendered pixels**, which prove the resolved culture actually reached the screen instead of merely being computed and stored.

Two deliberate choices in the pixel comparison. **No golden images** — renders are compared against each other within a single run, because a checked-in reference would break on every font, theme or layout change while never telling us more than "these two differ". And **a determinism control**: the test renders English twice and asserts the bytes match before asserting French differs. Without it, "the pixels differ" would be true of any two renders, and a non-deterministic renderer would give a permanently green, meaningless test.

Rather than sleeping a fixed interval before screenshotting, the helper polls until two consecutive captures match. A fixed sleep has to be long enough for the slowest CI runner on its worst day and is still a guess; polling took the suite from about two minutes to 39 seconds.

## Auditing the documentation against the code

The spec and `CLAUDE.md` were written before any of this existed, so the last step was checking each claim against the code rather than re-reading them for tone. It found real drift:

- **Error codes that do not exist.** The spec gave `MustBeSignedInToJoinClub` and `InvalidTwoFactorCode` as examples. The real members are `NotSignedIn` and `InvalidVerificationCode`. Anyone coding a client against the documented names would have matched on strings the API never sends.
- **A wrong HTTP verb** — the language endpoint was documented as PATCH; it is `PUT /api/auth/language`.
- **A rule that was true but incomplete.** Both documents said every front-end string is a `.resw` entry "referenced via `x:Uid`" and that none is "set from code-behind" — read literally, that forbids the very mechanism `LocalizedStrings` and `EnumLabels` had to use. All three routes are now described, with `x:Uid` as the default.
- **Behaviour documented that does not exist.** Both listed invitation emails as using the recipient's language, in the present tense. There is no invitation email; that handler creates a pending membership and sends nothing.

The audit also surfaced a trap worth naming. The culture list is stated in three places that cannot reference each other: the API constant, the app constant, and the `Strings/` folders. The resource tests hardcoded a **fourth** copy. Adding a language to the constants and shipping a new `.resw` would have left that file entirely unchecked — no key comparison, no blank-value check, no error-code coverage — precisely when those checks matter most, and silently, because everything would still pass.

Rather than document the trap, it's gone. The tests now discover the `Strings/` folders, and a further test cross-checks that set against the API's `SupportedCultures.All`. A constant without resources, or resources without a constant, fails with a message naming everything that needs updating. Verified by adding a stray `Strings/de` folder and confirming the failure. As a bonus, the "adding a language" checklist in the README no longer needs an "and update the tests" line — the tests follow the resources.
