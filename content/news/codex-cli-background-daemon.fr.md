---
title: "Codex CLI laisse discrètement un assistant tourner après sa fermeture"
date: 2026-10-19
draft: false
description: "Depuis la version 0.157.0, la CLI Codex d'OpenAI lance un processus en arrière-plan qui continue de tourner — et Hacker News l'a remarqué."
tags:
  - codex
  - openai
  - cli
---

Voilà un truc qui a surpris pas mal de monde : depuis la version 0.157.0, ouvrir Codex CLI lance aussi un petit assistant en arrière-plan qui continue de tourner même quand vous fermez la fenêtre. Il vérifie les mises à jour toutes les heures et garde sa propre copie de l'appli dans votre dossier personnel — quelqu'un a mesuré environ 374 Mo, et certains commentateurs disent que les anciennes copies se sont accumulées sur plusieurs gigaoctets.

OpenAI parle d'un choix volontaire plutôt que d'un bug, mais une demande pour le rendre optionnel est arrivée en tête de Hacker News cette semaine. Rien de bien méchant, juste un petit « attends, il fait quoi là, lui ? ».

Si vous n'en voulez pas, `codex features disable daemon_auto_start` désactive le lancement automatique pour les nouvelles sessions. Franchement, ça vaut le coup d'aller voir ce qui tourne sur votre machine.

**Sources**

- [Codex CLI Background Daemon: How to Turn It Off (Developers Digest)](https://www.developersdigest.tech/blog/codex-cli-background-daemon-auto-start-disable-2026)
- [Daemon Auto-Start Is Now the Stable Default in Codex CLI v0.157.0](https://codex.danielvaughan.com/2026/09/25/codex-cli-daemon-auto-start-stable-default-v0157/)
