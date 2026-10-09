---
title: "Messages, Plans et Contacts ne se lancent plus sous macOS 27 ? La solution : un nouveau profil"
description: "Après être passé de la bêta de macOS 27 à la version finale, Messages restait bloqué, Plans et Contacts ne démarraient plus et Réglages Système plantait. La cause était mon profil utilisateur, pas macOS — et la solution a été d'en créer un nouveau."
date: 2026-10-07
tags:
  - Troubleshooting
---

## Le symptôme

Après être passé de la bêta de macOS 27 à la version finale (27.0.1), trois applications d'Apple ont cessé de fonctionner chez moi. Messages rebondissait indéfiniment dans le Dock et apparaissait comme « Ne répond pas » dans Forcer à quitter. Plans et Contacts ne démarraient pas du tout. Cliquer sur Messages dans Réglages Système faisait planter Réglages Système, et la tentative de me déconnecter d'iCloud laissait la fenêtre tourner indéfiniment sur « Déconnexion ».

Tout fonctionnait très bien sur la bêta, jusqu'au moment où j'ai installé la version finale. Quand j'ai enfin réussi à me déconnecter d'iCloud puis à me reconnecter, cela n'a rien changé.

## macOS ou moi ?

Le test le plus utile a pris deux minutes : **créer un nouveau compte utilisateur et y essayer les applications.** Messages, Plans et Contacts fonctionnaient parfaitement dans le nouveau compte, sur le même Mac, avec la même version de macOS.

Ce seul résultat a changé toute l'enquête. Le système d'exploitation n'était pas en cause. C'étaient les données de *mon* profil qui étaient endommagées.

## Cerner le problème

Contacts semblait le suspect évident, puisque Messages et Plans s'appuient dessus. J'ai donc déplacé le dossier `AddressBook` hors de `~/Library/Application Support/`. Contacts en a simplement recréé un neuf, sans aucun changement.

Ce sont les fichiers de préférences des applications concernées qui ont fait avancer les choses. Après les avoir déplacés puis redémarré, Contacts et Plans se relançaient à nouveau :

```text
~/Library/Preferences/com.apple.AddressBook*
~/Library/Preferences/com.apple.Maps*
~/Library/Preferences/com.apple.systempreferences*
```

Messages, lui, restait bloqué.

## Lire l'échantillon

Pour Messages, j'ai ouvert Moniteur d'activité pendant que l'application rebondissait, je l'ai sélectionnée et j'ai choisi **Échantillonner le processus** dans le menu engrenage. L'application ne plantait pas : elle *attendait*. Le fil principal était bloqué au lancement dans `IMCore`, en attente d'une file de dispatch, et cette file était elle-même bloquée sur un appel synchrone vers un démon en arrière-plan :

```text
com.apple.IMCore.DaemonConnectionSetup
  -[NSXPCConnection _sendInvocation:...]
    __NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__
```

Un deuxième fil était dans le même état, en attente de la réponse d'un autre service :

```text
com.apple.telephonyutilities.callcapabilitiesxpcclient
  -[TUCallCapabilitiesXPCClient _retrieveState]
```

Messages attendait donc indéfiniment des services d'arrière-plan qui ne répondaient jamais. Ces démons s'exécutent par utilisateur et conservent leur propre état, ce qui concorde avec le fait que le nouveau compte fonctionnait.

## Ce qui n'a pas marché

J'ai redémarré les démons probables, que macOS relance automatiquement :

```bash
killall imagent identityservicesd callservicesd
```

Puis j'ai déplacé l'état d'iMessage et des services d'identité — les fichiers de préférences `com.apple.imagent*`, `com.apple.madrid*`, `com.apple.imservice*`, `com.apple.identityservices*` et `com.apple.TelephonyUtilities*`, ainsi que `~/Library/IdentityServices/`. Rien n'a réparé Messages.

J'ai aussi envisagé de réinstaller macOS, mais une réinstallation depuis la Récupération ne touche pas aux données utilisateur, y compris tout ce qui se trouve dans `~/Library`. Le nouveau compte avait déjà montré que les fichiers système étaient sains ; cela m'aurait très probablement ramené droit au même blocage.

## La solution : j'ai créé un nouveau profil

À ce stade, j'ai arrêté de tâtonner. Je suppose que quelque chose d'hérité de la bêta dans les données de mon ancien profil perturbait la version finale, et je n'allais pas le trouver par essais et erreurs. J'ai donc **recréé un nouveau profil** :

1. Sauvegarder d'abord : un passage de Time Machine, plus une copie de `~/Library/Messages`, qui contient l'historique de vos messages si vous ne le synchronisez pas via iCloud.
2. Créer un nouvel utilisateur, se connecter à iCloud et activer Messages, Contacts et le reste.
3. Copier les fichiers — Documents, Bureau, Téléchargements, Images — en laissant volontairement `Library` de côté, car c'est là que se trouve le problème.

Messages, Plans, Contacts et Réglages Système fonctionnent tous dans le nouveau profil.

## À retenir

Si plusieurs applications intégrées d'Apple tombent en panne en même temps après une mise à niveau, surtout d'une bêta vers une version finale, **testez avec un tout nouveau compte utilisateur avant de toucher à quoi que ce soit d'autre.** Cela prend deux minutes et vous dit si vous luttez contre macOS ou contre votre propre profil. Si le nouveau compte fonctionne, oubliez la réinstallation et la chirurgie interminable des préférences.

Dans mon cas, c'était mon profil, et **j'ai recréé un nouveau profil pour résoudre le problème.**
