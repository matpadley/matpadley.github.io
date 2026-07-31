---
title: "El Frontend Nunca Estuvo Realmente Conectado a la API"
date: 2026-07-29T16:15:00+01:00
draft: false
description: "Cada captura de pantalla anterior de \"funcionando\" era el bloque catch del ApiClient sirviendo datos de muestra. Un error de un dígito en el puerto, y lo que hizo falta para demostrar que el stack realmente estaba conectado."
summary: "Cada captura de pantalla anterior de \"funcionando\" era el bloque catch del ApiClient sirviendo datos de muestra. Un error de un dígito en el puerto, y lo que hizo falta para demostrar que el stack realmente estaba conectado."
tags:
  - club-monitor
  - dotnet
  - uno-platform
  - debugging
  - testing
---

## Qué cambió

El frontal UNO nunca fue realmente verificado contra una API en ejecución — cada captura de pantalla anterior de "funcionando" mostraba silenciosamente los datos de muestra del bloque catch de reserva del `ApiClient`, no respuestas reales de la API.

Se encontraron y corrigieron dos errores reales:

1. **`src/ClubMonitor.App/Services/ApiClient.cs`** — la `BaseAddress` por defecto era `http://localhost:5210`, pero el `Properties/launchSettings.json` de la API la ejecuta en `5239`. Cada solicitud fallaba, llegaba al bloque `catch` y devolvía datos de reserva. Se corrigió el valor por defecto a `5239` (aún reemplazable mediante `CLUBMONITOR_API_URL`).
2. Se confirmó una trampa relacionada para el desarrollo local: ejecutar la API con `dotnet run --no-launch-profile` omite la variable `ASPNETCORE_ENVIRONMENT=Development` establecida en `launchSettings.json`, por lo que carga silenciosamente `appsettings.json` (`ConnectionStrings:ClubMonitor` vacío) en lugar de `appsettings.Development.json`, produciendo `InvalidOperationException: The ConnectionString property has not been initialized.` en cada endpoint que toca la BD. No es un error de código, pero se documenta aquí ya que es una forma fácil de reintroducir el comportamiento "parece bien, no lo está" — siempre ejecutar localmente mediante `dotnet run --launch-profile http` (o simplemente `dotnet run`), no `--no-launch-profile`.

## Verificación realizada

- Se inició un contenedor local de SQL Server 2022 (`docker run ... mcr.microsoft.com/mssql/server:2022-latest`), se aplicó la migración EF Core `InitialCreate` contra él.
- Se ejecutó la API con su perfil de lanzamiento `http` y se probó cada capa del stack con `curl` de verdad: crear deporte (Super Admin) → crear club (se crea automáticamente la membresía de Admin) → invitar miembro → aceptar invitación → crear competición sin `sportId` (se confirmó que la regla de selección automática de deporte se activa con filas reales de BD) → añadir entradas → programar partido → registrar resultado → obtener clasificaciones (se confirmó que los 3/0 puntos se calculan en el servidor a partir de filas reales de partidos) → se confirmó el aislamiento de tenants (una competición de club privado devuelve `[]` cuando se consulta sin contexto de club).
- Se reconstruyó y ejecutó el head WebAssembly de UNO real apuntando al puerto corregido y se capturó pantalla: el dashboard muestra "Winter League" / Alice Admin 3 pts / Mark Member 0 pts — datos reales sembrados, no la antigua lista de muestra de reserva.

## Por qué

El usuario preguntó directamente si el frontal estaba conectado a la API. No lo estaba, debido al error de puerto anterior; esta sesión lo corrigió y lo demostró de extremo a extremo en lugar de asumir a partir de los resultados de las pruebas unitarias/e2e (que usan EF InMemory / datos simulados y nunca ejercitaron la ruta real HTTP + SQL).

## Archivos modificados

`src/ClubMonitor.App/Services/ApiClient.cs` (corrección del puerto), esta entrada de progreso.
