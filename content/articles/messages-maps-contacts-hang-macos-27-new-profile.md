---
title: "Messages, Maps and Contacts Won't Launch on macOS 27? The Fix Was a New Profile"
description: "After moving from the macOS 27 beta to the release build, Messages hung, Maps and Contacts wouldn't start, and System Settings crashed. The cause was my user profile, not macOS — and the fix was creating a new one."
date: 2026-10-07
tags:
  - Troubleshooting
---

## The symptom

After moving from the macOS 27 beta to the release build (27.0.1), three of Apple's own apps stopped working for me. Messages bounced in the Dock forever and showed up as “Not Responding” in Force Quit. Maps and Contacts wouldn't start at all. Clicking Messages in System Settings crashed System Settings outright, and trying to sign out of iCloud left the dialog spinning on “Signing out” indefinitely.

Everything had been fine on the beta, right up until I installed the proper release. Once I did manage to sign out of iCloud and back in again, it made no difference.

## Is it macOS, or is it me?

The most useful test took two minutes: **create a new user account and try the apps there.** Messages, Maps and Contacts all worked perfectly in the new account, on the same Mac, on the same build of macOS.

That one result changed the whole investigation. The operating system was fine. Something in *my* profile's data was broken.

## Narrowing it down

Contacts looked like the obvious suspect, since Messages and Maps both lean on it, so I moved the `AddressBook` folder out of `~/Library/Application Support/`. Contacts simply rebuilt a fresh one, and nothing changed.

Moving the preference files for the affected apps was what made progress. Moving these aside, then restarting, got Contacts and Maps launching again:

```text
~/Library/Preferences/com.apple.AddressBook*
~/Library/Preferences/com.apple.Maps*
~/Library/Preferences/com.apple.systempreferences*
```

Messages was still hanging.

## Reading the sample

For Messages, I opened Activity Monitor while it was bouncing, selected it and chose **Sample Process** from the gear menu. The app wasn't crashing — it was *waiting*. The main thread was stuck during launch inside `IMCore`, blocked on a dispatch queue, and that queue was itself blocked on a synchronous call to a background daemon:

```text
com.apple.IMCore.DaemonConnectionSetup
  -[NSXPCConnection _sendInvocation:...]
    __NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__
```

A second thread was in the same state, waiting on a reply from a different service:

```text
com.apple.telephonyutilities.callcapabilitiesxpcclient
  -[TUCallCapabilitiesXPCClient _retrieveState]
```

So Messages was waiting forever for background services that never answered. These daemons run per user and keep their own state, which fits with the new account working.

## What didn't work

I restarted the likely daemons, which macOS relaunches automatically:

```bash
killall imagent identityservicesd callservicesd
```

Then I moved the iMessage and identity service state aside — the `com.apple.imagent*`, `com.apple.madrid*`, `com.apple.imservice*`, `com.apple.identityservices*` and `com.apple.TelephonyUtilities*` preference files, plus `~/Library/IdentityServices/`. None of it fixed Messages.

I also considered reinstalling macOS, but a reinstall from Recovery leaves your user data alone, including everything in `~/Library`. The new account had already shown the system files were fine, so it would most likely have brought me straight back to the same hang.

## The fix: I created a new profile

At that point I stopped guessing. My best guess is that something left over from the beta in my old profile's data confused the release build, and I wasn't going to find it by trial and error. So I **re-created a new profile**:

1. Back up first: a Time Machine run, plus a copy of `~/Library/Messages`, which holds your message history if you don't sync it through iCloud.
2. Create a new user, sign into iCloud, and turn on Messages, Contacts and the rest.
3. Copy files across — Documents, Desktop, Downloads, Pictures — and deliberately leave `Library` behind, because that's where the problem lives.

Messages, Maps, Contacts and System Settings all work in the new profile.

## The takeaway

If several of Apple's built-in apps fail at once after an upgrade, especially from a beta to a release, **test with a brand new user account before you touch anything else.** It takes two minutes and tells you whether you're fighting macOS or your own profile. If the new account works, skip the reinstall and the endless preference surgery.

In my case it was my profile, and **I re-created a new profile to fix it.**
