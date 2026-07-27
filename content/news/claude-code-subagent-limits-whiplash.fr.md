---
title: "Claude Code a donné la liberté à ses agents, l'a reprise, puis rendue — en quatre jours"
date: 2026-07-27
draft: false
description: "Claude Code a plafonné les sous-agents, désactivé les lancements imbriqués, puis les a réactivés à une profondeur de 3 — un bras de fer de quatre jours sur la dose d'autonomie qu'un seul message peut acheter."
tags:
  - claude-code
  - ai-coding
  - agents
---

Claude Code a connu un drôle de bras de fer cette semaine. Vers le 21 juillet, l'outil a plafonné les sous-agents à 20 et a carrément coupé les lancements imbriqués — puis dès le 24 juillet, l'imbrication est revenue, avec une profondeur par défaut de 3. En clair : la fonction qui permet à un agent IA d'embaucher *encore plus* d'agents IA s'est vue poser des garde-fous, avant qu'on les desserre quelques jours plus tard.

Ce que j'aime, c'est l'honnêteté de la chose. On regarde en gros une entreprise déterminer, en direct, la dose d'autonomie qu'un seul message devrait pouvoir acheter. Il s'avère que « laisser les agents lancer des agents à l'infini » est un excellent moyen de faire fondre son portable, donc il y a maintenant trois limites distinctes, chacune avec son propre réglage.

Si vous faites tourner de grosses flottes d'agents, jetez un œil à `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` et aux nouveaux plafonds avant votre prochaine tâche géante.

**Sources**

- [Claude Code Put Guardrails on Its Own Agent Fleets](https://www.digitalapplied.com/blog/claude-code-subagent-depth-limits-budget-caps-2026)
- [Claude Code Changelog (July 2026)](https://www.gradually.ai/en/changelogs/claude-code/)
- [Claude Code changelog (officiel)](https://code.claude.com/docs/en/changelog)
