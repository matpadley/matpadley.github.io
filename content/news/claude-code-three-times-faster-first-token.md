---
title: "Claude Code just stopped making you wait around"
date: 2026-10-19
draft: false
description: "Anthropic says Claude Code's wait before the first word of a reply dropped from about 4 seconds to 1.3 — and it wasn't a new model, just plumbing."
tags:
  - claude-code
  - anthropic
  - performance
---

Anthropic says the pause before Claude Code starts replying has dropped by about 3x — from roughly 4 seconds down to 1.3 at the slow end (p90, if you like stats). And here's the fun bit: it's not a smarter model, it's plumbing. Requests now get squished (gzip) before they're sent, and cloud sessions start warming up the moment you start typing.

Cloud sessions improved too, from about 17 seconds to 6. Worth remembering these are Anthropic's own numbers, but it matches that "huh, it feels snappier" vibe a lot of people have been mentioning.

Best part? You don't have to do anything. If you ever want the old behaviour, there's an environment variable to switch the squishing off.

**Sources**

- [Claude Code waits 3x less for the first token (AICoder)](https://aicoder.com/news/news-20261017-claude-code-3x-faster-first-token-gzip-cloud-prewarm)
- [AI Changelog Week 42 (Neomanex)](https://neomanex.com/changelog/2026-w42)
