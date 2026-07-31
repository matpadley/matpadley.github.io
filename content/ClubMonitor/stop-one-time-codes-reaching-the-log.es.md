---
title: "Evitar que los Códigos de Un Solo Uso Lleguen al Log Fuera del Desarrollo"
date: 2026-07-31T09:30:00+01:00
draft: false
description: "Los remitentes que solo registran en log para el doble factor se registraban incondicionalmente, por lo que en producción se habría escrito cada código en el log de la aplicación. Un comentario no es un control."
summary: "Los remitentes que solo registran en log para el doble factor se registraban incondicionalmente, por lo que en producción se habría escrito cada código en el log de la aplicación. Un comentario no es un control."
tags:
  - club-monitor
  - dotnet
  - security
  - two-factor
  - configuration
---

## El defecto

`Program.cs` registraba los remitentes que solo usan log de forma incondicional:

```csharp
// Staging y producción deben registrar un proveedor real aquí...
builder.Services.AddScoped<IEmailSender, LoggingEmailSender>();
builder.Services.AddScoped<ISmsSender, LoggingSmsSender>();
```

Cada entorno los heredaba, por lo que un despliegue habría escrito **cada código de doble factor en el log de la aplicación y en OpenTelemetry** — anulando el segundo factor para cualquiera que pudiera leer los logs, mientras parecía funcionar perfectamente. La única salvaguarda era un comentario, y un comentario no es un control.

## La solución

La selección del remitente es ahora impulsada por configuración con guardas de inicio en `NotificationExtensions`. La idea rectora es que **un valor predeterminado inseguro debe ser imposible, y cualquier exclusión voluntaria debe ser explícita**:

- Los proveedores de `Logging` son **rechazados fuera de Development** — la aplicación lanza una excepción al inicio con un mensaje accionable en lugar de arrancar en un estado que filtra datos.
- Fuera de Development, un proveedor **no configurado** es un error, no un valor por defecto. Esta es la mitad importante: el error original era un recurso silencioso, por lo que el silencio ahora debe fallar ruidosamente.
- La entrega puede desactivarse en cualquier entorno, pero solo indicando `None`. Eso registra `UnavailableEmailSender`/`UnavailableSmsSender`, que reportan `IsConfigured = false` y **lanzan una excepción** si son invocados — descartar silenciosamente un código dejaría a un usuario bloqueado sin ningún rastro.
- `Smtp` es rechazado al inicio cuando falta `Host` o `FromAddress`, ya que nunca podría entregar.

`IEmailSender`/`ISmsSender` adquirieron `IsConfigured` para que el caso de bloqueo se maneje correctamente en lugar de por excepción:

- `ConfigureTwoFactorHandler` rechaza dejar que un usuario *habilite* un factor que este despliegue no puede entregar.
- `SendTwoFactorCodeHandler` devuelve un error de validación limpio en lugar de dejar que el remitente no disponible lance una excepción.

Se añadió `SmtpEmailSender` para que haya una ruta de producción real, usando el cliente SMTP de la BCL (sin nueva dependencia). Su registro omite deliberadamente el cuerpo del mensaje, que contiene el código.

## Verificación

Las pruebas unitarias cubren las guardas (62 en total, antes eran 50), pero las guardas también se ejercitaron contra un host real — el intento anterior de hacer esto no ejecutó nada silenciosamente, porque `timeout` no existe en macOS y los greps coincidían con un log vacío. Rehecho correctamente:

| Configuración | Resultado |
|---|---|
| Producción + `Logging` (el error original) | se negó a arrancar |
| Producción, nada configurado | se negó a arrancar |
| Producción + `None` explícito | arrancó, health 200 |
| Producción + `Smtp` completamente configurado | arrancó, health 200 |
| Development (usa log por defecto) | arrancó, health 200 |

## También actualizado

`infra/main.bicep` incorporó los ajustes de notificación (el proveedor de email por defecto es `None`, así que un despliegue es seguro pero el 2FA por email está desactivado hasta que se configure un relay SMTP), y `deploy.yml` los pasa. La especificación, `CLAUDE.md` y `README` registran las reglas, incluyendo una instrucción explícita de no "arreglar" un fallo al inicio reintroduciendo un valor por defecto.

## No realizado

No hay transporte SMS implementado — no hay un equivalente en la BCL — así que el doble factor por mensaje de texto necesita un proveedor (Twilio, Azure Communication Services) detrás de `ISmsSender`. `SmtpEmailSender` no ha sido ejercitado contra un servidor SMTP real; solo su selección y validación de configuración están probadas.

## Archivos modificados

`src/ClubMonitor.Api/Infrastructure/Notifications/*` (interfaces, remitentes de log, nuevos remitentes no disponibles, nuevo remitente SMTP, opciones, registro), `Program.cs`, `Handlers/Auth/ConfigureTwoFactorHandler.cs`, `Handlers/Auth/SendTwoFactorCodeHandler.cs`, ambos archivos de appsettings, `infra/main.bicep`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, pruebas, más esta entrada.
