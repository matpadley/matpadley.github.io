---
title: "Implementación Inicial de la Aplicación"
date: 2026-07-29T15:30:00+01:00
draft: false
description: "El primer pase funcional: una API Minimal de .NET 10 con multitenancy en EF Core, un frontal UNO Platform con temas intercambiables, cobertura con NUnit y Playwright, infraestructura Bicep y CI."
summary: "El primer pase funcional: una API Minimal de .NET 10 con multitenancy en EF Core, un frontal UNO Platform con temas intercambiables, cobertura con NUnit y Playwright, infraestructura Bicep y CI."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - uno-platform
  - minimal-api
  - bicep
---

## Qué cambió

Se implementó la primera versión funcional de la aplicación descrita en `Docs/main_spec.md`:

### Backend — `src/ClubMonitor.Api` (API Minimal de .NET 10)
- Modelo code-first de EF Core: `Sport`, `Club`, `ClubSport`, `User`, `Membership`, `Competition` (liga/copa, propiedad del club o a nivel de plataforma), `CompetitionClub`, `CompetitionEntry`, `Match`. Migración inicial creada (`Migrations/`).
- Multitenancy: `Club` es la frontera de tenant. Los filtros de consulta global de EF Core particionan los datos por ámbito de club mediante `ClubId`; el Super Admin omite el filtro; las competiciones a nivel de plataforma (`ClubId == null`) abarcan clubes mediante `CompetitionClub`; las competiciones cuyos resultados están configurados como Públicos son legibles por cualquiera.
- Metodología de handlers: una clase de handler discreta por funcionalidad (`Handlers/…`) que devuelve un `HandlerResult<T>` independiente del transporte; los endpoints (`Endpoints/ApiEndpoints.cs`) solo vinculan, delegan y traducen a HTTP.
- Reglas de dominio: roles por club, flujos de membresía por invitación + aceptación y solicitud de unión + aprobación, ascenso a admin, catálogo de deportes gestionado por Super Admin, selección automática de deporte cuando un club tiene exactamente uno, resultados y visibilidad solo para admin (Privado/Público), clasificaciones calculadas con 3/1/0 y desempate por diferencia de puntuación.
- Identidad: `CurrentUserMiddleware` resuelve el contexto de usuario/club a partir de las cabeceras `X-User-Id`/`X-Club-Id` — un sustituto de desarrollo para un proveedor de autenticación real; los handlers solo ven `ITenantContext`.
- Observabilidad: trazas/métricas/registros OpenTelemetry con exportador seleccionado mediante la configuración `Telemetry:Exporter` (`console`/`otlp`/`none`) — intercambiable por entorno sin cambios de código.

### Pruebas unitarias — `tests/ClubMonitor.Api.Tests` (NUnit + EF InMemory)
27 pruebas que cubren el catálogo de deportes, flujos de membresía, aislamiento de roles por club, regla de selección automática de deporte, competiciones de plataforma, visibilidad, programación/resultados de partidos y cálculo de clasificaciones. Todas pasan.

### Frontal — `src/ClubMonitor.App` (UNO Platform, WASM + escritorio)
- Arquitectura de tema/plantilla intercambiable: `Themes/OrganicTheme.xaml` y `Themes/NocturneTheme.xaml` definen las mismas claves de recurso; `ThemeService` intercambia el diccionario combinado en tiempo de ejecución (Shell tiene un botón "Cambiar tema"); las páginas nunca cambian.
- Pantallas según la especificación: Dashboard (saludo, acciones rápidas, ligas y copas con etiquetas, próximos partidos, vista previa de clasificaciones), Miembros (iniciales de avatar, etiquetas de rol/estado), Ligas, Clasificaciones, Perfil de jugador.
- Navegación adaptable: barra lateral en pantalla ancha (web/escritorio), barra de navegación inferior en pantalla estrecha (teléfono/tableta) mediante `AdaptiveTrigger`.
- Cliente tipado `ApiClient` con reserva de datos de muestra para que la interfaz funcione de forma independiente.
- **Nota:** la aplicación UNO tiene como objetivo `net9.0-browserwasm`/`net9.0-desktop` — las plantillas instaladas de Uno.Sdk aún no soportan .NET 10. La regla de .NET 10 se aplica a todo el código del backend. Revisitar cuando Uno publique TFMs para net10.
- Se corrigió un fallo al inicio (`FpsHelper` inicializador de tipo): las bibliotecas nativas del renderizador Skia necesitan `WasmBuildNative=true` más las cargas de trabajo `wasm-tools`/`wasm-tools-net9`. Ambas cargas están instaladas localmente y en CI.

### Pruebas E2E — `tests/ClubMonitor.UiTests` (Playwright + NUnit)
Pruebas de humo contra el head WASM en ejecución (la aplicación carga sin errores, el canvas de Skia renderiza, redimensionado de viewport teléfono/escritorio). Ubicado mediante `CLUBMONITOR_APP_URL`; ignorado cuando no está definido. Las 3 pruebas pasan localmente. El renderizador Skia dibuja en un canvas, por lo que las afirmaciones son a nivel de documento en lugar de consultas de texto DOM.

### Infraestructura y CI/CD
- `infra/main.bicep` (+ `.bicepparam` de staging/producción): plan de App Service, aplicación web de API, aplicación web estática para el head de UNO, servidor + base de datos Azure SQL. Compila con `az bicep build`. Staging y producción se despliegan en suscripciones separadas seleccionadas por las credenciales OIDC de cada entorno de GitHub.
- `.github/workflows/build-test.yml`: compilación + NUnit en PR/push; trabajo separado que arranca la aplicación WASM y ejecuta Playwright.
- `.github/workflows/deploy.yml`: login OIDC (sin secretos de larga duración), despliegue de Bicep, migraciones de EF, despliegue zip de API y head web. Staging al fusionar en master; producción mediante dispatch manual con protección de entorno.

### Control de versiones
Repositorio inicializado (`master` por defecto, sin commits directos); todo el trabajo está en `feature/initial-application` para revisión mediante PR.

## Por qué
Primer pase de implementación cubriendo todas las reglas obligatorias en `Docs/main_spec.md`.

## Archivos modificados
Todo bajo `src/`, `tests/`, `infra/`, `.github/workflows/`, `ClubMonitor.slnx`, `.gitignore`, `README.md`, más esta entrada.
