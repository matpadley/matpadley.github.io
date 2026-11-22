---
title: "Pourquoi mon marqueur de fléchettes passe d'un Nano à un Teensy"
description: "Mon marqueur de fléchettes sur Arduino Nano manque de RAM, donc la version 2 passe à un Teensy 4.0 et un écran couleur. Les règles sont écrites et testées sur PC ; le matériel vient ensuite."
date: 2026-10-27
---

Mon marqueur de fléchettes sur Arduino Nano fonctionne, mais il n'a plus de place pour évoluer. La version 2 passe à un Teensy 4.0 et à un écran couleur de 2,8 pouces, et j'ai écrit et testé les règles du jeu sur mon PC avant de toucher au moindre composant.

La version 1 est un Nano avec un écran LCD de 20x4 caractères et un clavier 4x4. Elle marque le 501 pour un à quatre joueurs et tient largement en mémoire flash (environ 15,5 Ko sur 32 Ko, soit 47 %). Le problème, c'est la RAM : elle utilise déjà environ 72 % des 2 Ko du Nano, et je veux plus qu'une grille de 20x4 : le 301 en plus du 501, des réglages de match, l'historique des volées de chaque joueur et des suggestions de finition.

La version 2 change donc le matériel :

- **Carte :** Teensy 4.0 (600 MHz, 1 Mo de flash, environ 1 Mo de RAM).
- **Écran :** écran SPI ILI9341 de 2,8 pouces, 320x240 pixels. J'ignore la couche tactile éventuelle ; je veux que le clavier reste la seule entrée.
- **Joueurs :** deux joueurs fixes pour l'instant, sans noms, rien de sauvegardé.
- **Règles :** 301 et 501, manches « premier à » ou « meilleur de », entrée libre ou double obligatoire, sortie libre ou sur un double, et jusqu'à trois routes de finition classées par nombre de fléchettes croissant.

En tant que développeur C#, la partie où je suis le plus à l'aise est celle qui se teste facilement, donc je l'ai faite en premier. Les règles du jeu ne touchent jamais le matériel : les écrans sont dessinés via une `Ui` abstraite, et sur PC une version qui enregistre les appels vérifie que chaque écran tient dans 320x240 et qu'aucun texte ne se chevauche. Pour l'instant, cela couvre les règles, les routes de finition et la mise en page de tous les écrans, le tout testé sur PC.

![Les composants prévus posés sur un établi avec une règle pour l'échelle](/images/darts-scorer/2026-10-27-nano-to-teensy/01-parts-with-ruler.jpg)
<!-- PHOTO TODO: Teensy 4.0, TFT, keypad, breadboard and jumper wires laid flat on a plain surface with a ruler beside them, shot from above in daylight. Gives the reader a sense of scale before any wiring. -->
*Les composants de la version 2, avec une règle pour l'échelle.*

J'ai relevé les prix chez des fournisseurs britanniques le 27 octobre 2026 : le Teensy 4.0 avec connecteurs coûte 25,80 £ chez The Pi Hut, et l'ensemble revient à environ 43 £ sans l'écran ni le buzzer, ou environ 60 £ avec les deux. Le prix de l'écran est une estimation (10-20 £) que je confirmerai avant de commander.

## Ce qui a mal tourné ou m'a surpris

**La tension.** Le Nano fonctionne en 5 V ; le Teensy fonctionne en 3,3 V et ses broches ne tolèrent *pas* le 5 V. Un seul mauvais fil peut le détruire définitivement. Mes règles pour le montage : câbler avec l'USB débranché, alimenter l'écran et son rétroéclairage depuis la broche 3,3 V (le rétroéclairage consomme 50 à 100 mA, beaucoup trop pour une broche de signal), et vérifier que l'annonce de l'écran indique une logique en 3,3 V.

**Le tampon d'écran.** Je dessine chaque écran dans un canevas en mémoire, puis je l'envoie à l'afficheur d'un seul coup, ce qui évite le scintillement. À 320x240x2 octets, cela représente environ 150 Ko. Sur le Nano, c'est impossible ; sur le Teensy, c'est une petite part de la RAM.

**Le double obligatoire à l'entrée avec des totaux de volée.** Le marqueur reçoit le total d'une volée, pas chaque fléchette. Avec le double à l'entrée, seules les fléchettes à partir du premier double comptent : on ne saisit donc que ces points (ou `B` si aucun double n'a été réussi). C'est une petite règle, mais elle a façonné les écrans de saisie.

**Meilleur de.** Je considère le « meilleur de » uniquement avec des nombres impairs (au meilleur de 5, il faut gagner 3 manches). C'est une hypothèse de travail que je n'ai pas encore confirmée avec les règles réelles d'un match.

![Un terminal affichant la réussite des tests sur PC](/images/darts-scorer/2026-10-27-nano-to-teensy/02-host-test-output.png)
<!-- PHOTO TODO: Screenshot of the PC test run for tests/test_main.cpp, cropped to the summary lines. Shows the reader the logic is tested without hardware. -->
*Les règles, les routes de finition et la mise en page des écrans passent tous les tests sur PC.*

## La suite

Rien n'a encore tourné sur le vrai clavier, le vrai écran ou le vrai buzzer. La prochaine étape consiste à faire démarrer l'écran en alimentation USB sur une breadboard, puis à ajouter le clavier, puis le buzzer, puis à jouer une manche complète et à relever les vraies valeurs de flash et de RAM. L'alimentation sur piles (3 piles AAA, un module élévateur 5 V et une diode) viendra plus tard, et seulement après avoir lu la page de PJRC sur l'alimentation du Teensy 4.0 concernant l'usage simultané des piles et de l'USB.

![Le schéma de câblage prévu sur breadboard pour le Teensy, l'écran et le clavier](/images/darts-scorer/2026-10-27-nano-to-teensy/03-wiring-sketch.png)
<!-- PHOTO TODO: Photo or screenshot of the wiring layout sketch (Teensy in the centre, TFT on SPI pins 13/11/10/14/15, keypad on 9-6 and 5-2). Replace with a photo of the real breadboard once wired. -->
*Le câblage prévu, avant que quoi que ce soit ne soit branché.*
