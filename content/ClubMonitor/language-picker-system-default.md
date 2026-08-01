---
title: "The Language Picker That Could Not Undo Itself"
date: 2026-08-01T10:30:00+01:00
draft: false
description: "Adding a \"System default\" option should have taken fifteen minutes. It was a no-op in exactly the case it exists for, because Uno persists the language override and applies it before any app code runs — so asking the ambient culture what the device is set to returns the app's own previous choice."
summary: "Adding a \"System default\" option should have taken fifteen minutes. It was a no-op in exactly the case it exists for, because Uno persists the language override and applies it before any app code runs — so asking the ambient culture what the device is set to returns the app's own previous choice."
tags:
  - club-monitor
  - uno-platform
  - localization
  - debugging
  - webassembly
  - testing
source: "2026-08-01-1030-language-picker-system-default.md"
---

The language picker shipped with three entries — English, Français, Español — and no way to stop following an explicit choice. An override could be changed but never undone. Closing that gap looked like a fifteen-minute job: add a **System default** item, clear the stored override, re-render. It didn't work, and the reason had been sitting in the codebase since the picker was first built.

## What "System default" has to mean

Clearing the override is only half of it. The account still needs a concrete language, because emails and text messages are composed on a server that cannot see this device's OS locale. The honest answer is the language the app is now showing, so `FollowSystem()` clears the override, re-renders, and syncs the resulting effective culture to the account.

The picker also has to *show* the right thing. When no override is stored it shows **System default** as selected, rather than highlighting whichever language happened to resolve — highlighting "Español" would claim a choice the user never made.

The new entry is, incidentally, the only item in that list that gets translated. The language names beside it are endonyms and stay identical in every culture; "System default" is a phrase, so it becomes "Langue du système" and "Idioma del sistema".

## Why it didn't work

**Uno persists `ApplicationLanguages.PrimaryLanguageOverride` across restarts and applies it before any application code runs.**

The culture service was answering "what language is this device set to?" by reading `CultureInfo.CurrentUICulture`. From the second launch onward, that reports the language *the app itself chose last time*. The original code already guarded against this within a session, by snapshotting the value early in startup — but a snapshot doesn't survive a restart, because the contamination happens before there is anything to snapshot.

Follow it through on a German device. Choose Spanish. Restart. Press System default. The override is cleared, the app asks "what is the device set to?", is told "Spanish", and stays in Spanish.

The feature was a no-op in precisely the case it exists for.

`ReadDeviceLanguage()` now derives the device language from `ApplicationLanguages.Languages` with the active override removed. Uno pushes the override onto the front of the device's own list, so dropping it leaves the truth underneath. `GlobalizationPreferences.Languages` is the API WinUI documents for exactly this and would have been the obvious fix — but Uno's WebAssembly head throws `NotImplementedException` from it, confirmed by instrumenting the running app.

## How it was found

Not by reading the code.

The Settings picker lives inside the Skia canvas and cannot be clicked from Playwright, so the lifecycle was driven through the stored override directly: load the app three times against a `de-DE` browser context and watch what it resolves to. The third load returned Spanish where English was expected. Instrumenting the culture service and capturing the browser console produced the actual values — `appLangs=[es,de-DE]`, `currentUI=es`, and `GlobalizationPreferences` throwing — which identified both the cause and the fix.

That's the whole diagnosis, and none of it was visible from the source. A bug that only appears on the second launch is invisible to a first run, and this one is invisible to code review as well: reading `CurrentUICulture` to find the device language looks entirely reasonable until you know that Uno has already overwritten it.

## What now guards it

Two tests, doing different jobs.

`An_explicit_choice_sticks_across_restarts_and_System_default_undoes_it` walks the whole lifecycle on a German — that is, unsupported — device: starts in English with no override stored, keeps Spanish across a restart once chosen, and returns to English once the override is cleared. It was verified against the old logic, where reverting `ReadDeviceLanguage` reproduces the failure as "Clearing the override left the app on the language that was cleared."

The test drives the stored override rather than the picker itself, since the control is inside the canvas — and says so in its own comments. What it really covers is the restart behaviour, which is where this went wrong.

The second is static: `The_language_picker_offers_every_supported_culture_and_the_system_default` pins the picker's `ComboBoxItem` tags to `SupportedCultures.All` plus `system`. Adding a language could otherwise ship a culture that is fully translated but unreachable from Settings, which nothing else would have caught — wiring up the picker is a manual step in the README.

The "never read `CurrentUICulture` to find out what the *device* is set to" trap is now written into all three project documents. It is invisible on a first run and only bites after a restart, which is exactly the kind of thing that gets rediscovered the expensive way.
