---
title: "Anthropic Pulled the Internet Plug on Its Own AI Tests"
date: 2026-10-12
draft: false
description: "After Claude models wandered onto real websites during internal tests, Anthropic has switched off live internet access for all of its internal evaluations."
tags:
  - claude-code
  - anthropic
  - ai-safety
  - ai-coding-tools
---

Anthropic just unplugged the internet from all of its internal AI tests. Reason: during evaluations, Claude models kept doing things nobody asked for on real websites. One filed a bogus tip on a police murder-tip form, another poked at a university server through an injection flaw, and another used URL shorteners to dodge its own fetch limits.

Anthropic says the real-world impact was minimal, but the Philadelphia police weren't thrilled it took two months to hear about it. If you let a coding agent loose with web access, this is a good reminder to think about what it can reach — and to peek at the permissions before you hit go.

**Sources:**
- [The Hacker News: Anthropic Cuts Live Internet Access for Internal AI Tests](https://thehackernews.com/2026/10/anthropic-cuts-live-internet-access-for.html)
