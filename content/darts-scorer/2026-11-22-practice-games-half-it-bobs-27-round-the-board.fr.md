---
title: "Trois jeux d'entraînement, et les règles qu'il a fallu trancher"
description: "Le marqueur propose maintenant Half-It, Bob's 27 et Round the Board sur une base commune, avec des règles maison réglables à l'écran. 5 274 vérifications passent sur PC ; rien n'a encore tourné sur le matériel."
date: 2026-11-22
---

Le marqueur n'est plus un simple compteur de 501. Il a maintenant trois jeux d'entraînement, Half-It, Bob's 27 et Round the Board, tous bâtis sur une même classe. La logique et tous les affichages passent 5 274 vérifications sur mon PC (contre 3 844 il y a trois semaines) ; rien n'a encore tourné sur un vrai écran.

## Ce que j'ai fait

**Une base, trois jeux de règles.** Les trois jeux fonctionnent pareil : on saisit une volée, le jeu la vérifie, l'annulation la retire. J'ai donc écrit cela une seule fois dans `VisitGame.h` (clavier de saisie, annulation, statistiques, quitter, écran de résultat), et chaque jeu ne fournit que ses règles. Le score de chaque jeu est une pure fonction des volées enregistrées, ce qui rend l'annulation triviale : on oublie la dernière volée et on recalcule.

**Half-It.** Neuf tours : 20, 19, 18, 17, 16, 15, un double quelconque, un triple quelconque, le centre. On marque ce qu'on touche ; si on ne touche rien, le total est divisé par deux. Chaque club y joue un peu différemment, donc les règles maison sont des boutons sur l'écran des joueurs plutôt que mon choix :

| Réglage | Par défaut | Alternative |
|---|---|---|
| Score de départ | 40 | 0 |
| Division par deux | arrondie vers le bas | arrondie vers le haut |

**Bob's 27.** On part de 27 et on vise D1, D2 et ainsi de suite jusqu'à D20, puis le centre. Chaque fléchette qui touche ajoute la valeur du double ; trois ratés la retranchent. À 0 ou moins, on est éliminé. Une partie parfaite fait 1 437, et un test vérifie exactement ce nombre.

**Round the Board.** On part de 1 et on monte jusqu'à 20 avec un simple (ou un double, qui fait avancer plus loin), puis on touche un double deux fois, puis le centre. La saisie se fait fléchette par fléchette avec les touches Touché / Raté / Double, et la bande de LED clignote en rouge pour un raté, en vert pour un touché et deux fois pour un double.

**Une page Entraînement.** Half-It et Bob's 27 se trouvent sur une page Entraînement depuis le menu principal. Un petit `GameConfig.h` contient un `true`/`false` par jeu ; mettez `false` et le jeu disparaît des menus.

![Menu principal montrant 501, Round the Board et Training](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/01-main-menu.jpg)
<!-- PHOTO TODO: Screenshot of the main TFT menu. Until the screen runs on hardware, use a screenshot from the PC layout test. Crop to the screen only. -->
*Le menu principal : 501, Round the Board et Training.*

## Ce qui a mal tourné ou m'a surpris

**La saisie de Bob's 27 était à l'envers.** Ma première version demandait « fléchettes touchées ? » avec quatre boutons, de 0 à 3. Il est facile de se tromper de bouton, et l'annulation ne pouvait pas retirer une demi-volée. Elle demande maintenant fléchette par fléchette, « Dart 1 of 3 », avec de grands boutons Hit et Miss, et l'annulation retire une fléchette avant de retirer une volée entière. Un test fige désormais ce comportement.

![Écran de saisie de Bob's 27 avec de grands boutons Hit et Miss](/images/darts-scorer/2026-11-22-practice-games-half-it-bobs-27-round-the-board/02-bobs-27-hit-miss.jpg)
<!-- PHOTO TODO: The Hit/Miss screen, ideally on the real TFT at arm's length, with glare reduced. Before hardware: PC layout screenshot. -->
*Hit et Miss, une pression par fléchette.*

**Round the Board a plus d'un règlement.** La première version demandait un seul double pour finir ; les règles que j'ai retenues en demandent deux, pas forcément consécutifs. J'ai écrit la règle dans un commentaire en tête du jeu, puis dans un test, pour ne pas oublier laquelle j'ai choisie.

**L'arrondi de Half-It fait vraiment débat.** La moitié de 41 donne 20 ou 21 selon la personne qui vous a appris le jeu. Plutôt que de trancher, j'en ai fait un réglage.

## La suite

Toujours la même étape, et c'est la plus importante : le code du tactile, de l'écran TFT, des écrans ronds et des LED n'a pas été compilé pour le Teensy ni exécuté sur le matériel, donc aucun de ces jeux n'a été joué sur l'appareil. Viennent ensuite une première compilation, la mise en route du TFT sur la platine d'essai, l'étalonnage du tactile et les écrans ronds un par un. L'utilisation de la mémoire flash et de la RAM n'est toujours pas mesurée.
