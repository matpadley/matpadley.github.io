---
title: "Killing a Process by Port on macOS"
date: 2026-08-21T12:00:00+01:00
draft: false
tags: ["macos", "dotnet", "dev-environment", "terminal"]
categories: ["articles"]
summary: "A quick reference for finding and killing whatever's squatting on a port on macOS — written after losing time trying to trace a rogue dotnet dev environment."
---

I'm writing this one down because I just lost ten minutes trying to figure out *which* of my running `dotnet` dev environments had a port locked, and I couldn't trace it back to a specific project or terminal window. Rather than dig through it properly, I just killed it by port and moved on — so here's the reference for next time.

## Find what's using the port

```bash
lsof -i :3000
```

This lists the process holding the port, including its PID:

```
COMMAND   PID   USER   FD   TYPE ...
dotnet   1234   mat    23u  IPv4 ...
```

## Kill it

Once you have the PID:

```bash
kill -9 1234
```

Or skip straight to it in one line:

```bash
kill -9 $(lsof -ti:3000)
```

An alternative using `fuser`:

```bash
sudo fuser -k 3000/tcp
```

## A note on `-9`

`kill -9` is a hard kill (`SIGKILL`) — it doesn't give the process a chance to clean up. For a stuck `dotnet watch` or dev server that's fine, but if you want a graceful shutdown first, try:

```bash
kill -15 1234
```

and only escalate to `-9` if it doesn't respond.

## The actual lesson

Killing by port is a workaround, not a fix. If it's happening repeatedly with `dotnet` projects specifically, it's worth checking `dotnet-trace` or just being more disciplined about stopping dev servers with `Ctrl+C` instead of closing terminal tabs — which is almost certainly how I ended up with an orphaned process in the first place.
