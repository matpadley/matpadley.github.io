---
title: "Claude Code por fin deja de hacerte esperar"
date: 2026-10-19
draft: false
description: "Anthropic asegura que la espera antes de la primera palabra de Claude Code bajó de unos 4 segundos a 1,3 — sin modelo nuevo, solo fontanería."
tags:
  - claude-code
  - anthropic
  - performance
---

Anthropic dice que la pausa antes de que Claude Code empiece a responder se ha reducido unas 3 veces: de unos 4 segundos a 1,3 en los casos más lentos (el famoso p90, para los fans de las estadísticas). Y lo curioso es que no es un modelo más listo, es fontanería. Ahora las peticiones se comprimen (gzip) antes de enviarse, y las sesiones en la nube empiezan a calentarse en cuanto empiezas a escribir.

Las sesiones en la nube también mejoraron, de unos 17 segundos a 6. Ojo, son cifras de la propia Anthropic, pero encaja con esa sensación de «oye, va más rápido» que mucha gente comenta.

¿Lo mejor? No tienes que hacer nada. Y si algún día quieres el comportamiento antiguo, hay una variable de entorno para apagar la compresión.

**Fuentes**

- [Claude Code waits 3x less for the first token (AICoder)](https://aicoder.com/news/news-20261017-claude-code-3x-faster-first-token-gzip-cloud-prewarm)
- [AI Changelog Week 42 (Neomanex)](https://neomanex.com/changelog/2026-w42)
