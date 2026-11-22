---
title: "Una pantalla redonda para cada jugador, y un anillo que se vacía"
description: "El marcador de dardos ahora tiene una pantalla táctil en el centro y una pequeña pantalla redonda por jugador, con un anillo que se reduce a medida que baja la puntuación. Todo funciona en mis pruebas en PC; nada ha corrido aún en el hardware."
date: 2026-10-30
---

He quitado el teclado y le he dado a cada jugador su propia pantalla redonda de 1,28 pulgadas. Cada una muestra la puntuación del jugador dentro de un anillo que se vacía a medida que se acerca a cero. Los diseños están probados en mi PC; nada de esto ha corrido todavía en hardware real.

## Qué hice

**Táctil en lugar de teclas.** El TFT de 2,8 pulgadas tiene una capa táctil resistiva, así que el teclado numérico ahora se dibuja en la pantalla y el teclado 4x4 desaparece del montaje. Eso libera mucho cableado. También invierte lo que escribí la última vez, cuando dije que el teclado seguiría siendo la única entrada.

**Una pantalla por jugador.** La pantalla grande ahora se encarga de la configuración, los ajustes de la partida y la entrada de puntuaciones. Las dos pantallas redondas GC9A01 (240x240, izquierda para el Jugador 1, derecha para el Jugador 2) muestran los números que quieres leer desde la línea de tiro: puntuación restante, legs, media de tres dardos, última tanda y una línea para la ruta de cierre o "Needs a double".

**El anillo.** El borde exterior de cada pantalla redonda es un indicador. Empieza lleno en 301 o 501 y se reduce en sentido horario desde las 12 a medida que baja la puntuación. Amarillo significa que ese jugador está en el oche, gris que espera, y verde con el anillo lleno que ha ganado la partida. La cuenta es una línea:

```cpp
int32_t d = (int32_t)v.remaining * 360 / v.start;
```

La biblioteca de pantalla no tiene función de arco, así que dibujo un puntito por grado alrededor del anillo. Así las pantallas redondas solo necesitan una llamada de "dibujar un círculo relleno", y el mismo código de dibujo funciona en el PC.

**Probar el diseño sin pantalla.** Igual que la pantalla principal, las pantallas de jugador dibujan a través de una superficie abstracta, y una versión que graba las llamadas en el PC comprueba que cada caja de texto queda dentro del círculo visible y dentro del anillo, y que nada se solapa. Una pantalla redonda recorta las esquinas, así que un rectángulo que cabe en 240x240 aún puede quedar cortado. La prueba completa informa ahora de 3.823 comprobaciones y 0 fallos.

![Primer plano de una pantalla redonda de jugador con la puntuación dentro de un anillo amarillo](/images/darts-scorer/2026-10-30-a-screen-for-each-player/01-round-screen-ring.jpg)
<!-- PHOTO TODO: Only once the round screen is working: close-up of one round screen mid-leg with the ring partly lit. Shoot straight on, slightly dimmed room, to avoid glare on the glass. Until then, use a screenshot of the PC layout. -->
*La pantalla de un jugador: la puntuación en el centro y los puntos restantes como parte iluminada del anillo.*

## Qué salió mal o me sorprendió

**Dos pantallas, los mismos cables.** Las pantallas redondas solo escuchan, así que pueden compartir los cables de reloj (SCK, pin 13) y de datos (MOSI, pin 11) de la pantalla principal. Cada una tiene su propio pin de selección (CS), que dice "este mensaje es para mí". El módulo también tiene una resistencia pull-down en CS: si un pin CS no se pone en alto al arrancar, las dos pantallas escuchan a la vez. El código pone ambos pines CS en alto nada más empezar `setup()`.

**Pines de reinicio.** Al principio pensé que podían compartir una sola línea de reset. No pueden: la biblioteca reinicia la pantalla al arrancar, así que al arrancar la segunda se borraría la primera. Cada una tiene su propio pin de reset (8 y 22).

**Memoria.** Un lienzo de 240x240 ocupa unos 115 KB. Las dos pantallas lo comparten y se redibujan una tras otra. El Teensy tiene la RAM para eso; el Nano nunca habría podido.

**El voltaje, otra vez.** El anuncio de las pantallas redondas dice alimentación de 3-5 V. Las alimento igualmente con 3,3 V, para que los pines de datos y la alimentación coincidan y nada pueda poner 5 V en un pin del Teensy.

![Placa de pruebas vista desde arriba con el Teensy, el TFT y las dos pantallas redondas cableados](/images/darts-scorer/2026-10-30-a-screen-for-each-player/02-breadboard-three-screens.jpg)
<!-- PHOTO TODO: Whole breadboard from above once wired, with the shared SCK/MOSI "hub" rows visible. Shows how three screens share two wires. Until then, use the updated docs/darts-scorer-v2-breadboard.jpg wiring diagram. -->
*El cableado previsto: tres pantallas que comparten los mismos cables de reloj y datos.*

## Lo siguiente

Ni el código del táctil, ni el del TFT, las pantallas redondas o el zumbador se ha compilado para el Teensy ni ejecutado en hardware. El plan es el mismo, con el táctil añadido: arrancar la pantalla principal con alimentación USB, añadir los cables del táctil y calibrar las cuatro esquinas, y luego añadir las pantallas redondas una a una, empezando por la izquierda. Aún tengo que confirmar que el chip táctil del módulo de 2,8 pulgadas es un XPT2046 cuando llegue, y el precio de las pantallas redondas, que el anuncio no mostraba.
