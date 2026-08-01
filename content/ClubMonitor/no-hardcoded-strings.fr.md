---
title: "Aucune Chaîne Codée en Dur : Localiser un Front End Uno Platform"
date: 2026-08-01T09:00:00+01:00
draft: false
description: "Une traduction manquante se replie silencieusement sur l'anglais : une compilation verte ne prouve rien. Les garanties devaient être des lints — et tester une interface qui se dessine entièrement dans un seul canvas a imposé de vérifier la culture stockée et les pixels plutôt que le texte."
summary: "Une traduction manquante se replie silencieusement sur l'anglais : une compilation verte ne prouve rien. Les garanties devaient être des lints — et tester une interface qui se dessine entièrement dans un seul canvas a imposé de vérifier la culture stockée et les pixels plutôt que le texte."
tags:
  - club-monitor
  - uno-platform
  - localization
  - xaml
  - playwright
  - testing
  - ci
source:
  - "2026-07-31-1700-multilingual-phase-4-frontend-groundwork.md"
  - "2026-07-31-1800-multilingual-phase-5-pages-off-hardcoded-strings.md"
  - "2026-07-31-1900-multilingual-phase-6-tests-and-ci.md"
  - "2026-08-01-0900-multilingual-phase-7-documentation.md"
---

Le contrat d'échec de l'API étant devenu lisible par machine, la moitié intéressante du passage au multilingue s'est déplacée vers le front end Uno Platform. Ce travail comportait trois volets : décider dans quelle langue l'application doit s'afficher, sortir du balisage chaque chaîne visible par l'utilisateur, et trouver quelque chose capable de détecter réellement une traduction manquante.

## Décider quelle langue afficher

L'ordre de négociation est court, mais chaque clause mérite sa place :

1. Une surcharge explicite sur l'appareil, si elle existe.
2. Sinon la locale du système, ramenée à une culture prise en charge.
3. Sinon l'anglais.

À la connexion, un appareil sans surcharge adopte le `PreferredLanguage` stocké sur le compte — mais une surcharge existante n'est jamais remplacée en silence. Le sélecteur intégré à l'application écrit la surcharge immédiatement et synchronise le compte au mieux.

Le rabattage compte plus qu'il n'y paraît. Un appareil réglé sur `fr-CA` ou `es-419` doit obtenir le français ou l'espagnol, et non retomber jusqu'à l'anglais parce que la balise régionale exacte n'est pas dans l'ensemble pris en charge. `SupportedCultures.Clamp` réduit une balise régionale à sa langue avant d'abandonner.

Deux détails d'implémentation sont faciles à rater. **La culture est appliquée avant même l'existence de la première fenêtre** — `CultureService.Initialize()` est la première ligne d'`OnLaunched` — et **changer de langue reconstruit la racine de l'application**, parce que les résolutions de ressources se font à la construction des visuels. Définir seulement `PrimaryLanguageOverride` laisse dans l'ancienne langue tout ce qui est déjà à l'écran. Le shell reconstruisait déjà la racine lors d'un changement de thème et mémorisait la page courante au passage : un changement de langue réutilise exactement ce chemin et l'utilisateur reste là où il était.

Une chose délibérément non construite : une invite à la connexion demandant qui l'emporte lorsque la surcharge de l'appareil et la langue du compte divergent. La spécification dit que la surcharge de l'appareil l'emporte toujours et que la connexion ne la remplace jamais en silence. Le milieu d'une connexion est un mauvais endroit pour poser une question dont la spécification n'a pas besoin de la réponse.

## Sortir les chaînes du balisage

Les fichiers de ressources sont passés d'une seule entrée à 142 par culture. L'essentiel relève du mécanique — un `x:Uid` sur chaque contrôle, à travers l'écran de connexion, le tableau de bord, les membres, les ligues, les classements et le profil joueur.

Une partie n'est pas mécanique du tout, et c'est précisément là que vit la localisation :

- **Le texte choisi à l'exécution.** Les invites du double facteur, les échecs de passkey, le message d'accueil selon l'heure, un titre de classement construit à partir d'une chaîne de format — `x:Uid` ne peut exprimer aucun de ces cas. Ils passent par une recherche `LocalizedStrings`. Les invites dynamiques de l'écran de connexion vivaient entièrement dans le code-behind, dont la règle « pas de littéraux en XAML » ne dit rien.
- **Les valeurs d'énumération venues de l'API.** Rôles, statuts, types de compétition, visibilité et statut de match arrivent sur le réseau sous forme de noms d'énumération anglais — `Admin`, `Active`, `League`, `Public`, `Scheduled`. Ce sont des données, pas des littéraux : un balayage du balisage ne les touche jamais. Laissées telles quelles, elles maintiennent les listes Membres et Ligues visiblement en anglais sur un écran par ailleurs français. `EnumLabels` les traduit, et une valeur non reconnue s'affiche telle quelle, de sorte qu'un nouveau membre d'énumération que l'application ne connaît pas se dégrade en anglais plutôt qu'en étiquette vide.
- **Le texte entre balises d'éléments.** La ligne de rencontre était constituée de deux éléments `Run` en ligne avec un ` vs ` littéral entre eux. `x:Uid` ne peut atteindre un nœud de texte nu — et coder en dur le séparateur code aussi en dur l'ordre des mots, qui appartient au traducteur. `Match_Fixture` vaut `{0} vs {1}`, ainsi une langue qui l'ordonne différemment le peut.
- **Les en-têtes de colonnes abrégés.** `P/W/D/L` dans le tableau des classements n'est pas cosmétique : cela devient `J/G/N/P` en français et `PJ/G/E/P` en espagnol.

Le sélecteur de langue liste English / Français / Español en endonymes — chacun dans sa propre langue, dans toutes les cultures, comme le font conventionnellement les sélecteurs de langue. Les commentaires de ressources le précisent explicitement, car des valeurs identiques dans trois cultures ressemblent sinon exactement à une traduction manquante.

## La seule chose qui détecte une traduction manquante

Une ressource absente d'une culture se replie silencieusement sur la langue par défaut à l'exécution. L'application paraît parfaitement saine tout en affichant de l'anglais à un utilisateur français. Une compilation verte ne prouve rien.

Les garanties sont donc des lints, exécutés comme des tests unitaires ordinaires qui lisent les fichiers `.resw` directement depuis le dépôt — pas de navigateur, pas de charge de travail Uno, pas d'application en cours d'exécution :

- Chaque culture définit exactement les mêmes clés, et aucune n'a de valeur vide.
- Chaque membre d'`ErrorCode` a un message dans chaque culture. Le projet de test référence l'API, il lit donc l'énumération elle-même plutôt qu'une liste de noms recopiée.
- Aucune entrée `ErrorCode_*` ne renvoie à un code qui n'existe plus, et un repli générique `Error_Unknown` existe partout.
- Aucun attribut `Text`/`Content`/`PlaceholderText`/`Header` littéral dans le XAML de l'application, et aucun texte littéral entre balises d'éléments.
- **Chaque `x:Uid` est adossé à une entrée de ressource.** C'est celui qui compte le plus : un `x:Uid` mal orthographié ou sans correspondance ne fait pas échouer la compilation, le contrôle s'affiche simplement vide à l'exécution.
- Aucun `.Text = "literal"` dans le code-behind des pages.

Chaque lint a été vérifié en introduisant la violation qu'il vise et en confirmant que la suite passait au rouge, avant de revenir en arrière — un lint qui analyse le mauvais répertoire passe tout aussi discrètement qu'un code propre.

Ils n'étaient initialement accessibles que depuis le job CI de bout en bout, qui nécessite SQL Server, l'API et la tête web. Ils s'exécutent désormais aussi dans le job rapide de build et de test via `--filter TestCategory=Static` : neuf tests en environ un dixième de seconde, sans lancer de navigateur, si bien qu'une traduction manquante ou une chaîne codée en dur fait échouer une pull request immédiatement.

## Tester une interface qu'on ne peut pas interroger

Le plan demandait que les fixtures Playwright existantes cessent de s'appuyer sur du texte anglais littéral et passent à `AutomationProperties.AutomationId`. Aucune des deux moitiés ne s'appliquait.

Elles ne s'appuyaient de toute façon jamais sur du texte anglais — les tests de connexion vérifient quels chemins d'API l'application appelle et les statuts HTTP ; les tests de fumée vérifient l'élément canvas, le statut HTTP et l'absence d'erreurs de page. Les deux étaient déjà indépendants de la langue, donc traduire l'application n'a rien cassé.

Et passer à `AutomationId` est impossible. La tête WebAssembly d'Uno dessine avec Skia dans un unique `<canvas>`. Sonder une application en cours d'exécution a confirmé que tout le document est `DIV/CANVAS/INPUT` avec un `innerText` vide — aucune chaîne rendue ni aucun `AutomationId` n'est atteignable depuis Playwright. Plutôt que d'inventer du travail, les deux fixtures consignent désormais la contrainte dans leurs commentaires de documentation, pour que la personne suivante ne passe pas un après-midi à la redécouvrir. Les `AutomationId` restent dans le XAML ; ils servent l'automatisation native et bureau, simplement pas la tête navigateur.

Ce qui *est* observable depuis l'extérieur du canvas s'avère suffisant. Les tests de langue de bout en bout pilotent la locale réelle du navigateur — `en-US`, `fr-FR`, `es-ES`, plus `de-DE` pour prouver qu'une langue non prise en charge se replie et `fr-CA` pour prouver qu'une balise régionale est ramenée à sa langue — et vérifient deux choses :

1. **La culture résolue par l'application.** Uno persiste `ApplicationLanguages.PrimaryLanguageOverride` dans le stockage local, le test relit donc la langue résolue par son nom au lieu de la déduire.
2. **Les pixels rendus**, qui prouvent que la culture résolue a réellement atteint l'écran au lieu d'être simplement calculée et stockée.

Deux choix délibérés dans la comparaison de pixels. **Pas d'images de référence** — les rendus sont comparés entre eux au sein d'une même exécution, car une référence versionnée casserait à chaque changement de police, de thème ou de mise en page sans jamais nous en dire plus que « ces deux-là diffèrent ». Et **un contrôle de déterminisme** : le test rend l'anglais deux fois et vérifie que les octets correspondent avant d'affirmer que le français diffère. Sans cela, « les pixels diffèrent » serait vrai de deux rendus quelconques, et un moteur de rendu non déterministe donnerait un test vert en permanence et sans signification.

Plutôt que de dormir un intervalle fixe avant la capture, l'assistant interroge jusqu'à ce que deux captures consécutives correspondent. Un sommeil fixe doit être assez long pour le runner CI le plus lent dans son pire jour et reste malgré tout une supposition ; l'interrogation a fait passer la suite d'environ deux minutes à 39 secondes.

## Auditer la documentation face au code

La spécification et `CLAUDE.md` ont été écrits avant que rien de tout cela n'existe ; la dernière étape a donc consisté à confronter chaque affirmation au code plutôt qu'à les relire pour le style. Elle a révélé de vraies dérives :

- **Des codes d'erreur qui n'existent pas.** La spécification donnait `MustBeSignedInToJoinClub` et `InvalidTwoFactorCode` en exemples. Les vrais membres sont `NotSignedIn` et `InvalidVerificationCode`. Quiconque coderait un client d'après les noms documentés aurait fait correspondre des chaînes que l'API n'envoie jamais.
- **Un mauvais verbe HTTP** — l'endpoint de langue était documenté comme un PATCH ; c'est `PUT /api/auth/language`.
- **Une règle vraie mais incomplète.** Les deux documents disaient que chaque chaîne du front end est une entrée `.resw` « référencée via `x:Uid` » et qu'aucune n'est « définie depuis le code-behind » — lu littéralement, cela interdit précisément le mécanisme que `LocalizedStrings` et `EnumLabels` ont dû employer. Les trois voies sont désormais décrites, avec `x:Uid` par défaut.
- **Un comportement documenté qui n'existe pas.** Les deux mentionnaient au présent que les e-mails d'invitation utilisent la langue du destinataire. Il n'y a pas d'e-mail d'invitation ; ce handler crée une adhésion en attente et n'envoie rien.

L'audit a aussi mis au jour un piège qui mérite d'être nommé. La liste des cultures est énoncée à trois endroits qui ne peuvent pas se référencer entre eux : la constante de l'API, la constante de l'application et les dossiers `Strings/`. Les tests de ressources en codaient en dur une **quatrième** copie. Ajouter une langue aux constantes et livrer un nouveau `.resw` aurait laissé ce fichier entièrement non vérifié — pas de comparaison de clés, pas de contrôle de valeur vide, pas de couverture des codes d'erreur — précisément quand ces contrôles comptent le plus, et en silence, puisque tout continuerait de passer.

Plutôt que de documenter le piège, il a disparu. Les tests découvrent désormais les dossiers `Strings/`, et un test supplémentaire recoupe cet ensemble avec le `SupportedCultures.All` de l'API. Une constante sans ressources, ou des ressources sans constante, échouent avec un message nommant tout ce qu'il faut mettre à jour. Vérifié en ajoutant un dossier `Strings/de` parasite et en confirmant l'échec. En prime, la liste « ajouter une langue » du README n'a plus besoin d'une ligne « et mettre à jour les tests » — les tests suivent les ressources.
