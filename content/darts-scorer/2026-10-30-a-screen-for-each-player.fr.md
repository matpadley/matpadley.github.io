---
title: "Un écran rond pour chaque joueur, et un anneau qui se vide"
description: "Le marqueur de fléchettes a maintenant un écran tactile au centre et un petit écran rond par joueur, avec un anneau qui se réduit à mesure que le score baisse. Tout fonctionne dans mes tests sur PC ; rien n'a encore tourné sur le matériel."
date: 2026-10-30
---

J'ai abandonné le clavier et donné à chaque joueur son propre écran rond de 1,28 pouce. Chacun affiche le score du joueur dans un anneau qui se vide à mesure qu'il approche de zéro. Les affichages sont testés sur mon PC ; rien de tout cela n'a encore tourné sur du vrai matériel.

## Ce que j'ai fait

**Tactile au lieu de touches.** Le TFT de 2,8 pouces a une couche tactile résistive, donc le pavé numérique est maintenant dessiné à l'écran et le clavier 4x4 disparaît du montage. Cela libère beaucoup de câblage. Cela inverse aussi ce que j'écrivais la dernière fois, quand je disais que le clavier resterait la seule entrée.

**Un écran par joueur.** Le grand écran gère maintenant la configuration, les réglages du match et la saisie des scores. Les deux écrans ronds GC9A01 (240x240, à gauche pour le Joueur 1, à droite pour le Joueur 2) affichent les chiffres qu'on veut lire depuis la ligne de lancer : score restant, manches, moyenne sur trois fléchettes, dernière volée, et une ligne pour le chemin de finition ou « Needs a double ».

**L'anneau.** Le bord extérieur de chaque écran rond est une jauge. Il est plein à 301 ou 501 et se réduit dans le sens horaire à partir de 12 heures quand le score baisse. Jaune : le joueur est au lancer ; gris : il attend ; vert avec un anneau plein : il a gagné le match. Le calcul tient en une ligne :

```cpp
int32_t d = (int32_t)v.remaining * 360 / v.start;
```

La bibliothèque d'affichage n'a pas de fonction d'arc, donc je dessine un petit point par degré autour de l'anneau. Les écrans ronds n'ont ainsi besoin que d'un appel « dessiner un disque plein », et le même code de dessin fonctionne sur le PC.

**Tester la mise en page sans écran.** Comme l'écran principal, les écrans des joueurs dessinent via une surface abstraite, et une version qui enregistre les appels sur le PC vérifie que chaque zone de texte tient dans le cercle visible et dans l'anneau, et que rien ne se chevauche. Un écran rond coupe ses coins : un rectangle qui tient dans 240x240 peut donc être tronqué. Le test complet indique actuellement 3 823 vérifications et 0 échec.

![Gros plan d'un écran rond de joueur avec le score dans un anneau jaune](/images/darts-scorer/2026-10-30-a-screen-for-each-player/01-round-screen-ring.jpg)
<!-- PHOTO TODO: Only once the round screen is working: close-up of one round screen mid-leg with the ring partly lit. Shoot straight on, slightly dimmed room, to avoid glare on the glass. Until then, use a screenshot of the PC layout. -->
*L'écran d'un joueur : le score au milieu, les points restants sous forme de partie allumée de l'anneau.*

## Ce qui a mal tourné ou m'a surpris

**Deux écrans, les mêmes fils.** Les écrans ronds ne font qu'écouter, donc ils peuvent partager les fils d'horloge (SCK, broche 13) et de données (MOSI, broche 11) de l'écran principal. Chacun a sa propre broche de sélection (CS), qui dit « ce message est pour moi ». Le module a aussi une résistance de rappel vers le bas sur CS : si une broche CS n'est pas mise à l'état haut au démarrage, les deux écrans écoutent en même temps. Le code met les deux broches CS à l'état haut dès le début de `setup()`.

**Broches de réinitialisation.** Je pensais d'abord qu'elles pouvaient partager une seule ligne de reset. Ce n'est pas possible : la bibliothèque réinitialise l'écran au démarrage, donc le démarrage du second écran vide le premier. Chacun a sa propre broche de reset (8 et 22).

**Mémoire.** Un canevas de 240x240 pèse environ 115 Ko. Les deux écrans le partagent et se redessinent l'un après l'autre. Le Teensy a la RAM pour ça ; le Nano n'aurait jamais pu.

**La tension, encore.** L'annonce des écrans ronds indique une alimentation de 3 à 5 V. Je les alimente quand même en 3,3 V, pour que les broches de données et l'alimentation soient d'accord et que rien ne puisse mettre 5 V sur une broche du Teensy.

![Plaque d'essai vue de dessus avec le Teensy, le TFT et les deux écrans ronds câblés](/images/darts-scorer/2026-10-30-a-screen-for-each-player/02-breadboard-three-screens.jpg)
<!-- PHOTO TODO: Whole breadboard from above once wired, with the shared SCK/MOSI "hub" rows visible. Shows how three screens share two wires. Until then, use the updated docs/darts-scorer-v2-breadboard.jpg wiring diagram. -->
*Le câblage prévu : trois écrans qui partagent les mêmes fils d'horloge et de données.*

## La suite

Ni le code du tactile, ni celui du TFT, des écrans ronds ou du buzzer n'a été compilé pour le Teensy ni exécuté sur du matériel. Le plan reste le même, avec le tactile en plus : mettre en route l'écran principal sur l'alimentation USB, ajouter les fils du tactile et calibrer les quatre coins, puis ajouter les écrans ronds un par un, en commençant par celui de gauche. Je dois encore confirmer que la puce tactile du module 2,8 pouces est bien un XPT2046 à sa réception, ainsi que le prix des écrans ronds, que l'annonce n'affichait pas.
