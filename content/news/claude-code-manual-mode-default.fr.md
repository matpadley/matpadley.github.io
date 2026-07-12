---
title: "Claude Code vient d'arrêter de se faire confiance par défaut"
date: 2026-07-06
draft: false
description: "Claude Code a discrètement basculé son mode de permission par défaut sur Manuel et supprimé la poursuite automatique des invites AskUserQuestion. Les nouvelles installations s'arrêtent désormais bien plus souvent pour demander l'autorisation."
tags:
  - claude-code
  - anthropic
  - ai-coding-tools
---

Claude Code a discrètement basculé son mode de permission par défaut sur « Manuel » cette semaine, et désactivé la poursuite automatique sur les fenêtres `AskUserQuestion`. Traduction : les nouvelles installations, et beaucoup d'installations existantes, vont désormais s'arrêter pour demander la permission avant de faire des choses qu'elles enchaînaient auparavant sans broncher.

C'est clairement une mesure de prudence après un été marqué par des articles sur des agents de code partant en roue libre en pleine tâche. Si vous aviez pris l'habitude que Claude Code fonce sans demander, attendez-vous à beaucoup plus de « je peux faire ça ? » à partir de maintenant — vous pouvez toujours revenir en arrière avec `--permission-mode` si vous préfériez vivre dangereusement.

**Sources :**
- [Claude Code changelog, v2.1.200 (3 juillet 2026)](https://code.claude.com/docs/en/changelog)
