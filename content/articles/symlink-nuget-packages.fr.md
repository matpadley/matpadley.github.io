---
title: "Libérez votre cache NuGet : déplacer .nuget et .packages vers un autre volume"
date: 2026-08-18
draft: false
description: "Votre cache .nuget dévore discrètement le disque de votre Mac. Déplacez-le vers un SSD externe, laissez un lien symbolique derrière vous, et récupérez l'espace sans perdre un seul paquet mis en cache."
tags:
  - dotnet
  - nuget
  - macos
  - developer-tools
---

Si vous avez déjà jeté un œil à la répartition du stockage de votre Mac en vous demandant pourquoi les « Données système » semblent vouloir avaler tout le disque, il y a de bonnes chances que votre cache `.nuget` et votre dossier `.packages` se gavent tranquillement en arrière-plan. Chaque restauration, chaque projet, chaque « allez, essayons vite fait ce paquet » ajoute un peu plus à la pile — et ça ne diminue jamais tout seul.

La bonne nouvelle : vous n'avez pas à vous en accommoder, et vous n'avez pas à renoncer à votre cache de paquets global pour récupérer l'espace. Il suffit de le déplacer — en laissant un lien symbolique derrière vous pour que .NET n'y voie que du feu.

## Pourquoi ça vaut le coup

Le dossier `~/.nuget/packages` (et souvent `~/.packages` aussi, selon votre configuration) accumule *chaque version de chaque paquet* que vous avez déjà restauré, sur *chaque projet* sur lequel vous avez travaillé. Multipliez ça par quelques années de développement C#, une poignée de solutions aux graphes de dépendances légèrement différents, et un `dotnet restore` un peu trop zélé de temps en temps, et il n'est pas rare d'y trouver des dizaines de gigaoctets — discrètement, invisiblement, pour toujours.

Le déplacer hors de votre disque interne principal vous rend cet espace instantanément, sans supprimer le moindre paquet mis en cache ni toucher aux performances de compilation.

## Le déplacement

**1. Fermez tout ce qui l'utilise.** Quittez votre IDE (Rider, VS Code, peu importe) pour que rien ne soit en pleine restauration pendant l'opération.

**2. Déplacez le dossier vers son nouveau foyer :**
```bash
mv ~/.nuget/packages /Volumes/VotreSSD/nuget-packages
```

**3. Laissez un lien symbolique là où .NET s'attend à le trouver :**
```bash
ln -s /Volumes/VotreSSD/nuget-packages ~/.nuget/packages
```

Répétez ces deux mêmes étapes pour `~/.packages` si vous l'utilisez. L'outillage .NET lit et écrit dans `~/.nuget/packages` par chemin — il n'a aucune idée (et aucune raison de se soucier) que les fichiers vivent désormais ailleurs.

**4. Vérifiez que ça marche :**
```bash
dotnet restore
```
Si la restauration se passe bien et que `ls -la ~/.nuget` affiche la petite flèche à côté de `packages`, c'est terminé.

## Mais *où* mettre cet « autre volume » ?

Voilà le point qu'il est facile de rater : techniquement, n'importe quel volume monté fait l'affaire — un disque dur externe, un partage réseau, une clé USB poussiéreuse trouvée au fond d'un tiroir. Mais tous ne fonctionnent pas *bien*.

Mettez-le sur un SSD. Idéalement un SSD externe branché en USB-C/Thunderbolt, ou mieux encore un SSD secondaire interne si votre configuration le permet.

Pourquoi c'est plus important qu'il n'y paraît : les restaurations NuGet impliquent des *milliers* de petites lectures de fichiers, pas quelques grosses lectures séquentielles. C'est exactement la charge de travail que les disques mécaniques gèrent le plus mal, et exactement celle que les SSD avalent sans broncher. Placez votre cache de paquets sur un disque mécanique et vous échangerez de l'espace disque contre des temps de restauration : chaque `dotnet restore`, chaque réindexation de l'IDE, chaque compilation locale donnera l'impression de patauger dans la mélasse.

Un SSD garde les restaurations rapides, évite que votre IDE se fige sur les recherches de fichiers, et rend malgré tout son espace à votre disque principal. Vraiment le meilleur des deux mondes — les NVMe externes bon marché font de ce choix une évidence aujourd'hui.

## Un petit piège

Si vous démontez ou débranchez ce SSD externe, `dotnet restore` échouera (le lien symbolique pointera dans le vide, ce qui se comprend). Pas bien grave si le disque reste branché en permanence, mais bon à retenir avant de le débrancher et de vouloir compiler dans la foulée.

Et c'est tout — la même astuce que pour déplacer n'importe quel dossier macOS avec un lien symbolique, simplement appliquée aux parties de votre chaîne d'outils `.NET` qui accumulent le plus d'espace. Votre disque interne vous dira merci.
