---
title: "Claude Code arrête enfin de vous faire patienter"
date: 2026-10-19
draft: false
description: "Anthropic affirme que l'attente avant le premier mot de réponse de Claude Code est passée d'environ 4 secondes à 1,3 — sans nouveau modèle, juste de la plomberie."
tags:
  - claude-code
  - anthropic
  - performance
---

Anthropic dit que la pause avant que Claude Code commence à répondre a été divisée par 3 environ — de 4 secondes à 1,3 dans les cas les plus lents (le fameux p90, pour les amateurs de stats). Et le plus drôle, c'est que ce n'est pas un modèle plus malin : c'est de la plomberie. Les requêtes sont maintenant compressées (gzip) avant l'envoi, et les sessions cloud commencent à se réveiller dès que vous tapez vos premières lettres.

Les sessions cloud ont gagné aussi, de 17 secondes à 6 environ. Gardez en tête que ce sont les chiffres d'Anthropic eux-mêmes, mais ça colle avec ce petit « tiens, ça me paraît plus rapide » que pas mal de gens évoquent.

Le mieux ? Vous n'avez rien à faire. Et si jamais vous voulez l'ancien comportement, il existe une variable d'environnement pour désactiver la compression.

**Sources**

- [Claude Code waits 3x less for the first token (AICoder)](https://aicoder.com/news/news-20261017-claude-code-3x-faster-first-token-gzip-cloud-prewarm)
- [AI Changelog Week 42 (Neomanex)](https://neomanex.com/changelog/2026-w42)
