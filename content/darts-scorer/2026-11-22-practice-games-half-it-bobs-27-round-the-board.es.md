---
title: "Tres juegos de práctica, y las reglas que tuve que fijar"
description: "El marcador ahora tiene Half-It, Bob's 27 y Round the Board sobre una base común, con reglas de la casa que se cambian en pantalla. Pasan 5.274 comprobaciones en PC; nada ha corrido aún en hardware."
date: 2026-11-22
---

El marcador ya no es solo un contador de 501. Ahora tiene tres juegos de práctica, Half-It, Bob's 27 y Round the Board, todos construidos sobre una misma clase. La lógica y todos los diseños de pantalla pasan 5.274 comprobaciones en mi PC (frente a 3.844 hace tres semanas); nada ha corrido todavía en una pantalla real.

## Qué hice

**Una base, tres juegos de reglas.** Los tres juegos funcionan igual: introduces una ronda, el juego la comprueba, deshacer la quita. Así que lo escribí una sola vez en `VisitGame.h` (teclado de entrada, deshacer, estadísticas, salir, pantalla de resultado), y cada juego solo aporta sus reglas. La puntuación de cada juego es una función pura de las rondas registradas, lo que hace trivial deshacer: olvidas la última ronda y recalculas.

**Half-It.** Nueve rondas: 20, 19, 18, 17, 16, 15, cualquier doble, cualquier triple, diana. Sumas lo que aciertas; si no aciertas nada, tu total se divide a la mitad. Cada club lo juega un poco distinto, así que las reglas de la casa son botones en la pantalla de jugadores en vez de una decisión mía:

| Ajuste | Por defecto | Alternativa |
|---|---|---|
| Puntuación inicial | 40 | 0 |
| División a la mitad | redondeo hacia abajo | redondeo hacia arriba |

**Bob's 27.** Empiezas con 27 y tiras a D1, D2 y así hasta D20, luego la diana. Cada dardo que acierta suma el valor del doble; tres fallos lo restan. Si llegas a 0 o menos, quedas eliminado. Una partida perfecta son 1.437, y una prueba comprueba exactamente ese número.

**Round the Board.** Empiezas en 1 y subes hasta 20 con un simple (o un doble, que avanza más), luego aciertas un doble dos veces, luego la diana. Se introduce dardo a dardo con los botones Acierto / Fallo / Doble, y la tira de LED parpadea en rojo con un fallo, en verde con un acierto y dos veces con un doble.

**Una página de Entrenamiento.** Half-It y Bob's 27 viven en una página de Entrenamiento desde el menú principal. Un pequeño `GameConfig.h` tiene un `true`/`false` por juego; pon `false` y el juego desaparece de los menús.

![Menú principal con 501, Round the Board y Training](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/01-main-menu.jpg)
<!-- PHOTO TODO: Screenshot of the main TFT menu. Until the screen runs on hardware, use a screenshot from the PC layout test. Crop to the screen only. -->
*El menú principal: 501, Round the Board y Training.*

## Qué salió mal o me sorprendió

**La entrada de Bob's 27 estaba al revés.** Mi primera versión preguntaba «¿dardos acertados?» con cuatro botones, del 0 al 3. Es fácil pulsar el equivocado, y deshacer no podía quitar media ronda. Ahora pregunta dardo a dardo, «Dart 1 of 3», con botones grandes Hit y Miss, y deshacer quita un dardo antes de quitar una ronda entera. Una prueba fija ahora ese comportamiento.

![Pantalla de entrada de Bob's 27 con botones grandes Hit y Miss](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/02-bobs-27-hit-miss.jpg)
<!-- PHOTO TODO: The Hit/Miss screen, ideally on the real TFT at arm's length, with glare reduced. Before hardware: PC layout screenshot. -->
*Hit y Miss, una pulsación por dardo.*

**Round the Board tiene más de un reglamento.** La primera versión pedía un solo doble para salir; las reglas que fijé piden dos, no necesariamente seguidos. Escribí la regla en un comentario al inicio del juego, y luego en una prueba, para no olvidar cuál elegí.

**El redondeo de Half-It es un debate real.** La mitad de 41 da 20 o 21 según quién te enseñó el juego. En lugar de elegir, lo convertí en un ajuste.

## Lo que sigue

El mismo paso de siempre, y el importante: el código del táctil, de la pantalla TFT, de las pantallas redondas y de los LED no se ha compilado para el Teensy ni se ha ejecutado en hardware, así que ninguno de estos juegos se ha jugado en el dispositivo. Después viene una primera compilación, la puesta en marcha del TFT en la placa de pruebas, la calibración del táctil y las pantallas redondas una a una. El uso de flash y RAM sigue sin medirse.
