---
title: "Enseñar a las pantallas redondas a celebrar un 180"
description: "Las pantallas de los jugadores ahora parpadean con un ton o un 180, se ponen azules cuando se está en un checkout y parpadean en una manga de nueve dardos. Todo pasa mis pruebas en PC; nada ha corrido aún en el hardware."
date: 2026-11-03
---

Esta semana las pantallas redondas de los jugadores han ganado personalidad. Parpadean en rojo y verde con un 180, se ponen azules cuando un jugador está en un checkout y parpadean con colores invertidos en una manga de nueve dardos. La lógica y los diseños pasan 3.844 comprobaciones en mi PC; nada ha corrido todavía en una pantalla real.

**Efectos dirigidos por el juego, no por la pantalla.** La clase del juego calcula qué acaba de pasar y activa indicadores en la vista que entrega a cada pantalla redonda: `ton`, `oneEighty`, `nineDart`, `onCheckout`. El código de dibujo solo reacciona a esos indicadores, así que cada regla se prueba en un PC sin pantalla. Una visita de 100 a 179 cuenta como ton, exactamente 180 como 180, y una manga de nueve dardos es una manga ganada en tres visitas con puntuación.

**Qué hace cada efecto.**

| Suceso | Pantalla redonda |
|---|---|
| Visita de 100 a 179 | El anillo y la puntuación parpadean una vez en rojo/verde |
| 180 | El mismo parpadeo, dos veces |
| Manga ganada en nueve dardos | Tres parpadeos en colores invertidos |
| Jugador en un checkout | El anillo se pone azul y la puntuación verde |
| Empieza el partido | «GAME ON» en ambas pantallas y luego la diana |

**Todo el ajuste en dos archivos pequeños.** `FaceColours.h` contiene todos los colores y `FaceTimings.h` todos los números y duraciones de los parpadeos; cambiar el estilo es cuestión de una línea:

```cpp
const uint8_t  OneEightyFlashes = 2;   // red/green flashes on a 180
const uint16_t OneEightyMs      = 130; // each red / green phase
const uint8_t  TonFlashes       = 1;   // same flash, once, for 100-179
```

**Fuentes tipográficas de verdad.** El texto se dibujaba con la fuente integrada, angulosa, de la biblioteca de la pantalla. Ahora una pequeña utilidad elige la fuente en negrita más grande que cabe en cada cuadro de texto y la centra. Los cuadros no han cambiado, así que las pruebas de diseño siguen valiendo. La indicación de checkout se escala igual (tamaño 3, 2 o 1, el que quepa dentro del anillo), y «Legs» y «Avg» son elementos separados, en amarillo y azul.

**Una pantalla de inicio.** El TFT principal muestra un título enmarcado «DARTS SCORER» durante 1,8 segundos antes del menú.

**Una placa que cabe en la caja.** También dibujé la placa soldada para la caja impresa en 3D. La caja deja unos 10,6 mm de profundidad detrás de las pantallas, así que la Teensy va soldada directamente a una placa perforada en lugar de ir en zócalos, que habrían sumado unos 14 mm. Un script compara el cableado dibujado con las constantes de pines del sketch y se niega a dibujar si difieren.

![Esquema de cableado de la versión en protoboard: Teensy 4.0, TFT de 2,8 pulgadas con táctil, dos pantallas redondas y zumbador](/images/darts-scorer/2026-11-03-round-screens-celebrate/03-wiring-breadboard.jpg)
*El cableado en protoboard con el que empezaré. Las tres pantallas comparten los cables de reloj y datos; cada una tiene su propio chip-select (CS).*

![Esquema de cableado de la placa perforada soldada, ajustada a la caja: Teensy, cabeceras, pads del zumbador y 28 cables](/images/darts-scorer/2026-11-03-round-screens-celebrate/04-wiring-soldered-board.jpg)
*La versión soldada: los mismos pines, con cable punto a punto bajo una placa perforada cortada para la caja.*

![Pantalla redonda de un jugador en pleno parpadeo tras un 180, anillo rojo y puntuación verde](/images/darts-scorer/2026-11-03-round-screens-celebrate/01-180-flash.jpg)
<!-- PHOTO TODO: Only once the round screen runs on hardware: a still of the 180 flash. Room lights dimmed, camera straight on, shutter around 1/60s so the colour isn't half-faded. Until then, use a screenshot of the PC layout. -->
*Un 180: el anillo y la puntuación parpadean en rojo y verde, dos veces.*

## Qué salió mal o me sorprendió

**Los parpadeos bloquean todo.** La forma más simple de parpadear es `delay()`, lo que significa que la Teensy ignora el táctil mientras dura el efecto. Un 180 dura aproximadamente medio segundo (2 parpadeos × 2 fases × 130 ms), el efecto de nueve dardos algo menos de un segundo y «GAME ON» 1,2 segundos. Para un juego de dardos es aceptable, nadie toca la pantalla durante una celebración, pero es un atajo, y haría falta una versión basada en temporizador si los efectos se alargaran.

**Los nueve dardos se deducen, no se cuentan.** El marcador recibe totales de visita, no los dardos uno a uno, así que no los ve. Supone que una manga ganada en exactamente tres visitas con puntuación es de nueve dardos, lo cual es cierto mientras cada visita sea de tres dardos. Es una simplificación deliberada, no una medición.

![Placa perforada con la Teensy soldada, junto a la carcasa frontal para comprobar el ajuste](/images/darts-scorer/2026-11-03-round-screens-celebrate/02-board-in-case.jpg)
<!-- PHOTO TODO: Once the board is built: perfboard next to the open front shell to show the depth problem and the notch for USB. Include a ruler for scale. Until then, use docs/darts-scorer-v2-soldered-board.jpg. -->
*La placa prevista: la Teensy soldada plana para que todo quepa detrás de las pantallas.*

## Qué sigue

Sigue siendo el mismo paso, y es el que importa: nada de esto (táctil, TFT, pantallas redondas, zumbador, pantalla de inicio y efectos) se ha compilado para la Teensy ni se ha ejecutado en hardware. Lo siguiente es una primera compilación, luego poner en marcha el TFT con alimentación USB en la protoboard, calibrar el táctil y activar las pantallas redondas una a una. El uso de flash y RAM sigue sin medirse hasta esa primera compilación.
