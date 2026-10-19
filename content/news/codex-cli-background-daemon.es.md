---
title: "Codex CLI deja un ayudante corriendo en silencio después de cerrarlo"
date: 2026-10-19
draft: false
description: "Desde la versión 0.157.0, la CLI de Codex de OpenAI arranca un proceso en segundo plano que sigue funcionando — y Hacker News se dio cuenta."
tags:
  - codex
  - openai
  - cli
---

Esta ha pillado por sorpresa a más de uno: desde la versión 0.157.0, abrir Codex CLI también arranca un pequeño ayudante en segundo plano que sigue funcionando cuando cierras la ventana. Busca actualizaciones cada hora y guarda su propia copia de la app en tu carpeta personal — alguien midió unos 374 MB, y algunos comentaristas cuentan que las copias viejas se han acumulado hasta ocupar varios gigas.

OpenAI lo presenta como una decisión deliberada y no como un fallo, pero una petición para hacerlo opcional llegó a la portada de Hacker News esta semana. No da miedo, solo provoca un «espera, ¿y esto qué hace aquí?».

Si prefieres no tenerlo, `codex features disable daemon_auto_start` desactiva el arranque automático en sesiones nuevas. La verdad, merece la pena echar un ojo a lo que corre en tu máquina.

**Fuentes**

- [Codex CLI Background Daemon: How to Turn It Off (Developers Digest)](https://www.developersdigest.tech/blog/codex-cli-background-daemon-auto-start-disable-2026)
- [Daemon Auto-Start Is Now the Stable Default in Codex CLI v0.157.0](https://codex.danielvaughan.com/2026/09/25/codex-cli-daemon-auto-start-stable-default-v0157/)
