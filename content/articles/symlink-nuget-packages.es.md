---
title: "Libera tu caché de NuGet: mover .nuget y .packages a otro volumen"
date: 2026-08-18
draft: false
description: "Tu caché de .nuget se está comiendo el disco del Mac sin que te enteres. Muévela a un SSD externo, deja un enlace simbólico detrás y recupera el espacio sin perder un solo paquete en caché."
tags:
  - dotnet
  - nuget
  - macos
  - developer-tools
---

Si alguna vez has mirado el desglose de almacenamiento de tu Mac preguntándote por qué los «Datos del sistema» parecen querer adueñarse del disco entero, hay bastantes probabilidades de que tu caché `.nuget` y tu carpeta `.packages` se estén dando un festín en segundo plano. Cada restauración, cada proyecto, cada «venga, probemos rápido este paquete» añade un poco más al montón — y nunca parece encoger por sí solo.

La buena noticia: no tienes que resignarte, ni renunciar a tu caché global de paquetes para recuperar el espacio. Solo tienes que reubicarla — y dejar un enlace simbólico detrás para que .NET no se entere de nada.

## Por qué merece la pena

La carpeta `~/.nuget/packages` (y a menudo también `~/.packages`, según tu configuración) acumula *cada versión de cada paquete* que hayas restaurado alguna vez, en *cada proyecto* en el que hayas trabajado. Multiplica eso por unos cuantos años de desarrollo en C#, un puñado de soluciones con grafos de dependencias ligeramente distintos y algún que otro `dotnet restore` demasiado entusiasta, y no es raro encontrarse decenas de gigabytes ahí — en silencio, invisibles, para siempre.

Sacarla de tu disco interno principal te devuelve ese espacio al instante, sin borrar un solo paquete en caché ni tocar el rendimiento de tus compilaciones.

## El traslado

**1. Cierra todo lo que la esté usando.** Cierra tu IDE (Rider, VS Code, lo que uses) para que nada esté a mitad de una restauración mientras haces esto.

**2. Mueve la carpeta a su nuevo hogar:**
```bash
mv ~/.nuget/packages /Volumes/TuSSD/nuget-packages
```

**3. Deja un enlace simbólico donde .NET espera encontrarla:**
```bash
ln -s /Volumes/TuSSD/nuget-packages ~/.nuget/packages
```

Repite esos dos pasos con `~/.packages` si lo usas. Las herramientas de .NET leen y escriben en `~/.nuget/packages` por ruta — no tienen ni idea (ni motivo para importarles) de que los archivos reales viven ahora en otro sitio.

**4. Comprueba que ha funcionado:**
```bash
dotnet restore
```
Si restaura sin problemas y `ls -la ~/.nuget` muestra la flechita junto a `packages`, ya está.

## Pero ¿*dónde* debería estar ese «otro volumen»?

Aquí viene lo que es fácil hacer mal: técnicamente sirve cualquier volumen montado — un disco duro externo, una unidad de red, un USB polvoriento que encontraste en un cajón. Pero no todos funcionan *bien*.

Ponlo en un SSD. Idealmente uno externo conectado por USB-C/Thunderbolt, o mejor aún, un SSD secundario interno si tu equipo lo permite.

Esto importa más de lo que parece: las restauraciones de NuGet implican *miles* de lecturas de archivos pequeños, no un puñado de lecturas secuenciales grandes. Esa es justo la carga de trabajo que peor llevan los discos mecánicos, y justo la que los SSD se comen con patatas. Pon tu caché de paquetes en un disco mecánico y cambiarás espacio en disco por tiempos de restauración: cada `dotnet restore`, cada reindexado del IDE, cada compilación local se sentirá como avanzar por el barro.

Un SSD mantiene rápidas las restauraciones, evita que tu IDE se atasque buscando archivos y aun así le devuelve el espacio a tu disco principal. De verdad, lo mejor de ambos mundos — los NVMe externos baratos hacen que hoy en día sea una decisión fácil.

## Un pequeño detalle a tener en cuenta

Si algún día desmontas o desconectas ese SSD externo, `dotnet restore` fallará (el enlace simbólico apuntará a la nada, comprensiblemente confundido). No es grave si el disco está siempre conectado, pero conviene recordarlo antes de desenchufarlo e intentar compilar acto seguido.

Y ya está — el mismo truco que para mover cualquier carpeta de macOS con un enlace simbólico, solo que apuntado directamente a las partes de tu cadena de herramientas de `.NET` que más espacio acaparan. Tu disco interno te lo agradecerá.
