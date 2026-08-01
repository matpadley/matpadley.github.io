---
title: "Des Codes d'Erreur, Pas de la Prose Traduite : Rendre une API Multilingue"
date: 2026-07-31T16:00:00+01:00
draft: false
description: "Traduire les messages d'échec d'une API fait de chaque phrase une partie du contrat réseau, et échoue dès que le destinataire n'est pas l'appelant. L'API de Club Monitor renvoie plutôt des codes d'erreur stables — et le balayage n'est devenu démontrable qu'une fois l'argument de code rendu obligatoire."
summary: "Traduire les messages d'échec d'une API fait de chaque phrase une partie du contrat réseau, et échoue dès que le destinataire n'est pas l'appelant. L'API de Club Monitor renvoie plutôt des codes d'erreur stables — et le balayage n'est devenu démontrable qu'une fois l'argument de code rendu obligatoire."
tags:
  - club-monitor
  - dotnet
  - localization
  - api-design
  - entity-framework
  - testing
source:
  - "2026-07-31-1200-multilingual-plan-and-spec-update.md"
  - "2026-07-31-1230-multilingual-phase-0-decisions.md"
  - "2026-07-31-0940-multilingual-phase-1-backend-groundwork.md"
  - "2026-07-31-1300-multilingual-phase-2-auth-error-codes.md"
  - "2026-07-31-1500-multilingual-phase-2-remaining-error-codes.md"
  - "2026-07-31-1600-multilingual-phase-3-localized-notifications.md"
---

Club Monitor n'avait aucune localisation : chaque message de handler, chaque modèle d'e-mail et chaque chaîne XAML était de l'anglais codé en dur. Rendre l'application entière multilingue — anglais, français et espagnol — touche presque tous les handlers et toutes les pages, ce travail a donc été mené comme un plan par phases plutôt que comme un seul changement gigantesque. Voici la moitié back-end : les décisions, le contrat de codes d'erreur et les modèles de notification.

## La décision qui conditionne tout le reste

La première question est faussement simple : lorsque l'API refuse une requête, dans quelle langue est le refus ?

La réponse tentante consiste à traduire le message — lire `Accept-Language`, choisir une ressource, renvoyer de la prose française. C'est aussi la mauvaise. Elle fait de chaque message d'échec une partie du contrat réseau : améliorer la formulation anglaise casse alors silencieusement les clients qui font correspondre ce texte. Elle oblige le serveur à posséder les traductions d'un texte qu'il n'affiche jamais. Et elle échoue purement et simplement dès que le destinataire d'un message n'est pas l'appelant.

L'API ne traduit donc pas. `HandlerResult<T>` conserve son énumération `HandlerError` existante, qui détermine le statut HTTP, et en gagne une seconde : `ErrorCode`, avec un membre par échec distinct. Le corps de la réponse devient :

```json
{ "error": "ClubNotFound", "message": "Club not found." }
```

`error` est le contrat stable sur lequel les clients s'appuient. `message` est un repli diagnostique en anglais uniquement, qu'aucun client ne devrait jamais afficher tel quel. Chaque client possède ses propres traductions et fait correspondre les codes à ses propres chaînes localisées.

La seconde décision découle du même raisonnement. Certains contenus sont réellement générés par le serveur — un code de double facteur par e-mail ou SMS, une notification d'invitation plus tard. Ce texte doit bien être dans *une* langue, et `Accept-Language` sur la requête déclenchante n'aide en rien, car le destinataire n'est fréquemment pas l'appelant : un Admin qui invite un membre, c'est une personne qui agit et une autre qui lit. L'enregistrement utilisateur a donc gagné un `PreferredLanguage` BCP-47 nullable (`null` signifiant `en`), exposé sur `GET /api/auth/me` et modifiable via `PUT /api/auth/language`.

## Faire grandir l'énumération sans tout arrêter

La première phase d'implémentation n'a ajouté que de l'infrastructure : l'énumération `ErrorCode` avec un petit jeu initial, une propriété `Code` sur `HandlerResult<T>`, la nouvelle forme de réponse, une constante `SupportedCultures`, la colonne `PreferredLanguage` et sa migration, ainsi que le handler et l'endpoint pour la définir.

L'astuce qui a gardé le tout relisible a été de rendre le nouvel argument optionnel — `ErrorCode code = ErrorCode.Unspecified` — de sorte que chaque site d'appel existant dans le code continuait à compiler sans modification. Le balayage pouvait alors progresser un domaine fonctionnel à la fois.

L'authentification est passée en premier, étant la plus visible pour l'utilisateur : 22 nouveaux codes répartis sur 52 sites d'appel dans douze handlers. Les domaines restants — Clubs, Compétitions, Matchs, Adhésions et Sports — en ont ajouté 27 autres.

Deux arbitrages reviennent tout du long :

- **Les erreurs propres à Identity se replient sur un seul code.** Les échecs composés à partir de `IdentityResult.Errors` (création de compte, définition d'un mot de passe, activation du double facteur) correspondent tous à `IdentityOperationFailed`. Le message est déjà la chaîne anglaise composée par Identity elle-même et ne se découpe pas utilement en codes plus fins.
- **Un même concept réutilise un même code.** `NotClubAdmin` couvre chaque garde d'Admin de club ; `MembershipNotFound` couvre une invitation, une demande d'adhésion ou un membre absent ; `PhoneNumberRequired` couvre à la fois l'activation du double facteur par SMS sans numéro et l'envoi d'un code vers un compte qui n'en a aucun.

Vient ensuite ce qui a rendu le balayage démontrable. Tous les sites d'appel convertis, la valeur par défaut a été retirée : `NotFound`, `Forbidden`, `Invalid` et `Conflict` *exigent* désormais un code. Que l'API compile proprement avec le paramètre obligatoire est la preuve que rien n'a été oublié — et désormais un nouveau chemin d'échec ne peut pas compiler sans nommer son code. `Unspecified` ne survit que comme valeur zéro de l'énumération, portée par les résultats réussis.

## Un fixture de test qui mentait

Ajouter la couverture des chemins d'échec pour le balayage a révélé un bug dans les tests plutôt que dans le code. `SeedData` ne définissait qu'`Email` sur ses utilisateurs de départ, alors qu'Identity écrit aussi `NormalizedEmail`, `UserName`, `NormalizedUserName` et `SecurityStamp`. `InviteMemberHandler` recherche les utilisateurs par `NormalizedEmail` : il manquait donc silencieusement chaque utilisateur du jeu de données et traitait une invitation en double comme une toute nouvelle. Le nouveau test `Inviting_an_existing_member_conflicts` a échoué jusqu'à ce que le jeu de données corresponde à ce qu'Identity écrit réellement. Le handler avait toujours raison ; le fixture, non.

## Localiser ce que le serveur envoie vraiment

`PreferredLanguage` en place, l'e-mail et le SMS de double facteur sont devenus la première sortie serveur réellement traduite : `NotificationStrings.resx` et ses variantes `.fr` et `.es`, avec des clés pour l'objet de l'e-mail, le corps de l'e-mail et le corps du SMS. Chaque entrée porte un commentaire de traduction précisant que « Club Monitor » est un nom de produit, ce qu'est `{0}`, et que la chaîne SMS doit tenir dans un unique segment de 160 caractères.

La contrainte intéressante est ce qu'il ne faut *pas* utiliser. `IStringLocalizer` est l'outil évident et le mauvais : il résout toujours par rapport à la `CultureInfo.CurrentUICulture` ambiante, qui sur une requête d'API est la culture de l'appelant — exactement la mauvaise source quand le destinataire est quelqu'un d'autre. `NotificationTemplates` prend plutôt la culture en argument et appelle `ResourceManager.GetString(key, culture)`, la surcharge officielle qui en accepte une directement. Cela évite également de muter la culture ambiante sur un thread de requête partagé.

Les préférences obsolètes se replient plutôt que de lever une exception. Si une langue est retirée de `SupportedCultures` après que des utilisateurs l'ont choisie, ces comptes doivent tout de même pouvoir recevoir un code de connexion.

## Tester des traductions qui échouent en silence

Treize tests couvrent les notifications, et deux d'entre eux n'existent que par la discrétion avec laquelle cela peut casser.

`ResourceManager` se replie sur la ressource neutre lorsqu'une clé manque dans un assembly satellite. Une chaîne non traduite paraît donc parfaitement saine à l'exécution — elle affiche simplement de l'anglais. Un test vérifie donc que le rendu de chaque culture non par défaut *diffère* effectivement de l'anglais.

L'autre extrait le code de l'e-mail **français** et le valide via `VerifyTwoFactorCodeHandler`. Une traduction ayant perdu son marqueur `{0}` s'afficherait magnifiquement et verrouillerait l'utilisateur dehors.

La suite d'API est passée de 61 à 103 tests réussis au fil de ces phases. Et `bin/Debug/net10.0/fr/ClubMonitor.Api.resources.dll` apparaît sans la moindre modification du `.csproj` — le SDK récupère les fichiers `.resx` tout seul.
