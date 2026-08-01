---
title: "Tres Suposiciones Equivocadas en una Habilidad de Publicación"
date: 2026-08-01T11:30:00+01:00
draft: false
description: "La herramienta que convierte este registro de ingeniería en artículos suponía que la sección era solo en inglés, que una entrada de registro de trabajo sirve como cuerpo de artículo y que una entrada equivale a un artículo. Las tres eran falsas, y corregirlas muestra dónde debe parar un script y empezar el criterio."
summary: "La herramienta que convierte este registro de ingeniería en artículos suponía que la sección era solo en inglés, que una entrada de registro de trabajo sirve como cuerpo de artículo y que una entrada equivale a un artículo. Las tres eran falsas, y corregirlas muestra dónde debe parar un script y empezar el criterio."
tags:
  - club-monitor
  - tooling
  - python
  - hugo
  - claude-code
  - writing
source:
  - "2026-07-31-1030-publish-progress-skill-adds-fr-es-translations.md"
  - "2026-07-31-1115-publish-progress-skill-reader-facing-articles.md"
  - "2026-08-01-1130-publish-progress-skill-multi-source-articles.md"
---

Estos artículos se generan a partir de un registro de ingeniería. Cada cambio en Club Monitor escribe una entrada fechada en `progress/`, y una pequeña habilidad convierte esas entradas en las publicaciones que estás leyendo, con un ayudante en Python que se ocupa de las partes deterministas —fechas, front matter, nombres de archivo— mientras los criterios quedan en manos del modelo.

La primera versión funcionaba, y luego resultó que tres cosas distintas de ella estaban mal. Cada arreglo es pequeño; juntos ilustran bastante bien dónde está en realidad la frontera entre un script y el juicio de un modelo.

## «Solo en inglés» nunca fue una restricción

La documentación de la habilidad decía que la sección ClubMonitor era solo en inglés. Esa era una descripción exacta de los ocho artículos que existían cuando se escribió, y no un hecho sobre el sitio. Las demás secciones del sitio ya publican archivos `.fr.md` y `.es.md` junto a cada artículo en inglés: mismo slug, front matter y cuerpo traducidos, y las etiquetas inglesas en kebab-case tal cual.

Copiar una convención establecida es más seguro que inventar una nueva, así que la sección ClubMonitor la sigue ahora. Los metadatos de cada artículo ganaron un objeto `translations` opcional con entradas `fr` y `es`, cada una con título, descripción y cuerpo. El script generalizó su constructor de front matter para aceptar un título y una descripción explícitos conservando `date`, `tags` y `source` de los metadatos base, de forma que el artículo inglés y sus traducciones comparten una única forma.

Cabe destacar que la traducción en sí quedó *fuera* del script. Requiere el mismo criterio que ya exigen el título y la descripción en inglés, así que vive en los metadatos que escribe el modelo. El script se limita deliberadamente a aquello en lo que un script es realmente mejor.

Ese cambio tuvo una consecuencia poco evidente. El comando `status` funciona releyendo la clave `source:` de los artículos publicados para decidir qué queda por escribir, y las traducciones llevan el mismo `source` que su original en inglés. Sin omitir los `*.fr.md` y `*.es.md` al construir ese mapa, el resultado dependía del orden del glob.

## El cuerpo era una transcripción, no un artículo

El segundo problema era más de fondo: el script publicaba el propio texto de la entrada de progreso como cuerpo del artículo.

Las entradas de progreso se escriben para el repositorio. Empiezan con «Qué cambió», dicen cosas como «Continuación de la pregunta sobre…» y «Decisión: mantenerlo anónimo», y enumeran cada archivo tocado. Todo eso es correcto para un registro de trabajo y equivocado para algo que pueda leer un desconocido. El resultado era técnicamente exacto y aburrido.

Así que los metadatos llevan ahora un `body` explícito: un artículo en inglés pulido, escrito por el modelo tras leer la entrada, que el script publica en lugar del texto en bruto. Ese mismo cuerpo es el que se traduce, de modo que los artículos en francés y español son traducciones del artículo y no del registro. Las instrucciones de la habilidad piden prosa que se lea como texto publicado, y nombran los tics concretos que hay que evitar. Una prueba de regresión cubre ese comportamiento.

## Un artículo, varias entradas

La última suposición en caer fue «una entrada, un artículo».

Se sostiene cuando las entradas se bastan solas. Falla gravemente con el trabajo que llegó por fases: el despliegue multilingüe descrito en otro lugar de esta sección aterrizó como siete entradas de progreso más un plan, y publicar ocho artículos flacos se habría leído mucho peor que una sola pieza que cuenta toda la historia.

Por eso `source` en los metadatos puede ser ahora un solo nombre de archivo, como antes, o una lista:

```json
{"source": ["2026-08-01-1200-thing.md", "2026-08-01-1600-thing-part-two.md"],
 "slug": "thing", "title": "...", "description": "...", "body": "..."}
```

Todo lo demás se desprende de ahí. El front matter escribe `source` como un escalar entrecomillado para una entrada y como una lista YAML para varias, de modo que los artículos existentes quedan intactos y volver a ejecutar `status` contra el sitio real da la misma respuesta que antes. `status` asigna cada entrada listada al artículo que la cubre, así que ninguna se vuelve a ofrecer, y ahora sugiere —cuando hay más de una entrada pendiente— que las entradas relacionadas pueden compartir artículo. La fecha del artículo es la más reciente de sus fuentes, de forma que una pieza combinada se ordena como trabajo reciente y no como el día en que aterrizó la primera fase.

Una regla se impone en lugar de sugerirse: `body` es **obligatorio** cuando hay más de una fuente. El respaldo de fuente única que extrae el texto del archivo de progreso no tiene un equivalente sensato para varias entradas, y empalmar registros uno tras otro es exactamente el resultado que toda la habilidad existe para evitar.

Releer la clave `source` exigió un pequeño cuidado. El patrón de elemento de lista tiene que exigir un espacio tras el guion, o se pasa de largo del `---` de cierre del front matter y lee el delimitador como una fuente más, malformada.

## Adónde fue el criterio

La decisión de agrupar no puede mecanizarse, así que se convirtió en una guía explícita: un paso entre leer las entradas y escribir los metadatos. Agruparlas cuando el usuario nombra archivos concretos, o cuando la lectura revela una sola historia contada a lo largo de varios registros. Mantenerlas separadas cuando el trabajo es genuinamente inconexo y solo coincide en el tiempo. Cuando el usuario nombra los archivos, publicar exactamente esos y no colar otros sin decirlo. Y para un artículo combinado, escribir una pieza continua —encontrar el hilo que atraviesa las entradas— en vez de los registros grapados uno tras otro bajo un encabezado cada uno, sin perder la sustancia de ninguna entrada listada como fuente.

Todo ello se probó contra un directorio de contenido desechable antes de acercarse al sitio real: un artículo de dos fuentes y otro de fuente única escritos en una misma ejecución, `status` informando de las tres entradas como publicadas, ambas rutas de error, y `status` contra el sitio real confirmando que los nueve artículos existentes con `source` escalar se resuelven exactamente igual que antes.
