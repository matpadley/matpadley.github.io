---
title: "Why my darts scorer is moving from a Nano to a Teensy"
description: "My Arduino Nano darts scorer is running short of RAM, so version 2 moves to a Teensy 4.0 and a colour screen. The rules are built and tested on a PC; the hardware is next."
date: 2026-10-27
---

My Arduino Nano darts scorer works, but it has run out of room to grow. Version 2 swaps in a Teensy 4.0 and a 2.8in colour screen, and I've built and tested the game rules on my PC before touching any hardware.

Version 1 is a Nano with a 20x4 character LCD and a 4x4 keypad. It scores 501 for one to four players and fits comfortably in flash (about 15.5 KB of 32 KB, 47%). RAM is the problem: it already uses about 72% of the Nano's 2 KB, and I want more than a 20x4 grid can show: 301 as well as 501, match settings, a visit history for each player and checkout routes.

So version 2 changes the hardware:

- **Board:** Teensy 4.0 (600 MHz, 1 MB flash, roughly 1 MB RAM).
- **Display:** 2.8in ILI9341 SPI screen, 320x240 pixels. I'm ignoring any touch layer; I want the keypad to stay the only input.
- **Players:** two fixed players for now, no names, nothing saved.
- **Rules:** 301 and 501, first-to or best-of legs, straight-in or double-in, single-out or double-out, and up to three checkout routes ranked fewest darts first.

As a C# developer, the part I'm most comfortable with is the testable bit, so I did that first. The game rules never touch hardware: screens are drawn through an abstract `Ui`, and on the PC a recording version of it checks that every screen fits 320x240 and that no text overlaps. So far that covers the rules, the checkout routes and every screen layout, all tested on the PC.

![The planned parts laid out on a bench with a ruler for scale](/images/darts-scorer/2026-10-27-nano-to-teensy/01-parts-with-ruler.jpg)
<!-- PHOTO TODO: Teensy 4.0, TFT, keypad, breadboard and jumper wires laid flat on a plain surface with a ruler beside them, shot from above in daylight. Gives the reader a sense of scale before any wiring. -->
*The version 2 parts, with a ruler for scale.*

I priced the parts from UK suppliers on 27 October 2026: the Teensy 4.0 with headers is £25.80 at The Pi Hut, and the whole kit comes to about £43 before the display and buzzer, or about £60 with both. The display price is an estimate (£10-20) that I'll confirm before ordering.

## What went wrong or surprised me

**Voltage.** The Nano runs at 5V; the Teensy runs at 3.3V and its pins are *not* 5V tolerant. One wrong wire can kill it permanently. My rules for the build: wire with USB unplugged, power the screen and its backlight from the 3.3V pin (the backlight draws 50-100 mA, far too much for a signal pin), and check the display listing says 3.3V logic.

**The screen buffer.** I draw each screen into an in-memory canvas and send it to the display in one go, which avoids flicker. At 320x240x2 bytes that's about 150 KB. On the Nano it would be impossible; on the Teensy it's a small slice of the RAM.

**Double-in with visit totals.** The scorer takes a visit total, not individual darts. Under double-in, only the darts from the first double onwards count, so you type just those points (or `B` if no double landed). It's a small rule, but it shaped the input screens.

**Best-of.** I'm treating best-of as odd numbers only (best of 5 means first to 3). That's a working assumption and I haven't confirmed it against real match rules yet.

![A terminal showing the host tests passing](/images/darts-scorer/2026-10-27-nano-to-teensy/02-host-test-output.png)
<!-- PHOTO TODO: Screenshot of the PC test run for tests/test_main.cpp, cropped to the summary lines. Shows the reader the logic is tested without hardware. -->
*The rules, checkout routes and screen layouts all pass on the PC.*

## What's next

Nothing has run on the real keypad, screen or buzzer yet. The next step is bringing up the display from USB power on a breadboard, then adding the keypad, then the buzzer, then playing a full leg and recording the real flash and RAM figures. Battery power (3xAAA, a 5V boost module and a diode) comes later, and only after I've read PJRC's Teensy 4.0 power page about using batteries and USB together.

![The planned breadboard wiring sketch for the Teensy, TFT and keypad](/images/darts-scorer/2026-10-27-nano-to-teensy/03-wiring-sketch.png)
<!-- PHOTO TODO: Photo or screenshot of the wiring layout sketch (Teensy in the centre, TFT on SPI pins 13/11/10/14/15, keypad on 9-6 and 5-2). Replace with a photo of the real breadboard once wired. -->
*The planned wiring, before anything is plugged in.*
