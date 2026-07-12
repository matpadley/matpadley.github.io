---
title: "Claude Code Just Stopped Trusting Itself by Default"
date: 2026-07-06
draft: false
description: "Claude Code quietly switched its default permission mode to Manual and killed auto-continue on AskUserQuestion prompts. Fresh installs now stop and ask a lot more often."
tags:
  - claude-code
  - anthropic
  - ai-coding-tools
---

Claude Code quietly flipped its default permission mode to "Manual" this week and turned off auto-continue on those `AskUserQuestion` pop-ups. Translation: fresh installs, and a lot of existing ones, will now stop and ask before doing things they used to just barrel through.

It's clearly a safety-first move after a summer of headlines about coding agents going rogue mid-task. If you've gotten used to Claude Code just running with it, expect a lot more "can I do this?" prompts starting now — you can still dial it back with `--permission-mode` if you liked living dangerously.

**Sources:**
- [Claude Code changelog, v2.1.200 (July 3, 2026)](https://code.claude.com/docs/en/changelog)
