---
title: "El Selector de Idioma Que no Podía Deshacerse"
date: 2026-08-01T10:30:00+01:00
draft: false
description: "Añadir una opción «Idioma del sistema» debería haber llevado quince minutos. No hacía nada justo en el caso para el que existe, porque Uno persiste la anulación de idioma y la aplica antes de que se ejecute código de la aplicación: preguntar a la cultura ambiental cómo está configurado el dispositivo devuelve la elección anterior de la propia aplicación."
summary: "Añadir una opción «Idioma del sistema» debería haber llevado quince minutos. No hacía nada justo en el caso para el que existe, porque Uno persiste la anulación de idioma y la aplica antes de que se ejecute código de la aplicación: preguntar a la cultura ambiental cómo está configurado el dispositivo devuelve la elección anterior de la propia aplicación."
tags:
  - club-monitor
  - uno-platform
  - localization
  - debugging
  - webassembly
  - testing
source: "2026-08-01-1030-language-picker-system-default.md"
---

El selector de idioma se publicó con tres entradas —English, Français, Español— y ninguna forma de dejar de seguir una elección explícita. Una anulación se podía cambiar, pero nunca deshacer. Cerrar esa carencia parecía un trabajo de quince minutos: añadir un elemento **Idioma del sistema**, borrar la anulación guardada, volver a renderizar. No funcionó, y el motivo llevaba en el código desde que se construyó el selector.

## Qué tiene que significar «Idioma del sistema»

Borrar la anulación es solo la mitad. La cuenta sigue necesitando un idioma concreto, porque los correos y los mensajes de texto se componen en un servidor que no puede ver la configuración regional del sistema de este dispositivo. La respuesta honesta es el idioma que la aplicación muestra ahora, así que `FollowSystem()` borra la anulación, vuelve a renderizar y sincroniza con la cuenta la cultura efectiva resultante.

El selector también tiene que *mostrar* lo correcto. Cuando no hay ninguna anulación guardada, muestra **Idioma del sistema** como seleccionado, en lugar de resaltar el idioma que casualmente se resolvió: resaltar «Español» reclamaría una elección que el usuario nunca hizo.

La entrada nueva es, dicho sea de paso, el único elemento de esa lista que se traduce. Los nombres de idioma que la acompañan son endónimos y permanecen idénticos en todas las culturas; «System default» es una expresión, así que pasa a ser «Langue du système» e «Idioma del sistema».

## Por qué no funcionaba

**Uno persiste `ApplicationLanguages.PrimaryLanguageOverride` entre reinicios y lo aplica antes de que se ejecute cualquier código de la aplicación.**

El servicio de cultura respondía a «¿en qué idioma está configurado este dispositivo?» leyendo `CultureInfo.CurrentUICulture`. A partir del segundo arranque, eso informa del idioma *que la propia aplicación eligió la vez anterior*. El código original ya se protegía de esto dentro de una sesión, capturando el valor al principio del arranque, pero una instantánea no sobrevive a un reinicio, porque la contaminación ocurre antes de que haya algo que capturar.

Sígase el hilo en un dispositivo alemán. Elegir español. Reiniciar. Pulsar Idioma del sistema. La anulación se borra, la aplicación pregunta «¿en qué idioma está el dispositivo?», se le responde «español» y se queda en español.

La función no hacía nada justo en el caso para el que existe.

`ReadDeviceLanguage()` deriva ahora el idioma del dispositivo de `ApplicationLanguages.Languages` con la anulación activa eliminada. Uno coloca la anulación al principio de la lista propia del dispositivo, así que quitarla deja debajo la verdad. `GlobalizationPreferences.Languages` es la API que WinUI documenta exactamente para esto y habría sido la corrección obvia, pero la cabecera WebAssembly de Uno lanza `NotImplementedException` desde ella, algo confirmado instrumentando la aplicación en ejecución.

## Cómo se encontró

No leyendo el código.

El selector de Ajustes vive dentro del canvas de Skia y no se puede pulsar desde Playwright, así que el ciclo de vida se manejó directamente a través de la anulación guardada: cargar la aplicación tres veces contra un contexto de navegador `de-DE` y observar qué resuelve. La tercera carga devolvió español donde se esperaba inglés. Instrumentar el servicio de cultura y capturar la consola del navegador dio los valores reales —`appLangs=[es,de-DE]`, `currentUI=es` y `GlobalizationPreferences` lanzando una excepción—, lo que identificó tanto la causa como la solución.

Ese es todo el diagnóstico, y nada de él era visible desde el código fuente. Un error que solo aparece en el segundo arranque es invisible en una primera ejecución, y este además es invisible en una revisión de código: leer `CurrentUICulture` para averiguar el idioma del dispositivo parece del todo razonable hasta que se sabe que Uno ya lo ha sobrescrito.

## Qué lo protege ahora

Dos pruebas, con cometidos distintos.

`An_explicit_choice_sticks_across_restarts_and_System_default_undoes_it` recorre todo el ciclo de vida en un dispositivo alemán —es decir, no admitido—: empieza en inglés sin anulación guardada, mantiene el español tras un reinicio una vez elegido, y vuelve al inglés en cuanto se borra la anulación. Se verificó contra la lógica antigua, donde revertir `ReadDeviceLanguage` reproduce el fallo como «Borrar la anulación dejó la aplicación en el idioma que se acababa de borrar.»

La prueba maneja la anulación guardada en lugar del propio selector, ya que el control está dentro del canvas, y así lo indica en sus propios comentarios. Lo que realmente cubre es el comportamiento tras el reinicio, que es donde estaba el problema.

La segunda es estática: `The_language_picker_offers_every_supported_culture_and_the_system_default` fija las etiquetas `ComboBoxItem` del selector a `SupportedCultures.All` más `system`. De lo contrario, añadir un idioma podría publicar una cultura completamente traducida pero inalcanzable desde Ajustes, algo que nada más habría detectado: conectar el selector es un paso manual en el README.

La trampa de «nunca leas `CurrentUICulture` para saber cómo está configurado el *dispositivo*» está ahora escrita en los tres documentos del proyecto. Es invisible en una primera ejecución y solo muerde tras un reinicio, que es exactamente el tipo de cosa que se redescubre por la vía cara.
