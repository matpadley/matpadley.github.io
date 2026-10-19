---
title: "Codex CLI quietly leaves a helper running after you close it"
date: 2026-10-19
draft: false
description: "Since version 0.157.0, OpenAI's Codex CLI starts a background process that keeps running — and people on Hacker News noticed."
tags:
  - codex
  - openai
  - cli
---

Here's one that surprised a few people: since version 0.157.0, opening Codex CLI also starts a background helper that keeps running after you close the window. It checks for updates every hour and keeps its own copy of the app tucked away in your home folder — one person measured about 374 MB, and some commenters say old copies have piled up into many gigabytes.

OpenAI calls it a deliberate default rather than a bug, but a request to make it opt-in hit the Hacker News front page this week. It's not scary, just a bit "wait, what's that doing there?"

If you'd rather not have it, `codex features disable daemon_auto_start` turns off the auto-start for new sessions. Worth a peek at what's running on your machine, honestly.

**Sources**

- [Codex CLI Background Daemon: How to Turn It Off (Developers Digest)](https://www.developersdigest.tech/blog/codex-cli-background-daemon-auto-start-disable-2026)
- [Daemon Auto-Start Is Now the Stable Default in Codex CLI v0.157.0](https://codex.danielvaughan.com/2026/09/25/codex-cli-daemon-auto-start-stable-default-v0157/)
