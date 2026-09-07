---
title: "¿Rider se queda colgado cargando cada proyecto? Revisa los permisos de privacidad de macOS para volúmenes externos"
date: 2026-09-07
draft: false
tags: ["jetbrains-rider", "macos", "dotnet", "troubleshooting"]
summary: "Rider 2026.2 se quedaba colgado en «Cargando proyectos» para cada solución en mi Mac. La causa real no era una caché corrupta ni un plugin defectuoso — era macOS revocando en silencio el acceso de Rider a un volumen externo tras una actualización."
---

## El síntoma

Cada solución que abría en JetBrains Rider 2026.2 en macOS se quedaba colgada en «Cargando proyectos». No era un proyecto puntualmente problemático — *todos* los proyectos, cada vez. Solución nueva, solución antigua, daba igual. La ventana se abría, el indicador de carga giraba indefinidamente, y nada en la interfaz daba la más mínima pista de por qué.

El protocolo habitual para esto — invalidar cachés, borrar `~/Library/Caches/JetBrains/Rider2026.2`, reiniciar en modo seguro para descartar plugins, matar cualquier proceso `dotnet`/`MSBuild` huérfano — no arregló nada. Curiosamente, VSCode no tenía ningún problema para compilar exactamente los mismos proyectos, lo que resultó ser la pista más importante.

## Leyendo el registro

El propio registro de Rider (`Help → Show Log in Finder`, o `~/Library/Logs/JetBrains/Rider2026.2/idea.log`) contaba la historia real en cuanto me molesté en mirarlo. Enterrado en un muro de stack traces estaba esto, repetido decenas de veces:

```
SEVERE - Access to the path '/Users/me/.dotnet/sdk' is denied. Operation not permitted
WARN  - /Users/me/.dotnet: Operation not permitted
```

El backend de Rider intentaba — y fallaba — enumerar mis SDKs de .NET instalados, una y otra vez, que es exactamente el tipo de cosa que produce un cuelgue aparentemente infinito al cargar el proyecto en lugar de un error limpio.

## Siguiendo el enlace simbólico

`~/.dotnet` en mi máquina no es un directorio real — guardo mis instalaciones del SDK de .NET en un volumen APFS externo para ahorrar espacio en el disco interno, y lo enlazo mediante un enlace simbólico:

```bash
$ readlink ~/.dotnet
/Volumes/LLM/.dotnet
```

El volumen estaba montado correctamente, formateado en APFS, y los permisos Unix normales de la carpeta estaban completamente bien. Y, lo que es crucial, **VSCode compilaba los mismos proyectos sin ningún problema**, lo que descartaba un problema real de permisos del sistema de archivos — si se tratara de un simple caso de «propietario incorrecto» o «chmod incorrecto», todas las herramientas estarían bloqueadas, no solo una.

## La causa real: TCC de macOS, no los permisos de Unix

Esa combinación — montado, con permisos correctos, pero con una aplicación bloqueada y otra funcionando bien — es la firma del sistema de protección de privacidad de macOS (TCC), y no un problema del sistema de archivos en absoluto. macOS trata el acceso a volúmenes extraíbles y externos como su propia categoría protegida, controlada aplicación por aplicación, por separado de los permisos normales de lectura/escritura. Cada aplicación tiene que recibir acceso de forma individual, y ese permiso está vinculado a la firma de código de la aplicación.

Lo que significa: **actualizar Rider cambia su firma, y macOS puede revocar silenciosamente un permiso previamente concedido al actualizar** — sin ningún aviso o error evidente que te diga que eso es lo que ha pasado. VSCode, al no haberse actualizado, conservó su permiso existente. Rider, recién actualizado a la versión 2026.2, lo perdió.

## La solución

1. Abre **Ajustes del Sistema → Privacidad y seguridad → Archivos y carpetas**, y comprueba si Rider aparece con acceso a volúmenes extraíbles. Revisa también **Acceso completo al disco** en el mismo panel.
2. Si falta, está desactualizado, o no estás seguro, obliga a macOS a reevaluarlo en lugar de confiar en el estado en caché:

   ```bash
   tccutil reset SystemPolicyAllFiles com.jetbrains.rider
   ```

   (Confirma primero el identificador de bundle real si no estás seguro — `mdls -name kMDItemCFBundleIdentifier /Applications/Rider.app`.)
3. Cierra Rider por completo (`Cmd+Q`, no solo cerrar la ventana) y vuelve a abrirlo. Abre una solución y presta atención a un posible aviso de permisos — puede aparecer detrás de la ventana principal en lugar de delante.
4. Si nada aparece automáticamente, prueba a desactivar y volver a activar el Acceso completo al disco de Rider en Ajustes — esto a veces obliga a macOS a volver a preguntar en lugar de reutilizar un resultado denegado.

Una vez concedido el permiso, los errores `/Volumes/...` desaparecen por completo de `idea.log`, y la carga de soluciones vuelve a la normalidad.

## La conclusión

Si un IDE o una herramienta en macOS empieza a fallar al leer algo en un volumen externo o de red — especialmente justo después de una actualización, y especialmente cuando *otra* herramienta puede leer exactamente la misma ruta sin problemas — revisa Privacidad y seguridad antes de tocar permisos de archivos, cachés o plugins. Una salida de `ls -l` de Unix que parece perfectamente normal no descarta que TCC esté bloqueando silenciosamente el proceso por debajo.
