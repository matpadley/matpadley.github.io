---
title: "Códigos de Error, No Prosa Traducida: Cómo Hacer Multilingüe una API"
date: 2026-07-31T16:00:00+01:00
draft: false
description: "Traducir los mensajes de fallo de una API convierte cada frase en parte del contrato de red y se rompe en cuanto el destinatario no es quien llama. La API de Club Monitor devuelve en su lugar códigos de error estables, y el barrido solo se volvió demostrable al hacer obligatorio el argumento del código."
summary: "Traducir los mensajes de fallo de una API convierte cada frase en parte del contrato de red y se rompe en cuanto el destinatario no es quien llama. La API de Club Monitor devuelve en su lugar códigos de error estables, y el barrido solo se volvió demostrable al hacer obligatorio el argumento del código."
tags:
  - club-monitor
  - dotnet
  - localization
  - api-design
  - entity-framework
  - testing
source:
  - "2026-07-31-1200-multilingual-plan-and-spec-update.md"
  - "2026-07-31-1230-multilingual-phase-0-decisions.md"
  - "2026-07-31-0940-multilingual-phase-1-backend-groundwork.md"
  - "2026-07-31-1300-multilingual-phase-2-auth-error-codes.md"
  - "2026-07-31-1500-multilingual-phase-2-remaining-error-codes.md"
  - "2026-07-31-1600-multilingual-phase-3-localized-notifications.md"
---

Club Monitor no tenía ninguna localización: cada mensaje de handler, cada plantilla de correo y cada cadena XAML era inglés codificado a mano. Hacer multilingüe toda la aplicación —inglés, francés y español— afecta a casi todos los handlers y a todas las páginas, así que se abordó como un plan por fases en lugar de como un único cambio enorme. Esta es la mitad del backend: las decisiones, el contrato de códigos de error y las plantillas de notificación.

## La decisión que condiciona todo lo demás

La primera pregunta es engañosamente simple: cuando la API rechaza una petición, ¿en qué idioma está el rechazo?

La respuesta tentadora es traducir el mensaje —leer `Accept-Language`, elegir un recurso, devolver prosa en francés—. También es la equivocada. Convierte cada mensaje de fallo en parte del contrato de red, de modo que mejorar la redacción inglesa rompe en silencio a los clientes que hacen coincidir ese texto. Obliga al servidor a mantener traducciones de un texto que nunca renderiza. Y falla por completo en cuanto el destinatario de un mensaje no es quien hizo la llamada.

Así que la API no traduce. `HandlerResult<T>` conserva su enumeración `HandlerError` existente, que decide el estado HTTP, y gana una segunda: `ErrorCode`, con un miembro por cada fallo distinto. El cuerpo de la respuesta pasa a ser:

```json
{ "error": "ClubNotFound", "message": "Club not found." }
```

`error` es el contrato estable contra el que programan los clientes. `message` es un recurso diagnóstico solo en inglés que ningún cliente debería mostrar literalmente. Cada cliente posee sus propias traducciones y asigna los códigos a sus propias cadenas localizadas.

La segunda decisión se desprende del mismo razonamiento. Parte del contenido sí lo genera realmente el servidor: un código de doble factor por correo o SMS y, más adelante, una notificación de invitación. Ese texto tiene que estar en *algún* idioma, y `Accept-Language` en la petición desencadenante no sirve de nada, porque el destinatario a menudo no es quien llama: un Admin que invita a un miembro es una persona actuando y otra leyendo. Por eso el registro de usuario ganó un `PreferredLanguage` BCP-47 anulable (`null` significa `en`), expuesto en `GET /api/auth/me` y modificable mediante `PUT /api/auth/language`.

## Hacer crecer la enumeración sin detener el mundo

La primera fase de implementación añadió solo infraestructura: la enumeración `ErrorCode` con un conjunto inicial reducido, una propiedad `Code` en `HandlerResult<T>`, la nueva forma de la respuesta, una constante `SupportedCultures`, la columna `PreferredLanguage` y su migración, y el handler y el endpoint para establecerla.

El truco que mantuvo esto revisable fue hacer opcional el nuevo argumento —`ErrorCode code = ErrorCode.Unspecified`— de forma que todos los puntos de llamada existentes en el código siguieran compilando sin tocarlos. El barrido pudo entonces avanzar por áreas funcionales, una cada vez.

Autenticación fue primero, por ser la más visible para el usuario: 22 códigos nuevos repartidos en 52 puntos de llamada en doce handlers. Las áreas restantes —Clubes, Competiciones, Partidos, Membresías y Deportes— añadieron otros 27.

Dos criterios se repiten a lo largo de todo el trabajo:

- **Los errores propios de Identity se agrupan en un solo código.** Los fallos compuestos a partir de `IdentityResult.Errors` (crear una cuenta, establecer una contraseña, activar el doble factor) se asignan todos a `IdentityOperationFailed`. El mensaje ya es la cadena inglesa compuesta por la propia Identity y no se divide de forma significativa en códigos más finos.
- **El mismo concepto reutiliza el mismo código.** `NotClubAdmin` cubre todas las comprobaciones de Admin de club; `MembershipNotFound` cubre una invitación, una solicitud de ingreso o un miembro ausentes; `PhoneNumberRequired` cubre tanto activar el doble factor por SMS sin número como enviar un código a una cuenta que no tiene ninguno registrado.

Luego viene lo que hizo demostrable el barrido. Con todos los puntos de llamada convertidos, se retiró el valor por defecto: `NotFound`, `Forbidden`, `Invalid` y `Conflict` ahora *exigen* un código. Que la API compile limpiamente con el parámetro obligatorio es la prueba de que no se pasó nada por alto, y a partir de aquí una nueva ruta de fallo no puede compilar sin nombrar su código. `Unspecified` sobrevive únicamente como el valor cero de la enumeración que llevan los resultados correctos.

## Un fixture de pruebas que mentía

Añadir cobertura de las rutas de fallo para el barrido destapó un error en las pruebas, no en el código. `SeedData` solo establecía `Email` en sus usuarios de siembra, pero Identity escribe también `NormalizedEmail`, `UserName`, `NormalizedUserName` y `SecurityStamp`. `InviteMemberHandler` busca usuarios por `NormalizedEmail`, así que fallaba silenciosamente con todos los usuarios sembrados y trataba una invitación duplicada como si fuera nueva. La nueva prueba `Inviting_an_existing_member_conflicts` falló hasta que la siembra coincidió con lo que Identity escribe realmente. El handler siempre estuvo bien; el fixture no.

## Localizar lo que el servidor sí envía

Con `PreferredLanguage` en su sitio, el correo y el SMS de doble factor se convirtieron en la primera salida del servidor genuinamente traducida: `NotificationStrings.resx` más sus hermanos `.fr` y `.es`, con claves para el asunto del correo, el cuerpo del correo y el cuerpo del SMS. Cada entrada lleva un comentario para el traductor que indica que «Club Monitor» es un nombre de producto, qué es `{0}` y que la cadena del SMS debe caber en un único segmento de 160 caracteres.

La restricción interesante es qué *no* usar. `IStringLocalizer` es la herramienta obvia y la equivocada: siempre resuelve contra la `CultureInfo.CurrentUICulture` ambiental, que en una petición de API es la cultura de quien llama, exactamente la fuente errónea cuando el destinatario es otra persona. `NotificationTemplates` toma en su lugar la cultura como argumento y llama a `ResourceManager.GetString(key, culture)`, la sobrecarga oficial que acepta una directamente. Eso evita además mutar la cultura ambiental en un hilo de petición compartido.

Las preferencias obsoletas recurren al idioma de respaldo en vez de lanzar una excepción. Si se retira un idioma de `SupportedCultures` después de que algunos usuarios lo hayan elegido, esas cuentas deben poder seguir recibiendo un código de inicio de sesión.

## Probar traducciones que fallan en silencio

Trece pruebas cubren las notificaciones, y dos de ellas existen precisamente por lo silenciosamente que esto puede romperse.

`ResourceManager` recurre al recurso neutro cuando falta una clave en un ensamblado satélite. Una cadena sin traducir parece por tanto perfectamente sana en tiempo de ejecución: simplemente muestra inglés. Por eso una prueba comprueba que el renderizado de cada cultura no predeterminada *difiere* realmente del inglés.

La otra extrae el código del correo en **francés** y lo verifica a través de `VerifyTwoFactorCodeHandler`. Una traducción que hubiera perdido su marcador `{0}` se mostraría preciosa y dejaría al usuario fuera.

La suite de la API pasó de 61 a 103 pruebas correctas a lo largo de estas fases. Y `bin/Debug/net10.0/fr/ClubMonitor.Api.resources.dll` aparece sin ningún cambio en el `.csproj`: el SDK recoge los archivos `.resx` por su cuenta.
