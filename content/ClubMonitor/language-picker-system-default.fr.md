---
title: "Le Sélecteur de Langue Qui ne Pouvait pas se Défaire"
date: 2026-08-01T10:30:00+01:00
draft: false
description: "Ajouter une option « Langue du système » aurait dû prendre quinze minutes. Elle était sans effet précisément dans le cas pour lequel elle existe, car Uno persiste la surcharge de langue et l'applique avant tout code applicatif — demander à la culture ambiante le réglage de l'appareil renvoie donc le choix précédent de l'application elle-même."
summary: "Ajouter une option « Langue du système » aurait dû prendre quinze minutes. Elle était sans effet précisément dans le cas pour lequel elle existe, car Uno persiste la surcharge de langue et l'applique avant tout code applicatif — demander à la culture ambiante le réglage de l'appareil renvoie donc le choix précédent de l'application elle-même."
tags:
  - club-monitor
  - uno-platform
  - localization
  - debugging
  - webassembly
  - testing
source: "2026-08-01-1030-language-picker-system-default.md"
---

Le sélecteur de langue est sorti avec trois entrées — English, Français, Español — et aucun moyen de cesser de suivre un choix explicite. Une surcharge pouvait être modifiée, jamais annulée. Combler ce manque ressemblait à un travail de quinze minutes : ajouter une entrée **Langue du système**, effacer la surcharge stockée, réafficher. Cela n'a pas fonctionné, et la raison dormait dans le code depuis la création même du sélecteur.

## Ce que « Langue du système » doit signifier

Effacer la surcharge n'en est que la moitié. Le compte a tout de même besoin d'une langue concrète, car les e-mails et les SMS sont composés sur un serveur qui ne peut pas voir la locale du système de cet appareil. La réponse honnête est la langue que l'application affiche désormais : `FollowSystem()` efface donc la surcharge, réaffiche, et synchronise avec le compte la culture effective qui en résulte.

Le sélecteur doit aussi *montrer* la bonne chose. Lorsqu'aucune surcharge n'est stockée, il affiche **Langue du système** comme sélectionnée, plutôt que de mettre en évidence la langue qui s'est trouvée résolue — mettre « Español » en évidence revendiquerait un choix que l'utilisateur n'a jamais fait.

La nouvelle entrée est d'ailleurs le seul élément de cette liste qui soit traduit. Les noms de langues à côté d'elle sont des endonymes et restent identiques dans toutes les cultures ; « System default » est une expression, elle devient donc « Langue du système » et « Idioma del sistema ».

## Pourquoi cela ne fonctionnait pas

**Uno persiste `ApplicationLanguages.PrimaryLanguageOverride` entre les redémarrages et l'applique avant l'exécution du moindre code applicatif.**

Le service de culture répondait à la question « quelle langue cet appareil utilise-t-il ? » en lisant `CultureInfo.CurrentUICulture`. À partir du deuxième lancement, cela renvoie la langue *que l'application elle-même a choisie la fois précédente*. Le code d'origine se prémunissait déjà contre cela au sein d'une session, en capturant la valeur tôt au démarrage — mais un instantané ne survit pas à un redémarrage, car la contamination survient avant qu'il y ait quoi que ce soit à capturer.

Déroulons cela sur un appareil allemand. Choisir l'espagnol. Redémarrer. Appuyer sur Langue du système. La surcharge est effacée, l'application demande « quelle est la langue de l'appareil ? », on lui répond « espagnol », et elle reste en espagnol.

La fonctionnalité était sans effet précisément dans le cas pour lequel elle existe.

`ReadDeviceLanguage()` déduit désormais la langue de l'appareil d'`ApplicationLanguages.Languages` avec la surcharge active retirée. Uno place la surcharge en tête de la liste propre à l'appareil : la supprimer laisse donc la vérité en dessous. `GlobalizationPreferences.Languages` est l'API que WinUI documente exactement pour cela et aurait été le correctif évident — mais la tête WebAssembly d'Uno y lève `NotImplementedException`, ce qu'a confirmé l'instrumentation de l'application en cours d'exécution.

## Comment cela a été trouvé

Pas en lisant le code.

Le sélecteur des paramètres vit à l'intérieur du canvas Skia et ne peut pas être cliqué depuis Playwright ; le cycle de vie a donc été piloté directement via la surcharge stockée : charger l'application trois fois dans un contexte de navigateur `de-DE` et observer ce qu'elle résout. Le troisième chargement a renvoyé l'espagnol là où l'anglais était attendu. Instrumenter le service de culture et capturer la console du navigateur a produit les valeurs réelles — `appLangs=[es,de-DE]`, `currentUI=es`, et `GlobalizationPreferences` levant une exception — ce qui a identifié à la fois la cause et le correctif.

Voilà tout le diagnostic, et rien de tout cela n'était visible depuis les sources. Un bug qui n'apparaît qu'au second lancement est invisible lors d'un premier essai, et celui-ci est également invisible en relecture de code : lire `CurrentUICulture` pour connaître la langue de l'appareil paraît tout à fait raisonnable tant qu'on ignore qu'Uno l'a déjà écrasée.

## Ce qui le protège désormais

Deux tests, aux rôles différents.

`An_explicit_choice_sticks_across_restarts_and_System_default_undoes_it` parcourt tout le cycle de vie sur un appareil allemand — c'est-à-dire non pris en charge : il démarre en anglais sans surcharge stockée, conserve l'espagnol après un redémarrage une fois celui-ci choisi, et revient à l'anglais une fois la surcharge effacée. Il a été vérifié contre l'ancienne logique, où rétablir `ReadDeviceLanguage` reproduit l'échec sous la forme « L'effacement de la surcharge a laissé l'application dans la langue qui venait d'être effacée. »

Le test pilote la surcharge stockée plutôt que le sélecteur lui-même, puisque le contrôle est à l'intérieur du canvas — et il le dit dans ses propres commentaires. Ce qu'il couvre réellement, c'est le comportement au redémarrage, là où tout est parti de travers.

Le second est statique : `The_language_picker_offers_every_supported_culture_and_the_system_default` fige les balises `ComboBoxItem` du sélecteur sur `SupportedCultures.All` plus `system`. Ajouter une langue pourrait sinon livrer une culture entièrement traduite mais inaccessible depuis les Paramètres, ce que rien d'autre n'aurait détecté — brancher le sélecteur est une étape manuelle du README.

Le piège « ne jamais lire `CurrentUICulture` pour savoir sur quoi l'*appareil* est réglé » est désormais consigné dans les trois documents du projet. Il est invisible au premier lancement et ne mord qu'après un redémarrage, ce qui est exactement le genre de chose qu'on redécouvre à la manière coûteuse.
