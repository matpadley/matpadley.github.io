---
title: "A round screen for each player, and a ring that counts down"
description: "The darts scorer now has a touchscreen in the middle and a small round screen for each player, with a ring around the edge that shrinks as the score falls. It all works in my PC tests; none of it has run on hardware yet."
date: 2026-10-30
---

I've dropped the keypad and given each player their own 1.28in round screen. Each one shows that player's score inside a ring that empties as they get closer to zero. The layouts are tested on my PC; none of this has run on real hardware yet.

**Touch instead of keys.** The 2.8in TFT has a resistive touch layer, so the number pad is now drawn on the screen and the 4x4 keypad is gone from the build. That frees up a lot of wiring. It also reverses what I wrote last time, when I said the keypad would stay the only input.

**One screen per player.** The big screen now handles setup, match settings and entering scores. The two round GC9A01 screens (240x240, left for Player 1, right for Player 2) show the numbers you actually want to read from the oche: remaining score, legs, three-dart average, last visit, and one line for the checkout route or "Needs a double".

**The ring.** The outer edge of each round screen is a gauge. It starts full at 301 or 501 and shrinks clockwise from 12 o'clock as the score drops. Yellow means that player is on the oche, grey means they're waiting, and green with a full ring means they've won the match. The maths is one line:

```cpp
int32_t d = (int32_t)v.remaining * 360 / v.start;
```

The display library has no arc function, so I draw one small dot per degree around the ring. That means the round screens need only a "draw a filled circle" call, and the same drawing code works on the PC.

**Testing the layout without a screen.** Like the main screen, the player screens draw through an abstract surface, and a recording version on the PC checks that every text box sits inside the visible circle and inside the ring, and that nothing overlaps. A round screen clips its corners, so a rectangle that fits 240x240 can still be cut off. The full test run currently reports 3,823 checks and 0 failures.

![Close-up of a round player screen showing the score inside a yellow ring](/images/darts-scorer/2026-10-30-a-screen-for-each-player/01-round-screen-ring.jpg)
<!-- PHOTO TODO: Only once the round screen is working: close-up of one round screen mid-leg with the ring partly lit. Shoot straight on, slightly dimmed room, to avoid glare on the glass. Until then, use a screenshot of the PC layout. -->
*A player's screen: score in the middle, remaining points as the lit part of the ring.*

## What went wrong or surprised me

**Two screens, one set of wires.** The round screens only listen, so they can share the main screen's clock (SCK, pin 13) and data (MOSI, pin 11) wires. Each has its own chip-select (CS) pin, which says "this message is for me". The module also has a pull-down resistor on CS, so if a CS pin isn't driven high at start-up, both screens try to listen at once. The code sets both CS pins high first thing in `setup()`.

**Reset pins.** I first thought they could share one reset line. They can't: the library resets the display when it starts, so the second screen starting would blank the first. Each gets its own reset pin (8 and 22).

**Memory.** One 240x240 canvas is about 115 KB. Both screens share it, redrawing one after the other. The Teensy has the RAM for it; the Nano never could have.

**Voltage again.** The round-screen listing says 3-5V supply. I'm powering both from the 3.3V rail anyway, so the data pins and the supply agree and nothing can put 5V on a Teensy pin.

![Breadboard from above with the Teensy, the TFT and the two round screens wired](/images/darts-scorer/2026-10-30-a-screen-for-each-player/02-breadboard-three-screens.jpg)
<!-- PHOTO TODO: Whole breadboard from above once wired, with the shared SCK/MOSI "hub" rows visible. Shows how three screens share two wires. Until then, use the updated docs/darts-scorer-v2-breadboard.jpg wiring diagram. -->
*The planned wiring: three screens sharing the same clock and data wires.*

## What's next

None of the touch, TFT, round-screen or buzzer code has been compiled for the Teensy or run on hardware. The plan is the same as before, with touch added: bring up the main screen on USB power, add the touch wires and calibrate the four corners, then add the round screens one at a time, left first. I still need to confirm the touch chip on the 2.8in module is an XPT2046 when it arrives, and the price of the round screens, which the listing didn't show.
