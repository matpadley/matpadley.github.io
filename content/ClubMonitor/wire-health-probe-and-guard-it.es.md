---
title: "Conectar la Sonda de Salud y Protegerla contra el Crecimiento"
date: 2026-07-30T09:00:00+01:00
draft: false
description: "Por qué /health permanece anónimo, por qué mereció la pena conectarlo a App Service, y cómo evitar que acumule cadenas de conexión como siempre hacen los endpoints de salud."
summary: "Por qué /health permanece anónimo, por qué mereció la pena conectarlo a App Service, y cómo evitar que acumule cadenas de conexión como siempre hacen los endpoints de salud."
tags:
  - club-monitor
  - azure
  - bicep
  - security
  - observability
---

## Por qué

Seguimiento a la pregunta de si `/health` debería bloquearse. Decisión: **mantenerlo anónimo.**

El endpoint devuelve un `{"status":"healthy"}` codificado, así que no divulga nada que un atacante no aprenda ya del handshake TLS o de recibir un 401 en cualquier otra ruta. Mientras tanto, las comprobaciones de salud de App Service, las sondas del balanceador de carga y los monitores de disponibilidad no pueden presentar un token bearer — bloquearlo eliminaría una capacidad operativa sin ningún beneficio de seguridad, y dejaría la señal de salud ambigua (algunas sondas interpretan 401 como activo, otras como inactivo), por lo que las interrupciones reales pasarían desapercibidas durante más tiempo.

El riesgo genuino no es el endpoint actual, sino en lo que se convierten los endpoints de salud: acumulan conectividad de base de datos, estado de migraciones, versiones de dependencias y eventualmente texto de excepciones que contiene cadenas de conexión. Así que la respuesta fue hacer que el endpoint *ganara su lugar* y cercarlo frente a esa deriva.

## Qué cambió

- **`infra/main.bicep`**: se estableció `healthCheckPath: '/health'` en la aplicación de API. Anteriormente estaba expuesto pero sin sonda — lo peor de ambos mundos. Se verificó que compila en la salida ARM solo en la aplicación de API (el head web es contenido estático sin esa ruta). Requiere el plan de nivel Basic o superior, que la plantilla ya usa (`B1`).
- **`src/ClubMonitor.Api/Program.cs`**: comentario en el endpoint que registra por qué es anónimo y que la respuesta debe permanecer como cadena fija. Sin cambio de comportamiento.
- **`Docs/main_spec.md`** y **`CLAUDE.md`**: se añadió la regla de que `/health` nunca debe reportar detalles de base de datos, dependencias, migraciones, configuración o excepciones; una comprobación de preparación que necesite cualquiera de eso va en una **ruta autenticada separada**. También se registró que si la sonda en sí debe ocultarse, eso pertenece a la capa de **red** (restricciones de acceso de App Service, o ingreso solo mediante Front Door) en lugar de añadir autenticación que rompería la sonda.

## Verificación

- Se compiló el Bicep a ARM y se afirmó `healthCheckPath=/health` en el sitio de la API y no establecido en el sitio web.
- 50 pruebas NUnit pasan. La prueba Playwright existente `Only_the_sign_in_endpoints_and_health_are_anonymous` ya fija el comportamiento esperado: 401 en toda la superficie de la API, 200 en `/health`.

## Archivos modificados

`infra/main.bicep`, `src/ClubMonitor.Api/Program.cs`, `Docs/main_spec.md`, `CLAUDE.md`, más esta entrada.
