---
title: "La semaine où Club Monitor est devenu un dépôt"
date: 2026-08-22T09:00:00+01:00
draft: false
description: "Sept semaines de travail jamais commité ont enfin reçu un historique git, le front end a gagné une navigation et de vrais écrans, le pipeline OpenAPI a été reconstruit deux fois, et le rôle de Super Admin a été coupé en deux après qu'on a découvert qu'il lisait les données de tous les clubs."
summary: "Sept semaines de travail jamais commité ont enfin reçu un historique git, le front end a gagné une navigation et de vrais écrans, le pipeline OpenAPI a été reconstruit deux fois, et le rôle de Super Admin a été coupé en deux après qu'on a découvert qu'il lisait les données de tous les clubs."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - openapi
  - multi-tenancy
  - security
source:
  - 2026-08-19-0930-docs-uno-to-avalonia.md
  - 2026-08-19-1500-fix-browser-session-store-module-path.md
  - 2026-08-19-1630-add-shell-side-nav-burger-menu.md
  - 2026-08-20-1400-cups-header-layout.md
  - 2026-08-20-1500-cups-add-modal.md
  - 2026-08-20-1530-fix-cups-header-grid-not-stretching.md
  - 2026-08-20-1600-cups-list-seeded-from-swagger-model.md
  - 2026-08-20-1600-leagues-members-add-modal.md
  - 2026-08-20-1700-shared-theme-colour-palette.md
  - 2026-08-20-1730-add-swagger.md
  - 2026-08-20-1800-fix-swagger-codegen-path-traversal-false-positive.md
  - 2026-08-20-1900-openapi-typed-responses.md
  - 2026-08-20-1930-fix-swagger-codegen-additionalproperties-bug.md
  - 2026-08-20-1945-no-tests-for-generated-swagger-code.md
  - 2026-08-20-2015-fix-swagger-codegen-jsonconverter-errors.md
  - 2026-08-20-2030-serve-swagger-ui-in-development.md
  - 2026-08-20-2130-migrate-to-builtin-openapi.md
  - 2026-08-21-0830-code-review-and-commit-subagents.md
  - 2026-08-21-0900-initial-import.md
  - 2026-08-21-1030-members-delete-button-and-swipe.md
  - 2026-08-21-1030-screen-builder-subagent.md
  - 2026-08-21-1200-members-edit-button-and-tap.md
  - 2026-08-21-1330-member-edit-page.md
  - 2026-08-21-1500-cups-leagues-edit-and-delete.md
  - 2026-08-21-1630-user-groups-permission-bundles.md
  - 2026-08-21-1800-super-admin-tenancy-boundary.md
  - 2026-08-22-0900-club-self-service-sports-and-creation.md
---

Deux semaines calmes, puis la période la plus chargée qu'ait connue le projet. Entre le 19 et le
22 août, Club Monitor a obtenu son premier commit, un shell de navigation, trois écrans de liste
fonctionnels, un pipeline OpenAPI construit puis jeté, et un correctif de sécurité qui a démonté un
rôle pour le remonter en plus petit.

## D'abord, les documents mentaient

Le front end de ce dépôt est une solution **Avalonia 12.1.1** depuis un certain temps. Tous les
documents de référence décrivaient encore un projet unique **Uno Platform** — et ce n'est pas un
décalage cosmétique, car les deux frameworks divergent sur presque chaque API que touche une
modification du front end. Quiconque lisait `CLAUDE.md` ou la spécification se serait tourné vers
`x:Uid`, les fichiers `.resw`, `AdaptiveTrigger` et
`ApplicationLanguages.PrimaryLanguageOverride`, dont aucun n'existe dans Avalonia.

La semaine s'est donc ouverte sur une réécriture de la documentation : `.resx` et `{x:Static}` au
lieu de `.resw` et `x:Uid`, `ContainerQuery` au lieu d'`AdaptiveTrigger`, une bibliothèque partagée
plus un projet par tête au lieu d'un projet unique, et `Avalonia.Headless.NUnit` désigné comme
l'endroit où vivent les assertions d'interface.

Le piège de la localisation devait être réécrit plutôt que traduit. Avalonia n'a aucune API de
substitution de langue au niveau de la plateforme, donc l'application applique la sienne en
définissant `CultureInfo.DefaultThreadCurrentUICulture` — après quoi la culture ambiante rapporte le
dernier choix de l'application, pas celui du système d'exploitation. La locale de l'OS doit être
capturée au démarrage **avant** que la substitution ne soit appliquée, sinon elle a disparu.

Deux documents plus anciens — le plan multilingue et une revue de sécurité d'août — n'ont
délibérément **pas** été réécrits. Ce sont des instantanés d'un travail achevé sur le front end Uno,
et transformer leurs cases cochées en affirmations Avalonia aurait falsifié l'histoire. Chacun a
reçu une bannière de remplacement à la place.

## Un shell pour naviguer, et un bug caché dans la précédence des valeurs d'Avalonia

L'application n'avait aucune navigation après la connexion : on se connectait et on atterrissait sur
une page d'accueil nue, sans moyen d'atteindre quoi que ce soit d'autre. Elle a maintenant un shell
persistant Accueil/Membres/Ligues/Classements — une barre latérale sur les grandes largeurs, un
bouton burger ouvrant un menu coulissant sur les étroites.

Le choix se fait **par la largeur, jamais par la plateforme**. Une `ContainerQuery` à 720px décide,
donc un navigateur de téléphone obtient la disposition téléphone, et une fenêtre de bureau étroite
aussi.

Sauf qu'au début elle ne décidait rien. La barre latérale et la barre supérieure étaient écrites
avec `IsVisible="True"` et `IsVisible="False"` comme attributs XAML locaux, et la précédence des
valeurs d'Avalonia place une valeur locale au-dessus de tout setter de style — les setters de la
container query étaient donc silencieusement sans effet et la disposition ne changeait à aucune
largeur. Le correctif a consisté à déplacer la valeur par défaut et la valeur interrogée dans des
setters de `Style`. C'est le test headless écrit pour le cas étroit qui l'a attrapé, échouant sur
« Expected False, but was True » jusqu'à ce que les attributs locaux disparaissent.

Ce test avait besoin d'un endroit où vivre, d'où l'existence de `tests/ClubMonitor.UiTests` — le
projet auquel les règles se référaient depuis des semaines sans que rien ne l'ait créé. Il a aussi
fait surgir un petit problème à l'échelle du processus : `Avalonia.Headless.NUnit` construit une
nouvelle `App` par test dans le même processus, et l'état d'attachement des DevTools est global au
processus, si bien que le deuxième test levait une exception dans `App.Initialize()` jusqu'à ce que
l'attachement soit protégé par un drapeau statique.

Un bug distinct, plus tranchant, avait déjà bloqué entièrement la tête WebAssembly.
`LocalStorageSessionStore` importait `"./session-store.js"` et récoltait un 404 sur
`_framework/session-store.js`, de sorte que l'application ne dépassait jamais `Program.Main`. Le
spécificateur de module dans `JSHost.ImportAsync` se résout relativement à l'emplacement du
*runtime* — `_framework/`, où vit `dotnet.js` — et non à la racine de l'application. Le `../` initial
est porteur, et il est désormais accompagné d'une note `<remarks>` qui le dit, car il ressemble
exactement à ce qu'un nettoyage supprimerait.

## Trois écrans, et le même bug de disposition deux fois

Coupes, Ligues et Membres ont chacun reçu un en-tête avec le titre en haut à gauche et un bouton
« + » en haut à droite, une boîte de dialogue d'ajout, puis des actions Modifier et Supprimer par
ligne.

Les dialogues sont des **superpositions dans la vue**, pas des `Window` : les têtes Browser et iOS
s'exécutent sous des cycles de vie à vue unique sans prise en charge des fenêtres enfants, donc un
dialogue basé sur une `Window` ne fonctionnerait que sur le bureau.

Le bouton « + » est resté un moment collé au titre au lieu de se placer au bord droit, malgré un
`Grid ColumnDefinitions="*,Auto"` qui aurait dû l'y pousser. La cause tenait à un attribut sur un
ancêtre : le `StackPanel` de contenu avait `HorizontalAlignment="Left"`, ce qui fait qu'un panneau
se dimensionne à son propre contenu plutôt qu'à son `MaxWidth`. Le `Grid` d'Avalonia donne aux
colonnes étoilées une largeur effectivement nulle lors du calcul de son propre `DesiredSize` — une
colonne étoilée est résolue pendant l'*arrange*, contre la taille finale que le parent renvoie — de
sorte qu'un parent qui se rétracte sur son contenu ne laissait rien dans quoi la colonne étoilée
puisse s'étendre. Supprimer l'alignement a corrigé le problème sans rien déplacer visuellement, car
`MaxWidth` dispose déjà un élément plafonné comme s'il était aligné à gauche. Un test de
non-régression vérifie le `Bounds.Right` du bouton : il échoue à 266 sur l'ancien balisage et passe
à 640 sur le correctif.

Les actions de ligne ont ensuite atterri sur les trois listes, et l'affordance est de nouveau
choisie par la largeur — cette fois à **500px, pas 720**. Les listes occupent la zone de contenu du
shell, plus étroite de 220px que la fenêtre partout où la barre latérale s'affiche ; à 720, une
fenêtre de bureau ordinaire serait tombée dans la disposition tactile, et
`SwipeGestureRecognizer.IsMouseEnabled` vaut `false` par défaut, donc un utilisateur à la souris
n'aurait eu aucun moyen de supprimer quoi que ce soit.

Les grandes largeurs obtiennent des boutons Modifier et Supprimer. Les étroites obtiennent une
**tape** pour modifier et un **balayage vers la gauche** pour supprimer, avec une ligne d'aide qui
le dit. Trois détails des reconnaisseurs de gestes d'Avalonia se sont révélés importants :

- `SwipeGestureEvent` et `TappedEvent` **remontent** tous deux, si bien qu'un seul gestionnaire sur
  l'`ItemsControl` voit chaque ligne — ce qui rend la chose praticable, puisqu'un `DataTemplate` ne
  peut pas porter de `x:Name`.
- Le reconnaisseur lève `SwipeGesture` **de façon répétée** tant que le doigt bouge, donc le
  gestionnaire enregistre `SwipeGestureEventArgs.Id` et ignore les répétitions d'un geste déjà
  traité.
- `Delta` vaut *départ moins courant*, donc un X positif est un doigt qui va vers la **gauche**. Le
  code lit `SwipeDirection` à la place, et un test fixe la correspondance pour que le signe ne
  ressemble pas à une faute de frappe.

À la troisième copie, deux morceaux ont été extraits plutôt que triplés : `IEditPage<TItem>`, qui
permet à `ShellViewModel.OpenEditPage` de posséder une seule fois ouverture/enregistrement/annulation
/désabonnement, et `RowGestures<TItem>`, qui a fait passer `MembersView.axaml.cs` d'environ soixante-dix
lignes de gestionnaire à un unique appel `Attach` et a offert le comportement à Coupes et Ligues.

La modification est aussi sortie d'une superposition pour occuper sa propre page — avec la règle que
**la liste ne navigue pas elle-même**. `MembersViewModel` lève `EditMemberRequested` ; le shell
possède la transition. Cela garde la page testable isolément et garde la connaissance de la
navigation dans le seul view model qui l'a déjà. La page de modification n'est délibérément pas une
destination de navigation : `SelectedNavKey` reste sur Membres tant qu'elle est ouverte, donc la
surbrillance de la barre latérale et le menu burger continuent de se comporter correctement.

En parallèle, l'équivalent de cinq vues de dictionnaires de couleurs quasi dupliqués a été
consolidé dans un unique `Themes/Theme.axaml` avec des clés sémantiques. Ce n'est pas du rangement
pour le rangement : les personnalisations de marque d'un club sont spécifiées comme des
remplacements de ces mêmes clés au niveau de l'application, donc une vue qui déclare sa propre copie
est une vue que la personnalisation ne peut pas atteindre.

## Un garde-fou de localisation qui a dû être écrit deux fois

`LocalizationTests` a été ajouté pour vérifier que les fichiers `.resx` anglais, français et
espagnol restent en parité. La première version passait contre une clé française délibérément
cassée, ce qui est une bonne raison de saboter ses propres tests avant de leur faire confiance : une
recherche de ressource qui manque un satellite **retombe sur la ressource neutre**, donc une
traduction française manquante s'affiche en anglais et aucun test passant par `ResourceManager` ne
peut la voir.

La version qui fonctionne compare les fichiers `.resx` en tant que fichiers, jeu de clés contre jeu
de clés. Relancée contre le même sabotage, elle nomme à la fois la clé non traduite et celle mal
orthographiée.

## Le pipeline OpenAPI, construit puis remplacé

C'est le fil le plus long de la semaine, et il s'est terminé ailleurs qu'il n'avait commencé.

Il a démarré avec Swashbuckle et un schéma de sécurité JWT bearer, réservé au développement — une
instance déployée décrivant ses propres routes et DTO est exactement le genre de détail interne dont
le point de terminaison anonyme `/health` est délibérément tenu à l'écart.

Puis une question sur la nécessité d'un view model séparé pour un handler a fait surgir quelque
chose de systémique : le client généré produisait `public void ApiMembersGet()` pour chaque route,
parce qu'aucun point de terminaison ne déclarait de métadonnées de réponse OpenAPI. Chaque route
Minimal API des huit fichiers de points de terminaison a reçu `.WithName()`, `.WithTags()` et une
extension `ProducesHandlerResult<T>()` déclarant le schéma de succès plus un `ErrorResponse` nommé
pour 400/401/403/404/409. Le marquage par fonctionnalité a aussi scindé la sortie générée d'une
classe unique d'environ 8 600 lignes en une classe par fonctionnalité. Les deux routes de
redirection destinées à la navigation du navigateur ont été entièrement exclues de la description —
une méthode de client générée qui les appellerait ne ferait que suivre la redirection.

Puis le générateur lui-même s'est mis à échouer, trois fois de suite :

1. **Un faux positif de traversée de chemin.** Le fork vendu de swagger-codegen rejette tout chemin
   contenant `..`, et l'argument `-o ../club_monitor/...` du script lui-même le déclenchait. Corrigé
   en canonisant le répertoire de sortie là où l'argument de la ligne de commande est stocké — et
   non en affaiblissant le contrôle de traversée, qui est une protection légitime contre des noms de
   fichiers issus de la spécification qui s'échapperaient pendant la génération.
2. **`Dictionary<String, >` sur 44 des 46 modèles générés.** Chaque record sur lequel Swashbuckle
   fait de la réflexion obtient `additionalProperties: false`, et le modèle C# du générateur émet un
   type de base `Dictionary` dès que `additionalProperties` est présent — en laissant l'argument
   générique vide quand aucun schéma ne vient le remplir. Comme rien dans la base de code ne valide
   les corps de requête contre leur schéma JSON, le drapeau était informatif, et un transformateur
   de schéma le supprimant ne coûtait rien.
3. **Une avalanche de références `JsonConverter` non résolues.** Le projet généré émettait une
   disposition héritée `.NET Framework 4.5` + `packages.config` dont le `HintPath` pointait vers un
   dossier que rien ne restaure. Passer le générateur en sortie de style SDK a réglé le problème,
   avec un `Directory.Packages.props` local masquant celui du dépôt — la gestion centralisée des
   paquets de NuGet utilise le fichier **le plus proche** en remontant et ne fusionne pas, donc un
   sous-arbre avec des versions en ligne a besoin du sien.

Une règle est entrée dans `CLAUDE.md` au passage : **ne jamais écrire de tests pour le client
généré**. Cet arbre est régénéré intégralement à chaque exécution — c'est arrivé deux fois en un
après-midi — donc des tests écrits à la main contre lui ne feraient que réaffirmer la sortie du
générateur avant d'être silencieusement écrasés.

Puis toute la couche Swashbuckle est sortie. ASP.NET Core 10 livre un générateur OpenAPI de première
partie, donc `AddOpenApi`/`MapOpenApi` a remplacé `AddSwaggerGen`, Scalar a remplacé l'interface
Swagger comme explorateur réservé au développement, et le filtre de schéma a été porté vers un
`IOpenApiSchemaTransformer`. Le schéma bearer est devenu un transformateur de document activé par
injection de dépendances qui découvre le schéma JWT enregistré via `IAuthenticationSchemeProvider`.
`Microsoft.OpenApi` a été épinglé explicitement en 2.12.0, car la version arrivant de manière
transitive porte un avis de sécurité connu de gravité élevée (débordement de pile par références
circulaires de schémas).

Le résultat est un document OpenAPI 3.1.1 avec 48 schémas, un schéma bearer appliqué à chaque
opération, et une compilation propre sans avertissement de paquet vulnérable.

## Le dépôt a enfin eu un dépôt

Au matin du 21, `git log` échouait encore sur une branche non née et sans HEAD. Tout ce qui précède,
et tout ce des sept semaines antérieures, n'existait que sur le disque.

L'import initial a commité les 545 fichiers comme premier commit, après avoir revérifié que
`.gitignore` excluait la sortie de build et qu'aucun `.pfx`, `.env`, profil de publication ou
`secrets.json` n'avait été indexé. Comme le hook de sécurité git du dépôt refuse les commits
directement sur `main` ou `master` — et qu'il n'y avait pas encore de `main` d'où partir — l'import
a atterri sur une branche issue du HEAD non né.

Trois sous-agents de projet ont été écrits à la même période, pour que la revue et l'atterrissage
soient des étapes séparées et explicitement délimitées : un `code-reviewer` en lecture seule portant
les pièges propres à ce dépôt sous forme de liste de contrôle, un `change-committer` qui applique
les conclusions et ouvre la PR sans contourner les hooks git, et un `screen-builder` qui connaît les
huit endroits qu'un nouvel écran touche — ceux qu'on oublie étant le câblage, pas la vue.

## Puis le modèle d'autorisation a été reconstruit, deux fois en deux jours

L'appartenance n'avait que deux rôles, `Standard` et `Admin`, si bien qu'un club ne pouvait dire que
« tout » ou « rien ». Un club voulant un trésorier devait céder la personnalisation, les
compétitions, les membres et l'abonnement avec.

La première réponse a été les groupes d'utilisateurs : sept permissions, des octrois dans une table
enfant plutôt qu'un masque de bits pour rester lisibles dans les migrations, et une appartenance de
groupe pointant vers `Membership` plutôt que `User` — de sorte qu'un groupe n'a de sens qu'à
l'intérieur de son propre club, retirer quelqu'un d'un club emporte ses octrois, et « un utilisateur
du club B dans un groupe du club A » est irreprésentable.

Ce qui mérite d'être noté, c'est ce qui n'a **pas** changé. La demande portait sur quelque chose qui
fonctionne avec les passkeys et l'authentification tierce autant qu'avec les mots de passe, et **pas
une ligne du code de connexion n'a changé**. Chaque chemin — mot de passe, fournisseur externe,
passkey, les deux compléments de double facteur, inscription, sélection de club — converge vers une
fabrique unique où le jeton est frappé, et ce jeton porte le sujet, le club actif, le tampon de
sécurité et la finalité. Pas de rôle. Pas de permission. L'autorité se résolvait déjà côté serveur à
chaque requête, donc les groupes ont hérité gratuitement de l'indépendance vis-à-vis des
identifiants. Le travail consistait à *préserver* cette propriété, qu'une nouvelle classe de tests
fixe désormais de trois manières.

Le lendemain, il s'est avéré que quelque chose de bien plus grave tenait dans une seule ligne.

`TenantContext.BypassTenantFilter` était défini comme `=> IsSuperAdmin`. Le rôle de plateforme et
« lire les lignes de tous les clubs » étaient donc la même propriété — un Super Admin pouvait lire
l'effectif, les compétitions, les rencontres et les résultats de n'importe quel club. Ce n'est pas
la vocation du rôle. Un Super Admin gère le côté commercial des clubs hébergés sur un domaine
multi-locataire : abonnement, domaine, fonctionnalités. Si un club est sur le domaine principal, le
Super Admin ne devrait voir que son **nom**.

Les deux propriétés sont maintenant séparées. `IsSuperAdmin` est le rôle de plateforme, accordant
une portée de configuration sur les clubs d'un domaine locataire et aucune portée sur les données,
nulle part. `BypassTenantFilter` supprime tous les filtres de locataire et n'est activé **que** par
de la maintenance sans utilisateur derrière — amorçage, migrations, tests. Rien d'accessible depuis
une requête HTTP ne l'active.

Quatre autres endroits accordaient chacun indépendamment de la portée aux Super Admins et ont dû
suivre : le garde de permissions et le garde d'administration des compétitions ont cessé de renvoyer
vrai pour ce rôle, les données d'amorçage ont gagné un club sur le domaine principal comme cible des
tests de confidentialité, et le filtre de requête des compétitions a gagné une clause explicite
`IsSuperAdmin && ClubId == null`.

Cette dernière a fait surgir un bug latent qui mérite d'être nommé. Laisser les compétitions à
l'échelle de la plateforme être appariées par `c.ClubId == tenant.ClubId` repose sur le fait qu'un
null en apparie un autre — ce qui se trouve être vrai avec le fournisseur InMemory qu'utilisent les
tests, et jamais en SQL, où `NULL = NULL` est inconnu. Un bug de correction dépendant du fournisseur,
trouvé uniquement parce que le code alentour était en cours de réécriture.

Un nouveau DTO rend la fuite irreprésentable plutôt que simplement vérifiée : chaque champ de
configuration est nullable et tous valent null pour un club du domaine principal, et le type ne
porte les membres, ligues, coupes et classements sous aucune forme, pour aucun club. Les
compétitions à l'échelle de la plateforme refusent désormais franchement les clubs du domaine
principal, puisqu'une telle compétition expose nécessairement les joueurs inscrits d'un club.

## Restaient deux questions, tranchées le samedi

Si la plateforme ne peut pas voir les membres d'un club, pourquoi décide-t-elle des sports qu'il
pratique ? Et pourquoi un club ne peut-il pas exister sans que la plateforme le crée ?

Les deux sont passées au club. L'affectation des sports est devenue une permission de club — une
vraie cette fois, alors qu'elle avait précédemment été retirée précisément *parce qu'elle* était
réservée au Super Admin, ce qui en faisait une permission qu'un club pouvait accorder et qui serait
malgré tout refusée. Le catalogue reste propriété de la plateforme : un club choisit les sports
qu'il pratique, il ne peut pas en inventer un dont la plateforme n'a jamais entendu parler.

La création de club est devenue accessible à tout utilisateur connecté, qui devient le premier Admin
du club, sur le domaine principal — ce qui résout l'anomalie où un Super Admin créait un club puis se
retrouvait immédiatement incapable de le configurer.

Le handler qui affecte un sport avait besoin d'un contrôle qu'il n'utilisait pas : il prend un
identifiant de club dans le corps de la requête, ce qui était inoffensif quand seul un Super Admin
pouvait l'appeler, et devient une brèche inter-locataires dès l'instant où l'appelant détient une
permission limitée à un club. Le club du corps est désormais confronté à celui du jeton, avec un test
nommé pour exactement cela. Et `CreateClubRequest` a perdu son champ `InitialAdminUserId` — laisser
un appelant désigner le premier Admin permettrait à n'importe qui de faire d'un inconnu l'Admin d'un
club qu'il n'a jamais demandé, et un premier Admin peut inviter et promouvoir. Supprimer le champ
rend cela irreprésentable plutôt que simplement validé.

La semaine s'est terminée sur 268 tests d'API et 181 tests de front end, tous au vert.
