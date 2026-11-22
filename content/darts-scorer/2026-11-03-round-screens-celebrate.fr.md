---
title: "Apprendre aux écrans ronds à fêter un 180"
description: "Les écrans des joueurs clignotent maintenant pour un ton ou un 180, passent au bleu quand on est sur un checkout et clignotent pour une manche en neuf fléchettes. Tout passe mes tests sur PC ; rien n'a encore tourné sur le matériel."
date: 2026-11-03
---

Cette semaine, les écrans ronds des joueurs ont pris de la personnalité. Ils clignotent en rouge et vert pour un 180, passent au bleu quand un joueur est sur un checkout, et clignotent en couleurs inversées pour une manche en neuf fléchettes. La logique et les affichages passent 3 844 vérifications sur mon PC ; rien n'a encore tourné sur un vrai écran.

**Des effets pilotés par le jeu, pas par l'affichage.** La classe du jeu détermine ce qui vient de se passer et active des indicateurs sur la vue qu'elle transmet à chaque écran rond : `ton`, `oneEighty`, `nineDart`, `onCheckout`. Le code de dessin ne fait que réagir à ces indicateurs, donc chaque règle se teste sur PC sans écran. Une volée de 100 à 179 compte comme un ton, exactement 180 comme un 180, et une manche en neuf fléchettes est une manche gagnée en trois volées marquantes.

**Ce que fait chaque effet.**

| Événement | Écran rond |
|---|---|
| Volée de 100 à 179 | L'anneau et le score clignotent une fois en rouge/vert |
| 180 | Même clignotement, deux fois |
| Manche gagnée en neuf fléchettes | Trois clignotements en couleurs inversées |
| Joueur sur un checkout | L'anneau passe au bleu, le score au vert |
| Début de match | « GAME ON » sur les deux écrans, puis la cible |

**Tout le réglage dans deux petits fichiers.** `FaceColours.h` contient toutes les couleurs et `FaceTimings.h` tous les nombres et durées de clignotements ; restyler se fait en une ligne :

```cpp
const uint8_t  OneEightyFlashes = 2;   // red/green flashes on a 180
const uint16_t OneEightyMs      = 130; // each red / green phase
const uint8_t  TonFlashes       = 1;   // same flash, once, for 100-179
```

**De vraies polices.** Le texte était dessiné avec la police intégrée, anguleuse, de la bibliothèque d'affichage. Un petit utilitaire choisit maintenant la plus grande police grasse qui tient dans chaque zone de texte et la centre. Les zones n'ont pas changé, donc les tests de mise en page tiennent toujours. L'indication de checkout se redimensionne de la même façon (taille 3, 2 ou 1, selon ce qui tient dans l'anneau), et « Legs » et « Avg » sont des éléments séparés, en jaune et en bleu.

**Un écran de démarrage.** Le TFT principal affiche un titre encadré « DARTS SCORER » pendant 1,8 seconde avant le menu.

**Une carte qui tient dans le boîtier.** J'ai aussi dessiné la carte soudée pour le boîtier imprimé en 3D. Le boîtier laisse environ 10,6 mm de profondeur derrière les écrans, donc la Teensy est soudée directement sur une plaque perforée plutôt que montée sur supports, ce qui aurait fait environ 14 mm. Un script compare le câblage dessiné aux constantes de broches du croquis et refuse de dessiner si elles diffèrent.

![Schéma de câblage de la version sur plaque d'essai : Teensy 4.0, TFT 2,8 pouces tactile, deux écrans ronds et buzzer](/images/darts-scorer/2026-11-03-round-screens-celebrate/03-wiring-breadboard.jpg)
*Le câblage sur plaque d'essai, par lequel je commencerai. Les trois écrans partagent les fils d'horloge et de données ; chacun a sa propre broche de sélection (CS).*

![Schéma de câblage de la plaque perforée soudée, ajustée au boîtier : Teensy, embases, plots du buzzer et 28 fils](/images/darts-scorer/2026-11-03-round-screens-celebrate/04-wiring-soldered-board.jpg)
*La version soudée : les mêmes broches, avec des fils point à point sous une plaque perforée découpée pour le boîtier.*

![Écran rond d'un joueur en plein clignotement après un 180, anneau rouge et score vert](/images/darts-scorer/2026-11-03-round-screens-celebrate/01-180-flash.jpg)
<!-- PHOTO TODO: Only once the round screen runs on hardware: a still of the 180 flash. Room lights dimmed, camera straight on, shutter around 1/60s so the colour isn't half-faded. Until then, use a screenshot of the PC layout. -->
*Un 180 : l'anneau et le score clignotent en rouge et vert, deux fois.*

## Ce qui a mal tourné ou m'a surpris

**Les clignotements bloquent tout.** La façon la plus simple de clignoter est `delay()`, ce qui signifie que la Teensy ignore le tactile pendant l'effet. Un 180 dure environ une demi-seconde (2 clignotements × 2 phases × 130 ms), l'effet neuf fléchettes un peu moins d'une seconde, et « GAME ON » 1,2 seconde. Pour un jeu de fléchettes c'est acceptable, personne ne touche l'écran pendant une célébration, mais c'est un raccourci, et il faudrait une version à base de minuterie si les effets s'allongeaient.

**Les neuf fléchettes sont déduites, pas comptées.** Le marqueur reçoit des totaux de volée, pas les fléchettes une à une, donc il ne les voit pas. Il suppose qu'une manche gagnée en exactement trois volées marquantes est une manche en neuf fléchettes, ce qui est vrai tant que chaque volée compte trois fléchettes. C'est une simplification assumée, pas une mesure.

![Plaque perforée avec la Teensy soudée, tenue à côté de la coque avant pour vérifier l'ajustement](/images/darts-scorer/2026-11-03-round-screens-celebrate/02-board-in-case.jpg)
<!-- PHOTO TODO: Once the board is built: perfboard next to the open front shell to show the depth problem and the notch for USB. Include a ruler for scale. Until then, use docs/darts-scorer-v2-soldered-board.jpg. -->
*La carte prévue : la Teensy soudée à plat pour que tout tienne derrière les écrans.*

## La suite

Toujours la même étape, et c'est celle qui compte : rien de tout cela (tactile, TFT, écrans ronds, buzzer, écran de démarrage et effets) n'a été compilé pour la Teensy ni exécuté sur du matériel. Vient ensuite une première compilation, puis la mise en route du TFT sous alimentation USB sur la plaque d'essai, l'étalonnage du tactile, et les écrans ronds un par un. L'utilisation de la mémoire flash et de la RAM n'est pas mesurée avant cette première compilation.
