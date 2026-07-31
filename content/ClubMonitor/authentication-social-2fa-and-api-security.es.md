---
title: "Autenticación: Inicio de Sesión Social, Doble Factor y Seguridad de la API"
date: 2026-07-29T17:30:00+01:00
draft: false
description: "ASP.NET Core Identity con tokens JWT bearer, cuatro proveedores externos y passkeys usadas como segundo factor — más la trampa de la versión del esquema de Identity que elimina silenciosamente la tabla de passkeys."
summary: "ASP.NET Core Identity con tokens JWT bearer, cuatro proveedores externos y passkeys usadas como segundo factor — más la trampa de la versión del esquema de Identity que elimina silenciosamente la tabla de passkeys."
tags:
  - club-monitor
  - dotnet
  - aspnet-core-identity
  - authentication
  - security
  - passkeys
---

## Qué cambió

Se añadió una pantalla de login y toda la aplicación quedó protegida tras ella. La API ahora está asegurada con tokens y la identidad de desarrollo basada en cabeceras ha desaparecido.

### Primero la especificación
`Docs/main_spec.md` no tenía sección de autenticación, así que se añadió una (y se actualizó `CLAUDE.md` para que coincida) antes de escribir código, según el acuerdo de trabajo. Registra los métodos de inicio de sesión, las reglas de doble factor, el modelo de tokens/claims y las dos desviaciones descritas a continuación.

### Modelo de identidad — `src/ClubMonitor.Api`
- `User` ahora extiende `IdentityUser<int>`; `ClubMonitorDbContext` extiende `IdentityDbContext`. `DisplayName`, `IsSuperAdmin` y `Memberships` permanecen, más un nuevo `TwoFactorMethod`.
- Nueva migración `AddIdentityAuthentication` (usuarios/roles/logins/tokens/claims/passkeys). La base de datos de desarrollo fue eliminada y reconstruida.

### Inicio de sesión
- **Proveedores externos**: Google, Facebook, X (Twitter) y Apple. Cada uno se registra solo cuando sus credenciales están configuradas, por lo que la aplicación funciona localmente sin ninguno y la pantalla de login solo muestra botones que funcionarán.
- **Email + contraseña** mediante Identity, con bloqueo tras 5 fallos y contraseña mínima de 10 caracteres.
- **Doble factor** en la ruta de contraseña: **email**, **SMS** o **passkey**. Email/SMS van a través de `IEmailSender`/`ISmsSender` intercambiables; el desarrollo local registra el código en lugar de enviarlo.
- **Inicio de sesión sin contraseña mediante passkey** también, que es el escenario de passkey compatible con el framework.

### Tokens y tenancy
- `JwtTokenService` emite tokens de acceso que llevan el id de usuario, el club activo y la marca de super-admin. Una contraseña correcta con 2FA habilitado devuelve solo un **token pendiente** de corta duración, que es rechazado en todas partes excepto en los endpoints de completar el doble factor.
- `CurrentUserMiddleware` ya no lee `X-User-Id`/`X-Club-Id`; construye el contexto de tenant a partir de claims de token verificados, por lo que un llamador ya no puede seleccionar otro tenant editando una cabecera. El cambio de club pasa por `/api/auth/select-club/{id}`, que verifica la membresía en el servidor.

### Frontend — `src/ClubMonitor.App`
- Nueva `LoginPage` (contraseña, paso 2FA, passkey, botones sociales), `AuthService` que gestiona la sesión, e interoperabilidad WebAuthn con passkey para el head WASM.
- La raíz de la aplicación muestra la pantalla de login hasta que se confirma una sesión y cambia al shell al iniciar sesión; se añadió un botón de cierre de sesión al shell.
- `ApiClient` ahora envía el token bearer y **ya no recurre a datos de muestra inventados** — esa reserva anteriormente enmascaraba una conexión a la API completamente rota, por lo que los fallos ahora se manifiestan como contenido vacío en lugar de contenido ficticio.

## Dos desviaciones deliberadas, ambas indicadas en la especificación

1. **El passkey como segundo factor no es algo que ASP.NET Core Identity soporte.** Su documentación establece que los passkeys se "tratan como factor de autenticación primario, no como segundo factor". El comportamiento solicitado se construyó directamente sobre `PerformPasskeyAssertionAsync`, y su seguridad descansa en que `VerifyPasskeyTwoFactorHandler` afirme que el usuario verificado coincide con el usuario que pasó el paso de contraseña — sin esa comprobación cualquier passkey válido completaría el inicio de sesión de cualquiera. Hay una prueba para ello.
2. **Los resultados públicos permanecen legibles de forma anónima.** "Asegurar la API" entra en conflicto con la regla de dominio existente de que un Admin puede publicar resultados como "público (visible para cualquiera)". Los endpoints de clasificaciones y lista de partidos permiten por tanto llamadas anónimas y el handler continúa aplicando la visibilidad; todo lo demás requiere un token. Todas las *páginas* siguen requiriendo inicio de sesión.

## Una trampa del framework que merece registrarse

Identity mapea la tabla de passkeys solo desde la **versión de esquema 3**; las versiones 1 y 2 llaman a `Ignore` en la entidad passkey, y **la versión 1 es la predeterminada**. La versión se lee de `IdentityOptions.Stores.SchemaVersion` a través del *proveedor de servicios de la aplicación*, que una fábrica en tiempo de diseño no tiene — por lo que las migraciones generadas no tenían tabla de passkeys incluso después de establecer la opción en tiempo de ejecución. Se solucionó estableciéndola en `Program.cs` para el tiempo de ejecución y dando a `DesignTimeDbContextFactory` un proveedor de servicios mediante `UseApplicationServiceProvider`. Sobreescribir la propiedad `SchemaVersion` **no** funciona: `OnModelCreating` lee las opciones directamente y lo omite.

## Verificación

- **49 pruebas NUnit** (antes eran 27): registro, reglas de contraseña, respuestas idénticas para email desconocido vs contraseña incorrecta, los flujos 2FA para email/SMS/passkey, bloqueo de configuraciones 2FA inválidas, contenido de claims de tokens, y que un token pendiente no establece contexto de tenant.
- **6 pruebas Playwright** (antes eran 3): la aplicación no solicita datos del club antes del inicio de sesión, la API devuelve 401 sin token, y los resultados publicados no están detrás de 401.
- **Ejecutado en vivo en un navegador** contra SQL Server: inicio de sesión → desafío 2FA → código leído del log de desarrollo → verificado → dashboard cargado con una llamada autenticada a `/api/competitions`.

## Archivos modificados

Nuevos `Handlers/Auth/*`, `Infrastructure/Auth/*`, `Infrastructure/Notifications/*`, `Endpoints/AuthEndpoints.cs`, `Endpoints/EndpointResults.cs`; modificados `Domain/User.cs`, `Data/*`, `Endpoints/ApiEndpoints.cs`, `Program.cs`, configuración de la aplicación, `infra/main.bicep`, `.github/workflows/deploy.yml`; nuevas `Views/LoginPage.*` y `Services/*` en la aplicación; nuevas pruebas; `Docs/main_spec.md`, `CLAUDE.md`, `README.md`.
