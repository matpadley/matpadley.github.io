---
title: "Set Your NuGet Cache Free: Moving .nuget and .packages to Another Volume"
date: 2026-08-18
draft: false
description: "Your .nuget cache is quietly eating your Mac's drive. Move it to an external SSD, leave a symlink behind, and get the space back without losing a single cached package."
tags:
  - dotnet
  - nuget
  - macos
  - developer-tools
---

If you've ever glanced at your Mac's storage breakdown and wondered why "System Data" looks like it's trying to take over the whole drive, there's a decent chance your `.nuget` cache and `.packages` folder are quietly gorging themselves in the background. Every restore, every project, every "let's just try this package real quick" adds a little more to the pile — and it never seems to shrink on its own.

The good news: you don't have to live with it, and you don't have to give up your global package cache to reclaim the space. You just have to relocate it — and leave a symlink behind to keep .NET none the wiser.

## Why this is worth doing

The `~/.nuget/packages` folder (and often `~/.packages` too, depending on your setup) accumulates *every version of every package* you've ever restored, across *every project* you've ever worked on. Multiply that by a few years of C# development, a handful of solutions with slightly different dependency graphs, and the odd overzealous `dotnet restore`, and it's not unusual to find tens of gigabytes sitting there — quietly, invisibly, forever.

Moving it off your main internal drive gives you that space back instantly, without deleting a single cached package or touching your build performance.

## The move

**1. Shut down anything using it.** Close your IDE (Rider, VS Code, whatever you're driving) so nothing's mid-restore while you do this.

**2. Move the folder to its new home:**
```bash
mv ~/.nuget/packages /Volumes/YourSSD/nuget-packages
```

**3. Leave a symlink where .NET expects to find it:**
```bash
ln -s /Volumes/YourSSD/nuget-packages ~/.nuget/packages
```

Repeat the same two steps for `~/.packages` if you use it. .NET tooling reads and writes to `~/.nuget/packages` by path — it has no idea (and no reason to care) that the actual files now live somewhere else entirely.

**4. Verify it worked:**
```bash
dotnet restore
```
If it restores cleanly and `ls -la ~/.nuget` shows the little arrow next to `packages`, you're done.

## But *where* should that "other volume" be?

Here's the bit that's easy to get wrong: technically, any mounted volume works — an external HDD, a network share, a dusty USB stick you found in a drawer. But not all of them work *well*.

Put it on an SSD. Ideally an external one connected over USB-C/Thunderbolt, or better still, an internal secondary SSD if your setup allows it.

Here's why that matters more than it might seem: NuGet restores involve *thousands* of small file reads, not a handful of big sequential ones. That's exactly the workload spinning hard drives are worst at, and exactly the workload SSDs eat for breakfast. Put your package cache on a mechanical drive and you'll trade disk space for restore times — every `dotnet restore`, every IDE re-index, every CI-adjacent local build will feel like it's wading through treacle.

An SSD keeps restores fast, keeps your IDE from stalling on file lookups, and still gives your main drive its space back. Genuinely the best of both worlds — cheap external NVMe drives make this an easy win these days.

## One small gotcha

If you ever unmount or disconnect that external SSD, `dotnet restore` will fail (the symlink will point at nothing, understandably confused). Not a big deal if it's a permanent fixture, but worth remembering before you unplug it and immediately try to build something.

And that's it — same trick as moving any macOS folder with a symlink, just aimed squarely at the parts of your `.NET` toolchain that are hoarding the most space. Your internal drive will thank you.
