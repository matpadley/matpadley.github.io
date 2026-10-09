---
title: "¿Mensajes, Mapas y Contactos no se abren en macOS 27? La solución fue un perfil nuevo"
description: "Tras pasar de la beta de macOS 27 a la versión final, Mensajes se quedaba colgado, Mapas y Contactos no arrancaban y Ajustes del Sistema se cerraba. La causa era mi perfil de usuario, no macOS, y la solución fue crear uno nuevo."
date: 2026-10-07
tags:
  - Troubleshooting
---

## El síntoma

Después de pasar de la beta de macOS 27 a la versión final (27.0.1), tres aplicaciones de Apple dejaron de funcionarme. Mensajes rebotaba en el Dock sin parar y aparecía como «No responde» en Forzar salida. Mapas y Contactos no arrancaban en absoluto. Al hacer clic en Mensajes dentro de Ajustes del Sistema, Ajustes del Sistema se cerraba de golpe, y al intentar cerrar sesión en iCloud el cuadro de diálogo se quedaba girando indefinidamente en «Cerrando sesión».

Todo había funcionado bien en la beta, hasta que instalé la versión final. Cuando por fin conseguí cerrar sesión en iCloud y volver a iniciarla, no cambió nada.

## ¿Es macOS o soy yo?

La prueba más útil me llevó dos minutos: **crear una cuenta de usuario nueva y probar las aplicaciones allí.** Mensajes, Mapas y Contactos funcionaban perfectamente en la cuenta nueva, en el mismo Mac y con la misma versión de macOS.

Ese único resultado cambió toda la investigación. El sistema operativo estaba bien. Lo que fallaba eran los datos de *mi* perfil.

## Acotando el problema

Contactos parecía el sospechoso evidente, ya que Mensajes y Mapas dependen de él, así que moví la carpeta `AddressBook` fuera de `~/Library/Application Support/`. Contactos simplemente creó una nueva y no cambió nada.

Lo que sí hizo avanzar las cosas fue mover los archivos de preferencias de las aplicaciones afectadas. Tras apartarlos y reiniciar, Contactos y Mapas volvieron a abrirse:

```text
~/Library/Preferences/com.apple.AddressBook*
~/Library/Preferences/com.apple.Maps*
~/Library/Preferences/com.apple.systempreferences*
```

Mensajes seguía colgado.

## Leyendo la muestra

Para Mensajes, abrí el Monitor de Actividad mientras la aplicación rebotaba, la seleccioné y elegí **Muestrear proceso** en el menú del engranaje. La aplicación no se estaba cerrando: estaba *esperando*. El hilo principal estaba atascado durante el arranque dentro de `IMCore`, bloqueado en una cola de dispatch, y esa cola a su vez estaba bloqueada en una llamada síncrona a un demonio en segundo plano:

```text
com.apple.IMCore.DaemonConnectionSetup
  -[NSXPCConnection _sendInvocation:...]
    __NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__
```

Un segundo hilo estaba en el mismo estado, esperando la respuesta de otro servicio:

```text
com.apple.telephonyutilities.callcapabilitiesxpcclient
  -[TUCallCapabilitiesXPCClient _retrieveState]
```

Así que Mensajes esperaba eternamente a servicios en segundo plano que nunca respondían. Estos demonios se ejecutan por usuario y guardan su propio estado, lo que encaja con que la cuenta nueva funcionara.

## Lo que no funcionó

Reinicié los demonios más probables, que macOS vuelve a lanzar automáticamente:

```bash
killall imagent identityservicesd callservicesd
```

Después aparté el estado de iMessage y de los servicios de identidad: los archivos de preferencias `com.apple.imagent*`, `com.apple.madrid*`, `com.apple.imservice*`, `com.apple.identityservices*` y `com.apple.TelephonyUtilities*`, además de `~/Library/IdentityServices/`. Nada arregló Mensajes.

También me planteé reinstalar macOS, pero una reinstalación desde Recuperación no toca los datos de usuario, incluido todo lo que hay en `~/Library`. La cuenta nueva ya había demostrado que los archivos del sistema estaban bien, así que lo más probable es que me hubiera devuelto directamente al mismo bloqueo.

## La solución: creé un perfil nuevo

En ese punto dejé de adivinar. Mi hipótesis es que algo heredado de la beta en los datos de mi perfil antiguo confundía a la versión final, y no iba a encontrarlo a base de prueba y error. Así que **recreé un perfil nuevo**:

1. Primero, copia de seguridad: una pasada de Time Machine, más una copia de `~/Library/Messages`, que guarda el historial de mensajes si no lo sincronizas con iCloud.
2. Crear un usuario nuevo, iniciar sesión en iCloud y activar Mensajes, Contactos y lo demás.
3. Copiar los archivos —Documentos, Escritorio, Descargas, Imágenes— dejando deliberadamente `Library` atrás, porque ahí está el problema.

Mensajes, Mapas, Contactos y Ajustes del Sistema funcionan todos en el perfil nuevo.

## Conclusión

Si varias aplicaciones integradas de Apple fallan a la vez tras una actualización, sobre todo de una beta a una versión final, **prueba con una cuenta de usuario completamente nueva antes de tocar nada más.** Lleva dos minutos y te dice si estás luchando contra macOS o contra tu propio perfil. Si la cuenta nueva funciona, olvídate de reinstalar y de la interminable cirugía de preferencias.

En mi caso era mi perfil, y **recreé un perfil nuevo para solucionarlo.**
