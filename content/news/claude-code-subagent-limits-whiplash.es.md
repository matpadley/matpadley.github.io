---
title: "Claude Code dio libertad a sus agentes, se la quitó y se la devolvió — en cuatro días"
date: 2026-07-27
draft: false
description: "Claude Code limitó los subagentes, desactivó el lanzamiento anidado y volvió a activarlo con profundidad 3 — un tira y afloja de cuatro días sobre cuánta autonomía puede comprar un solo mensaje."
tags:
  - claude-code
  - ai-coding
  - agents
---

Claude Code tuvo un tira y afloja curioso esta semana. Alrededor del 21 de julio limitó los subagentes a 20 y desactivó por completo el lanzamiento anidado — y para el 24 de julio ya lo había reactivado, con una profundidad por defecto de 3. En pocas palabras: la función que permite que un agente de IA contrate a *más* agentes de IA recibió unas barreras de seguridad, y unos días después se las aflojaron otra vez.

Lo que me gusta es lo honesto que resulta. Estás viendo, básicamente en tiempo real, cómo una empresa decide cuánta autonomía debería poder comprar un solo mensaje. Resulta que «dejar que los agentes lancen agentes sin fin» es una forma estupenda de derretir tu portátil, así que ahora hay tres límites distintos, cada uno con su propio ajuste.

Si manejas grandes flotas de agentes, échale un vistazo a `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` y a los nuevos topes antes de tu próxima tarea gigante.

**Fuentes**

- [Claude Code Put Guardrails on Its Own Agent Fleets](https://www.digitalapplied.com/blog/claude-code-subagent-depth-limits-budget-caps-2026)
- [Claude Code Changelog (July 2026)](https://www.gradually.ai/en/changelogs/claude-code/)
- [Claude Code changelog (oficial)](https://code.claude.com/docs/en/changelog)
