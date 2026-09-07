---
title: "Rider Hangs Loading Every Project? Check macOS's Privacy Permissions for External Volumes"
date: 2026-09-07
draft: false
tags: ["jetbrains-rider", "macos", "dotnet", "troubleshooting"]
summary: "Rider 2026.2 hung on 'Loading projects' for every solution on my Mac. The real cause wasn't a corrupted cache or a bad plugin — it was macOS silently revoking Rider's access to an external volume after an update."
---

## The symptom

Every solution I opened in JetBrains Rider 2026.2 on macOS got stuck on "Loading projects." Not one flaky project — *every* project, every time. New solution, old solution, didn't matter. The window would open, the loading spinner would sit there indefinitely, and nothing in the UI gave any clue why.

The usual playbook for this — invalidate caches, delete `~/Library/Caches/JetBrains/Rider2026.2`, restart in Safe Mode to rule out plugins, kill any orphaned `dotnet`/`MSBuild` processes — didn't fix it. Interestingly, VSCode had no trouble building the exact same projects, which turned out to be the clue that mattered most.

## Reading the log

Rider's own log (`Help → Show Log in Finder`, or `~/Library/Logs/JetBrains/Rider2026.2/idea.log`) told the real story once I actually looked at it. Buried in a wall of stack traces was this, repeated dozens of times:

```
SEVERE - Access to the path '/Users/me/.dotnet/sdk' is denied. Operation not permitted
WARN  - /Users/me/.dotnet: Operation not permitted
```

Rider's backend was trying — and failing — to enumerate my installed .NET SDKs, over and over, which is exactly the kind of thing that produces an infinite-looking hang on project load rather than a clean error.

## Following the symlink

`~/.dotnet` on my machine isn't a real directory — I keep my .NET SDK installs on an external APFS volume to save space on the internal disk, and symlink it in:

```bash
$ readlink ~/.dotnet
/Volumes/LLM/.dotnet
```

The volume was mounted correctly, APFS-formatted, and ordinary Unix permissions on the folder were completely fine. And critically, **VSCode built the same projects without any issue**, which ruled out a genuine filesystem permissions problem — if it were a plain "wrong owner" or "wrong chmod" situation, every tool would be blocked, not just one.

## The actual cause: macOS TCC, not Unix permissions

That combination — mounted, correctly permissioned, but one app blocked and another fine — is the signature of macOS's privacy protection system (TCC), not a filesystem issue at all. macOS treats access to removable and external volumes as its own protected category, gated per-application, separately from ordinary read/write permissions. Each app has to be individually granted access, and that grant is tied to the app's code signature.

Which means: **updating Rider changes its signature, and macOS can silently revoke a previously-granted permission on update** — without any obvious prompt or error telling you that's what happened. VSCode, not having been updated, kept its existing grant. Rider, freshly updated to 2026.2, lost it.

## The fix

1. Open **System Settings → Privacy & Security → Files and Folders**, and check whether Rider is listed with access to removable volumes. Also check **Full Disk Access** in the same pane.
2. If it's missing, stale, or you're not sure, force macOS to re-evaluate it rather than trusting the cached state:

   ```bash
   tccutil reset SystemPolicyAllFiles com.jetbrains.rider
   ```

   (Confirm the actual bundle ID first if you're unsure — `mdls -name kMDItemCFBundleIdentifier /Applications/Rider.app`.)
3. Fully quit Rider (`Cmd+Q`, not just close the window) and relaunch. Open a solution and watch for a permission prompt — it can appear behind the main window rather than in front of it.
4. If nothing prompts automatically, try toggling Rider's Full Disk Access off and back on in Settings — this sometimes forces macOS to re-ask instead of reusing a denied result.

Once that's granted, the `/Volumes/...` errors disappear from `idea.log` entirely, and solution loading goes back to normal.

## The takeaway

If an IDE or tool on macOS starts failing to read something on an external or network volume — especially right after an update, and especially when a *different* tool can read the exact same path fine — check Privacy & Security before you touch file permissions, caches, or plugins. Unix `ls -l` output looking perfectly normal doesn't rule out TCC silently blocking the process underneath.
