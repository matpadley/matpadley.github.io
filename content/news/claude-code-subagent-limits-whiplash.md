---
title: "Claude Code gave its agents freedom, took it away, then gave it back — in four days"
date: 2026-07-27
draft: false
description: "Claude Code capped subagents, killed nested spawning, then re-enabled it at depth 3 — a four-day tug-of-war over how much autonomy one message should buy."
tags:
  - claude-code
  - ai-coding
  - agents
---

Claude Code had a funny little tug-of-war this week. Around July 21 it capped subagents at 20 and switched off nested spawning entirely — then by July 24 it flipped nesting back on at a default depth of 3. In plain terms: the feature that lets an AI agent hire *more* AI agents got guardrails bolted on, then loosened again a few days later.

What I like is how honest it is. You're basically watching a company work out, live, how much autonomy a single message should be allowed to buy. Turns out "let agents spawn agents forever" is a great way to melt your laptop, so now there are three separate limits, each with its own knob.

If you run big agent fleets, peek at `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` and the new caps before your next giant task.

**Sources**

- [Claude Code Put Guardrails on Its Own Agent Fleets](https://www.digitalapplied.com/blog/claude-code-subagent-depth-limits-budget-caps-2026)
- [Claude Code Changelog (July 2026)](https://www.gradually.ai/en/changelogs/claude-code/)
- [Claude Code changelog (official)](https://code.claude.com/docs/en/changelog)
