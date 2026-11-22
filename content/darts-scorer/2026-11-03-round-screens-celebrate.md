---
title: "Teaching the round screens to celebrate a 180"
description: "The player screens now flash for a ton or a 180, turn blue when you're on a checkout and flash a nine-dart leg. It all passes my PC tests; none of it has run on hardware yet."
date: 2026-11-03
---

This week the round player screens got personality. They flash red and green for a 180, turn blue when a player is on a checkout, and flash inverse colours for a nine-dart leg. The logic and layouts pass 3,844 checks on my PC; none of it has run on a real screen yet.

**Effects driven by the game, not the display.** The game class works out what just happened and sets flags on the view it hands to each round screen: `ton`, `oneEighty`, `nineDart`, `onCheckout`. The drawing code only reacts to the flags, so every rule is testable on a PC without a screen. A visit of 100-179 counts as a ton, exactly 180 as a 180, and a nine-dart leg is a leg won in three scoring visits.

**What each effect does.**

| Event | Round screen |
|---|---|
| Visit of 100-179 | Ring and score flash red/green once |
| 180 | Same flash, twice |
| Leg won in nine darts | Three inverse-colour flashes |
| Player on a checkout | Ring turns blue, score turns green |
| Match starts | "GAME ON" on both screens, then the dartboard |

**All the tuning in two small files.** `FaceColours.h` holds every colour and `FaceTimings.h` holds every flash count and duration, so restyling is a one-line change:

```cpp
const uint8_t  OneEightyFlashes = 2;   // red/green flashes on a 180
const uint16_t OneEightyMs      = 130; // each red / green phase
const uint8_t  TonFlashes       = 1;   // same flash, once, for 100-179
```

**Real fonts.** Text was drawn with the display library's built-in blocky font. A small helper now picks the largest bold font that fits each text box and centres it. The boxes are unchanged, so the layout tests still hold. The checkout hint scales the same way (size 3, 2 or 1, whichever fits inside the ring), and "Legs" and "Avg" are separate items in yellow and blue.

**A start-up screen.** The main TFT shows a bordered "DARTS SCORER" title for 1.8 seconds before the menu.

**A board that fits the case.** I also drew the soldered-board layout for the 3D-printed case. The case leaves about 10.6 mm of depth behind the screens, so the Teensy is soldered straight to a perfboard rather than sitting in sockets, which would have been about 14 mm tall. A script checks the drawn wiring against the pin constants in the sketch and refuses to draw if they differ.

![Wiring diagram for the breadboard build: Teensy 4.0, the 2.8in TFT with touch, two round screens and the buzzer](/images/darts-scorer/2026-11-03-round-screens-celebrate/03-wiring-breadboard.jpg)
*The breadboard wiring I'll build from first. The three screens share the clock and data wires; each has its own chip-select.*

![Wiring diagram for the soldered perfboard, fitted to the case: Teensy, headers, buzzer pads and 28 wires](/images/darts-scorer/2026-11-03-round-screens-celebrate/04-wiring-soldered-board.jpg)
*The soldered version: the same pins, point-to-point wire on the underside of a perfboard cut to fit the case.*

![Round player screen mid-flash after a 180, ring red and score green](/images/darts-scorer/2026-11-03-round-screens-celebrate/01-180-flash.jpg)
<!-- PHOTO TODO: Only once the round screen runs on hardware: a still of the 180 flash. Room lights dimmed, camera straight on, shutter around 1/60s so the colour isn't half-faded. Until then, use a screenshot of the PC layout. -->
*A 180: the ring and score flash red and green, twice.*

## What went wrong or surprised me

**Flashes block everything.** The simplest way to flash is `delay()`, and that means the Teensy ignores touch while it plays. A 180 takes about half a second (2 flashes × 2 phases × 130 ms), the nine-dart effect a little under a second, and "GAME ON" 1.2 seconds. That's fine for a darts game, since nobody taps during a celebration, but it's a shortcut, and I'd need a timer-based version if the effects ever got longer.

**Nine darts is inferred, not counted.** The scorer takes visit totals, not individual darts, so it can't see the darts. It assumes a leg won in exactly three scoring visits is nine darts, which holds as long as each visit is three darts. It's a deliberate simplification, not a measurement.

![Perfboard with the Teensy soldered in place, held beside the front shell for fit](/images/darts-scorer/2026-11-03-round-screens-celebrate/02-board-in-case.jpg)
<!-- PHOTO TODO: Once the board is built: perfboard next to the open front shell to show the depth problem and the notch for USB. Include a ruler for scale. Until then, use docs/darts-scorer-v2-soldered-board.jpg. -->
*The planned board: the Teensy soldered flat so everything fits behind the screens.*

## What's next

Still the same step as before, and it's the one that matters: nothing here (touch, TFT, round screens, buzzer, the splash and effects) has been compiled for the Teensy or run on hardware. Next is a first compile, then TFT bring-up from USB power on the breadboard, touch calibration, and the round screens one at a time. Flash and RAM use is still unmeasured until that first compile.
