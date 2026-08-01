---
title: "Trois Hypothèses Fausses dans une Compétence de Publication"
date: 2026-08-01T11:30:00+01:00
draft: false
description: "L'outil qui transforme ce journal d'ingénierie en articles supposait que la section était en anglais uniquement, qu'une entrée de journal de travail fait un bon corps d'article, et qu'une entrée égale un article. Les trois étaient fausses, et les corriger montre où un script doit s'arrêter et le jugement commencer."
summary: "L'outil qui transforme ce journal d'ingénierie en articles supposait que la section était en anglais uniquement, qu'une entrée de journal de travail fait un bon corps d'article, et qu'une entrée égale un article. Les trois étaient fausses, et les corriger montre où un script doit s'arrêter et le jugement commencer."
tags:
  - club-monitor
  - tooling
  - python
  - hugo
  - claude-code
  - writing
source:
  - "2026-07-31-1030-publish-progress-skill-adds-fr-es-translations.md"
  - "2026-07-31-1115-publish-progress-skill-reader-facing-articles.md"
  - "2026-08-01-1130-publish-progress-skill-multi-source-articles.md"
---

Ces articles sont générés à partir d'un journal d'ingénierie. Chaque modification apportée à Club Monitor écrit une entrée datée dans `progress/`, et une petite compétence transforme ces entrées en les billets que vous lisez, un assistant Python prenant en charge les parties déterministes — dates, en-tête de métadonnées, nommage des fichiers — tandis que les arbitrages restent au modèle.

La première version fonctionnait, puis trois choses distinctes s'y sont révélées fausses. Chaque correctif est modeste ; ensemble, ils illustrent assez bien où passe réellement la frontière entre un script et le jugement d'un modèle.

## « Anglais uniquement » n'a jamais été une contrainte

La documentation de la compétence indiquait que la section ClubMonitor était en anglais uniquement. C'était une description exacte des huit articles qui existaient au moment de sa rédaction, et pas du tout un fait à propos du site. Les autres sections du site publient déjà des fichiers `.fr.md` et `.es.md` à côté de chaque article anglais : même slug, en-tête et corps traduits, étiquettes anglaises en kebab-case laissées telles quelles.

Copier une convention établie est plus sûr que d'en inventer une nouvelle : la section ClubMonitor la suit désormais. Les métadonnées de chaque article ont gagné un objet `translations` optionnel avec des entrées `fr` et `es`, chacune portant un titre, une description et un corps. Le script a généralisé son constructeur d'en-tête pour accepter un titre et une description explicites tout en conservant `date`, `tags` et `source` des métadonnées de base, si bien que l'article anglais et ses traductions partagent une seule et même forme.

Fait notable, la traduction elle-même est restée *en dehors* du script. Elle exige le même jugement que le titre et la description anglais réclament déjà, elle vit donc dans les métadonnées que le modèle rédige. Le script est délibérément cantonné à ce qu'un script fait effectivement mieux.

Ce changement a eu une conséquence peu évidente. La commande `status` fonctionne en relisant la clé `source:` des articles publiés pour déterminer ce qu'il reste à écrire — et les traductions portent le même `source` que leur original anglais. Sans ignorer les `*.fr.md` et `*.es.md` lors de la construction de cette table, le résultat dépendait de l'ordre du glob.

## Le corps était une transcription, pas un article

Le deuxième problème était plus fondamental : le script publiait le texte même de l'entrée de progression comme corps de l'article.

Les entrées de progression sont écrites pour le dépôt. Elles s'ouvrent sur « Ce qui a changé », elles disent des choses comme « Suite à la question sur… » ou « Décision : garder l'anonymat », et elles listent chaque fichier touché. Tout cela est juste pour un journal de travail et faux pour un texte qu'un inconnu pourrait lire. Le résultat était techniquement exact et ennuyeux.

Les métadonnées portent donc désormais un `body` explicite — un article anglais soigné, rédigé par le modèle après lecture de l'entrée, que le script publie à la place du texte brut. C'est ce même corps qui est traduit, de sorte que les articles français et espagnol sont des traductions de l'article et non du journal. Les instructions de la compétence réclament une prose qui se lise comme un texte publié, et nomment les tics précis à éviter. Un test de non-régression couvre ce comportement.

## Un article, plusieurs entrées

La dernière hypothèse à tomber fut « une entrée, un article ».

Elle tient lorsque les entrées se suffisent à elles-mêmes. Elle échoue lourdement pour un travail arrivé par phases — le déploiement multilingue décrit ailleurs dans cette section a atterri sous la forme de sept entrées de progression plus un plan, et publier huit articles ténus se serait bien moins lu qu'un seul texte racontant toute l'histoire.

Ainsi, `source` dans les métadonnées peut désormais être un nom de fichier unique, comme avant, ou une liste :

```json
{"source": ["2026-08-01-1200-thing.md", "2026-08-01-1600-thing-part-two.md"],
 "slug": "thing", "title": "...", "description": "...", "body": "..."}
```

Tout le reste en découle. L'en-tête écrit `source` comme un scalaire entre guillemets pour une entrée et comme une liste YAML pour plusieurs, si bien que les articles existants restent intacts et que relancer `status` sur le site en production donne la même réponse qu'avant. `status` associe chaque entrée listée à l'article qui la couvre, aucune n'est donc proposée de nouveau, et il suggère désormais — lorsque plus d'une entrée est en attente — que des entrées liées peuvent partager un article. La date de l'article est la plus récente de ses sources, de sorte qu'un article combiné se classe comme un travail récent plutôt qu'au jour où la première phase a atterri.

Une règle est imposée plutôt que suggérée : `body` est **obligatoire** dès qu'il y a plus d'une source. Le repli mono-source qui extrait le texte du fichier de progression n'a pas d'équivalent multi-entrées sensé, et coller des journaux bout à bout est exactement le résultat que toute la compétence existe pour éviter.

Relire la clé `source` a demandé un petit soin. Le motif d'élément de liste doit exiger une espace après le tiret, faute de quoi il déborde au-delà du `---` de fermeture de l'en-tête et lit le délimiteur comme une source supplémentaire, malformée.

## Où est passé le jugement

La décision de regroupement ne peut pas être mécanisée ; elle est donc devenue une consigne explicite : une étape entre la lecture des entrées et l'écriture des métadonnées. Regrouper lorsque l'utilisateur nomme des fichiers précis, ou lorsque la lecture révèle une seule histoire racontée à travers plusieurs journaux. Séparer lorsque les travaux sont réellement sans rapport et simplement voisins dans le temps. Lorsque l'utilisateur nomme les fichiers, publier exactement ceux-là sans en glisser d'autres en douce. Et pour un article combiné, écrire un texte continu — trouver le fil qui traverse les entrées — plutôt que les journaux agrafés les uns aux autres sous un titre chacun, sans perdre la substance d'aucune entrée listée comme source.

L'ensemble a été éprouvé sur un répertoire de contenu jetable avant d'approcher le vrai site : un article à deux sources et un article à source unique écrits en une seule exécution, `status` signalant les trois entrées comme publiées, les deux chemins d'erreur, et `status` sur le site réel confirmant que les neuf articles existants à `source` scalaire se résolvent exactement comme auparavant.
