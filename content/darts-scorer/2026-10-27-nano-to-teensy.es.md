---
title: "Por qué mi marcador de dardos pasa de un Nano a un Teensy"
description: "Mi marcador de dardos con Arduino Nano se queda corto de RAM, así que la versión 2 pasa a un Teensy 4.0 y una pantalla a color. Las reglas están escritas y probadas en el PC; el hardware viene después."
date: 2026-10-27
---

Mi marcador de dardos con Arduino Nano funciona, pero ya no tiene espacio para crecer. La versión 2 cambia a un Teensy 4.0 y a una pantalla a color de 2,8 pulgadas, y he escrito y probado las reglas del juego en mi PC antes de tocar nada de hardware.

La versión 1 es un Nano con una pantalla LCD de 20x4 caracteres y un teclado 4x4. Puntúa 501 para uno a cuatro jugadores y cabe de sobra en la memoria flash (unos 15,5 KB de 32 KB, el 47 %). El problema es la RAM: ya usa alrededor del 72 % de los 2 KB del Nano, y quiero más que una cuadrícula de 20x4: 301 además de 501, ajustes de partida, el historial de turnos de cada jugador y rutas de cierre sugeridas.

Por eso la versión 2 cambia el hardware:

- **Placa:** Teensy 4.0 (600 MHz, 1 MB de flash, aproximadamente 1 MB de RAM).
- **Pantalla:** pantalla SPI ILI9341 de 2,8 pulgadas, 320x240 píxeles. Ignoro la capa táctil si la tiene; quiero que el teclado siga siendo la única entrada.
- **Jugadores:** dos jugadores fijos por ahora, sin nombres, sin nada guardado.
- **Reglas:** 301 y 501, legs de «primero en llegar a» o «mejor de», entrada libre o con doble, salida libre o con doble, y hasta tres rutas de cierre ordenadas de menos a más dardos.

Como desarrollador de C#, la parte con la que me siento más cómodo es la que se puede probar fácilmente, así que la hice primero. Las reglas del juego nunca tocan el hardware: las pantallas se dibujan a través de una `Ui` abstracta, y en el PC una versión que registra las llamadas comprueba que cada pantalla cabe en 320x240 y que ningún texto se solapa. Hasta ahora eso cubre las reglas, las rutas de cierre y el diseño de todas las pantallas, todo probado en el PC.

![Los componentes previstos sobre una mesa de trabajo con una regla como escala](/images/darts-scorer/2026-10-27-nano-to-teensy/01-parts-with-ruler.jpg)
<!-- PHOTO TODO: Teensy 4.0, TFT, keypad, breadboard and jumper wires laid flat on a plain surface with a ruler beside them, shot from above in daylight. Gives the reader a sense of scale before any wiring. -->
*Los componentes de la versión 2, con una regla como referencia de tamaño.*

Comprobé los precios en proveedores del Reino Unido el 27 de octubre de 2026: el Teensy 4.0 con pines cuesta 25,80 £ en The Pi Hut, y el conjunto sale por unas 43 £ sin la pantalla ni el zumbador, o unas 60 £ con ambos. El precio de la pantalla es una estimación (10-20 £) que confirmaré antes de pedirla.

## Qué salió mal o me sorprendió

**El voltaje.** El Nano funciona a 5 V; el Teensy funciona a 3,3 V y sus pines *no* toleran 5 V. Un solo cable equivocado puede estropearlo para siempre. Mis reglas para el montaje: cablear con el USB desconectado, alimentar la pantalla y su retroiluminación desde el pin de 3,3 V (la retroiluminación consume entre 50 y 100 mA, demasiado para un pin de señal) y comprobar que el anuncio de la pantalla indica lógica de 3,3 V.

**El búfer de pantalla.** Dibujo cada pantalla en un lienzo en memoria y lo envío al display de una sola vez, lo que evita el parpadeo. A 320x240x2 bytes son unos 150 KB. En el Nano sería imposible; en el Teensy es una pequeña parte de la RAM.

**Entrada con doble y totales de turno.** El marcador recibe el total del turno, no cada dardo. Con entrada con doble, solo cuentan los dardos a partir del primer doble, así que se escriben solo esos puntos (o `B` si no entró ningún doble). Es una regla pequeña, pero dio forma a las pantallas de entrada.

**Mejor de.** Trato el «mejor de» solo con números impares (mejor de 5 significa ganar 3 legs). Es una suposición de trabajo que aún no he confirmado con las reglas reales de un partido.

![Una terminal mostrando las pruebas del PC superadas](/images/darts-scorer/2026-10-27-nano-to-teensy/02-host-test-output.png)
<!-- PHOTO TODO: Screenshot of the PC test run for tests/test_main.cpp, cropped to the summary lines. Shows the reader the logic is tested without hardware. -->
*Las reglas, las rutas de cierre y el diseño de las pantallas pasan las pruebas en el PC.*

## Lo siguiente

Todavía no ha funcionado nada en el teclado, la pantalla o el zumbador reales. El siguiente paso es poner en marcha la pantalla con alimentación USB en una protoboard, luego añadir el teclado, luego el zumbador, y después jugar un leg completo y anotar las cifras reales de flash y RAM. La alimentación con pilas (3 pilas AAA, un módulo elevador a 5 V y un diodo) vendrá más tarde, y solo después de leer la página de PJRC sobre la alimentación del Teensy 4.0 y el uso simultáneo de pilas y USB.

![El esquema de cableado previsto en la protoboard para el Teensy, la pantalla y el teclado](/images/darts-scorer/2026-10-27-nano-to-teensy/03-wiring-sketch.png)
<!-- PHOTO TODO: Photo or screenshot of the wiring layout sketch (Teensy in the centre, TFT on SPI pins 13/11/10/14/15, keypad on 9-6 and 5-2). Replace with a photo of the real breadboard once wired. -->
*El cableado previsto, antes de conectar nada.*
