---
title: "Matar un proceso por su puerto en macOS"
date: 2026-08-21T12:00:00+01:00
draft: false
tags: ["macos", "dotnet", "dev-environment", "terminal"]
categories: ["articles"]
summary: "Una chuleta para encontrar y matar lo que sea que esté ocupando un puerto en macOS — escrita después de perder un rato intentando rastrear un entorno de desarrollo dotnet fantasma."
---

Apunto esto porque acabo de perder diez minutos intentando averiguar *cuál* de mis entornos de desarrollo `dotnet` en marcha tenía un puerto bloqueado, sin poder rastrearlo hasta un proyecto o una ventana de terminal concreta. En lugar de investigarlo como es debido, lo maté por el puerto y seguí adelante — así que aquí queda la chuleta para la próxima vez.

## Encontrar qué está usando el puerto

```bash
lsof -i :3000
```

Esto lista el proceso que retiene el puerto, incluido su PID:

```
COMMAND   PID   USER   FD   TYPE ...
dotnet   1234   mat    23u  IPv4 ...
```

## Matarlo

Una vez que tienes el PID:

```bash
kill -9 1234
```

O ve directo al grano en una sola línea:

```bash
kill -9 $(lsof -ti:3000)
```

Una alternativa usando `fuser`:

```bash
sudo fuser -k 3000/tcp
```

## Una nota sobre `-9`

`kill -9` es una muerte forzosa (`SIGKILL`) — no le da al proceso ninguna oportunidad de limpiar lo suyo. Para un `dotnet watch` o un servidor de desarrollo atascado eso está bien, pero si prefieres intentar antes un cierre ordenado, prueba:

```bash
kill -15 1234
```

y escala a `-9` solo si no responde.

## La lección de verdad

Matar por el puerto es un apaño, no una solución. Si te pasa una y otra vez, sobre todo con proyectos `dotnet`, merece la pena echarle un vistazo a `dotnet-trace` — o simplemente ser más disciplinado y parar los servidores de desarrollo con `Ctrl+C` en vez de cerrar pestañas del terminal, que es casi con toda seguridad como acabé con un proceso huérfano en primer lugar.
