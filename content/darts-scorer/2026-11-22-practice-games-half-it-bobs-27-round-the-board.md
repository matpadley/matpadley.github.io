---
title: "Three practice games, and the rules I had to pin down"
description: "The scorer now has Half-It, Bob's 27 and Round the Board on a shared shell, with house rules you can switch on screen. 5,274 PC checks pass; none of it has run on hardware yet."
date: 2026-11-22
---

The scorer is no longer just a 501 counter. It now has three practice games, Half-It, Bob's 27 and Round the Board, all built on one shared class. The logic and every screen layout pass 5,274 checks on my PC (up from 3,844 three weeks ago); none of it has run on a real screen yet.

## What I did

**One shell, three rule sets.** The three games all work the same way: you enter a visit, the game checks it, undo takes it back. So I wrote that once as `VisitGame.h` (entry pad, undo, stats, quit, result screen), and each game only supplies its rules. Each game's score is a pure function of the visits recorded so far, which makes undo trivial: forget the last visit and recalculate.

**Half-It.** Nine rounds: 20, 19, 18, 17, 16, 15, any double, any treble, bull. Score what you hit; hit nothing and your total is halved. Every club seems to play it slightly differently, so the house rules are buttons on the players screen rather than my guess:

| Setting | Default | Alternative |
|---|---|---|
| Start score | 40 | 0 |
| Halving | rounded down | rounded up |

**Bob's 27.** Start on 27 and throw at D1, D2 and so on up to D20, then the bull. Each dart that hits adds the double's value; three misses subtract it. Reach 0 or below and you're out. A perfect game is 1,437, and a test checks exactly that number.

**Round the Board.** Start on 1 and work up to 20 with a single (or a double, which jumps further), then hit a double twice, then the bullseye. It is entered dart by dart with Hit / Miss / Double taps, and the LED strip flashes red for a miss, green for a hit and twice for a double.

**A Training page.** Half-It and Bob's 27 live on a Training page off the main menu. A small `GameConfig.h` has one `true`/`false` per game; set one to `false` and it vanishes from the menus.

![Main menu showing 501, Round the Board and Training](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/01-main-menu.jpg)
<!-- PHOTO TODO: Screenshot of the main TFT menu. Until the screen runs on hardware, use a screenshot from the PC layout test. Crop to the screen only. -->
*The main menu: 501, Round the Board and Training.*

## What went wrong or surprised me

**Bob's 27 entry was backwards.** My first version asked "darts hit?" with four buttons, 0 to 3. Tapping the wrong one is easy, and undo couldn't take back half a visit. It now asks dart by dart, "Dart 1 of 3", with big Hit and Miss buttons, and undo removes one dart before it removes a whole visit. A test now pins that behaviour.

![Bob's 27 entry screen with large Hit and Miss buttons](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/02-bobs-27-hit-miss.jpg)
<!-- PHOTO TODO: The Hit/Miss screen, ideally on the real TFT at arm's length, with glare reduced. Before hardware: PC layout screenshot. -->
*Hit and Miss, one tap per dart.*

**Round the Board has more than one rulebook.** The first version needed one double on the way out; the rules I settled on need it twice, not necessarily in a row. I wrote the rule into a comment at the top of the game, and then into a test, so I can't forget which one I chose.

**Half-It rounding is a real argument.** Halving 41 gives 20 or 21 depending on who taught you. Rather than pick, I made it a setting.

## What's next

Same step as always, and it's the important one: the touch, TFT, round-screen and LED code has not been compiled for the Teensy or run on hardware, so none of these games has been played on the device. Next is a first compile, TFT bring-up on the breadboard, touch calibration and the round screens one at a time. Flash and RAM use are still unmeasured.
