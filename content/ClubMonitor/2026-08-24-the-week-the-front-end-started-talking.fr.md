---
title: "La semaine où le front end s'est mis à parler à l'API"
date: 2026-08-28T11:00:00+01:00
draft: false
description: "Un moteur de permissions a été supprimé une semaine après sa construction, neuf écrans sont passés sur un seul système de design, l'application a reçu une pile de conteneurs et de l'intégration continue, et la connexion a enfin appelé une vraie API — où Safari l'a bloquée pour une raison qui ressemblait seulement à du CORS."
summary: "Un moteur de permissions a été supprimé une semaine après sa construction, neuf écrans sont passés sur un seul système de design, l'application a reçu une pile de conteneurs et de l'intégration continue, et la connexion a enfin appelé une vraie API — où Safari l'a bloquée pour une raison qui ressemblait seulement à du CORS."
tags:
  - club-monitor
  - weeknotes
  - avalonia
  - dotnet
  - docker
  - github-actions
  - design-system
source:
  - 2026-08-24-1300-remove-user-groups-and-enforce-platform-features.md
  - 2026-08-24-1600-development-role-sign-in.md
  - 2026-08-26-1500-friendlier-sign-in-screen.md
  - 2026-08-26-1730-shared-control-styles-across-every-screen.md
  - 2026-08-27-0740-land-friendlier-login-branch.md
  - 2026-08-27-1030-club-admin-gates-on-members-leagues-cups.md
  - 2026-08-27-1450-login-page-register-link.md
  - 2026-08-27-1730-create-club-only-shell-for-new-accounts.md
  - 2026-08-27-1924-github-actions-build-and-test-workflows.md
  - 2026-08-27-1945-dev-api-endpoint-and-container-stack.md
  - 2026-08-27-2015-compose-migrate-service.md
  - 2026-08-27-2040-verify-compose-stack.md
  - 2026-08-28-1035-front-end-auth-calls-the-api.md
  - 2026-08-28-1100-browser-head-served-over-http.md
---

La semaine précédente s'était achevée sur un moteur de permissions, une frontière de multi-location
redessinée et un front end incapable de se connecter à quoi que ce soit. Cette semaine a supprimé le
premier, conservé la deuxième et enfin comblé le troisième manque — l'application crée maintenant de
vrais comptes contre une vraie API tournant dans un conteneur.

## Supprimer une fonctionnalité trois jours après l'avoir construite

Les groupes d'utilisateurs sont partis. L'autorisation au niveau du club repose de nouveau sur deux
rôles : `Admin` et `Standard`, avec Super Admin comme rôle exclusivement de plateforme, lié à aucun
club.

Deux choses l'ont tranché. La première est un argument de conception direct — une ligue de club a un
ou deux administrateurs, et un Admin de club détenait déjà toutes les permissions implicitement, de
sorte que les paquets de permissions résolvaient un problème de délégation que ce produit n'a pas.
Les écrans du front end pour cela tournaient sur des lignes fictives codées en dur et rien ne les
consommait.

La seconde mérite qu'on s'en souvienne. **`ManageGroups` était un chemin d'auto-escalade.** Un membre
Standard ne détenant que `ManageGroups` pouvait modifier son propre groupe pour y ajouter
`ManageAdmins`, puis se promouvoir Admin de club à part entière — anéantissant tout l'intérêt de
« lui donner de l'autorité sans en faire un Admin ». Un moteur de permissions dont l'octroi le plus
faible reconstitue le rôle le plus fort n'est pas un modèle plus fin, c'est le même modèle avec des
étapes en plus.

Ce qui a été conservé, parce que c'est indépendant des groupes : la frontière de multi-location du
Super Admin, les domaines de locataires, les fonctionnalités de club et le libre-service de club. La
règle désormais écrite noir sur blanc est que si un club a un jour vraiment besoin d'une délégation
plus fine, la réponse est un rôle nommé, pas un moteur de permissions.

Le même passage a rendu **les interrupteurs de fonctionnalités de plateforme réels**. Ils
existaient, mais la méthode qui les vérifie n'avait aucun appelant en dehors de son propre test — un
Super Admin pouvait donc désactiver les Compétitions pour un club hébergé, recevoir un `200` et ne
rien changer du tout. Des contrôles se trouvent maintenant sur la création d'une ligue ou d'une
coupe, l'inscription de joueurs, la programmation de rencontres, l'enregistrement de résultats, la
lecture d'un tableau de classement, chaque écriture de personnalisation, et l'adhésion à une
compétition à l'échelle de la plateforme.

Deux détails dans la façon dont ces refus se lisent :

- Le garde des compétitions renvoie un **verdict** — `Allowed`, `NotAdmin` ou `FeatureDisabled` —
  plutôt qu'un booléen, de sorte qu'une fonctionnalité désactivée signale `FeatureNotEnabled` au
  lieu de « vous n'êtes pas administrateur ». Dire à un Admin de club légitime qu'il manque
  d'autorité l'envoie chasser un problème de permission qui n'existe pas.
- **Le classement est contrôlé sur le club qui possède la compétition**, pas sur celui de
  l'appelant, afin que la règle tienne encore pour un lecteur public sans club une fois la
  publication anonyme en place.

## Se connecter en tant que quelqu'un, avant qu'il n'y ait quelqu'un

Rien de ce qui dépend du rôle ne pouvait être vu ni démontré, car le service d'authentification de
substitution acceptait n'importe quel identifiant et frappait une session sans aucun rôle. La page
de connexion a donc reçu un panneau **Development sign-in** : une identité fictive par rôle ; en
presser une frappe une session localement et route vers le shell exactement comme le ferait une
vraie connexion.

C'est le genre de commodité qui part en production par accident, donc les garde-fous sont
délibérément superposés :

- Chaque identité et le drapeau `IsEnabled` sont à l'intérieur d'un `#if DEBUG`. Une build Release ne
  contient aucune identité de test, et la liste vide replie le panneau.
- La commande **revérifie `IsEnabled`** au lieu de faire confiance au fait que le panneau était
  masqué, de sorte qu'une build Release ne peut pas être amenée à ouvrir une session fictive par un
  appel direct.
- Le jeton d'accès est la sentinelle `development-sign-in-not-issued-by-the-api` — sans la forme
  d'un JWT, rejeté par l'API, de sorte qu'une session de développement n'atteint jamais que des
  écrans alimentés par des données locales.
- Un test de garde relit le fichier source **en tant que texte** et échoue si une identité sort du
  garde. Une exécution de tests est elle-même une build Debug, donc le *comportement* Release ne peut
  pas être exécuté — seul le garde qui le produit peut être vérifié. Vérifié à la main aussi : les
  adresses fictives apparaissent trois fois dans l'assembly Debug et zéro fois dans le Release.

La session a gagné `Role` et `IsSuperAdmin` comme deux champs distincts, à dessein. Super Admin est
un rôle de plateforme détenu hors de tout club, donc cette identité porte un rôle de club null — les
réunir en un seul champ aurait recréé la confusion que la semaine précédente avait passé une journée
à démêler.

## L'application a cessé de ressembler à un formulaire

L'écran de connexion était une colonne centrée de contrôles Fluent sans style, et c'était la
première chose que voyait quiconque. Il est devenu une composition en deux parties : un panneau de
marque sombre avec le nom de l'application, un titre et des marquages de terrain dessinés, à côté du
formulaire de connexion.

Choisi par la largeur, jamais par la plateforme — une `ContainerQuery` à 720px, correspondant au
point de rupture du shell lui-même. Au-dessus, le panneau de marque est une colonne ancrée à gauche ;
en dessous, la même matière se replie en un bandeau d'en-tête au-dessus du formulaire.

Quelques décisions dans le détail :

- L'écusson et les icônes œil/œil barré sont des ressources `StreamGeometry` dessinées dans la vue,
  pas des images, afin qu'elles se recolorent avec le thème et restent nettes à toute densité.
- Les marquages de terrain sont ancrés au centre et aux bords du panneau plutôt qu'à des coordonnées
  fixes, de sorte qu'ils conservent leurs proportions à toute hauteur de fenêtre.
- La révélation du mot de passe est **une seule zone masquée dont le caractère de masque change** —
  Avalonia traite `'\0'` comme « ne pas masquer » — plutôt qu'une seconde zone contenant une copie en
  clair du mot de passe. Se connecter remasque, afin qu'un mot de passe révélé ne reste pas à
  l'écran pour la personne suivante.
- L'indication d'invitation dit que les comptes commencent par une invitation d'un administrateur de
  club, ce qui est le modèle de compte réel, plutôt qu'un lien « s'inscrire » vers un parcours qui
  n'existait pas encore. (Il existait dès le jeudi. Voir plus bas.)

Deux jours plus tard, ce traitement a atteint les neuf autres écrans — et l'important, c'est que le
système a été **extrait, pas répliqué**. L'écran de connexion avait déclaré ses styles dans son
propre bloc `UserControl.Styles`, ce qui convient pour un écran et pas pour neuf : les
personnalisations de marque des clubs remplacent les clés de pinceau partagées, donc un style qui
code ses valeurs en dur est un écran que la personnalisation ne peut pas atteindre. Chaque style de
contrôle et chaque géométrie d'icône ont migré vers `Themes/Controls.axaml`, fusionné **après**
`FluentTheme` parce qu'une collection de styles s'applique dans l'ordre et que ces règles existent
pour l'emporter sur celles de Fluent. Fluent peint les états d'un bouton sur son `ContentPresenter`
interne, pas sur le bouton, donc tout ce qui doit survivre au survol est défini via la partie du
template.

Ensuite, vingt déclarations `Opacity="0.7"` réparties dans neuf fichiers sont devenues une classe
`muted`. L'opacité atténuait l'élément *et* ce qui transparaissait derrière, de sorte que la même
ligne secondaire se lisait différemment sur une carte de ligne et sur le fond de page. Huit copies
d'un titre 28px semi-gras sont devenues `pageTitle` ; dix zones de texte ont pris une classe
`field` ; les valeurs en lecture seule ont reçu leur propre classe pour qu'une valeur que personne
ne peut changer cesse de ressembler à une que quelqu'un a oublié de finir.

Deux garde-fous sont venus avec. Un test statique échoue sur toute vue qui atténue du texte avec
`Opacity`, déclare une couleur hexadécimale littérale ou fixe une taille de police d'affichage — on
corrige un échec en ajoutant la classe manquante, pas en supprimant l'assertion. Et un test de
planche de rendu rend chaque écran en PNG à 1200px et 390px avec de vrais pixels Skia, ce qui a
gagné sa place immédiatement : c'est ainsi qu'on a attrapé les cartes de ligne laissant un espace
mort sous un contenu aligné en haut.

## Un contrôle qui n'était jamais réellement fermé

`CupsViewModel` avait une propriété `IsClubAdmin`, et elle n'était atteignable que depuis XAML, et
seulement en partie. Les boutons de ligne liaient `IsVisible="{Binding IsClubAdmin}"` à l'intérieur
d'un `DataTemplate` — ce qui se lie à l'élément de la ligne, pas au view model de la page, et ne
résolvait donc rien. Les liaisons compilées ne sont pas activées dans ce projet, donc l'échec était
**silencieux à l'exécution** plutôt qu'à la compilation, et les boutons s'affichaient pour tout le
monde.

Corriger la liaison n'aurait pas suffi non plus. Un `IsVisible` local l'emporte sur le setter de
style, donc une liaison par bouton aurait mis en échec la container query à 500px qui masque ces
boutons sur les dispositions étroites. Et la disposition étroite atteint la modification et la
suppression par tape et balayage, où il n'y a aucun bouton à masquer — de sorte qu'un contrôle
purement visuel laisse les deux routes grandes ouvertes.

Le contrôle vit désormais à deux endroits à dessein : sur le *conteneur* des actions de ligne en
XAML, qui atteint le view model de la page via `$parent[ItemsControl]` et laisse la container query
maîtresse des boutons eux-mêmes, et dans les commandes du view model, ce qui ferme les routes
gestuelles. Super Admin n'est délibérément pas une porte d'entrée — un rôle null se lit comme
non-administrateur, avec un test par view model qui le fixe.

## Un compte, un club, et un endroit où les mettre

L'API prenait en charge l'auto-inscription depuis l'arrivée de son handler d'inscription, et tout
utilisateur connecté pouvait créer un club et en devenir le premier Admin. Le front end n'atteignait
ni l'un ni l'autre : la seule route vers un compte était une invitation sur laquelle l'application
ne pouvait pas agir.

L'inscription est arrivée avec une page derrière le lien — nom affiché, e-mail, mot de passe,
confirmation, et un code d'invitation facultatif. Un seul bouton de révélation gouverne les deux
champs de mot de passe, car une confirmation que l'utilisateur ne peut pas lire ne confirme rien.
L'habillage de marque a migré vers deux vues partagées sans contexte de données afin que
l'inscription porte la même matière sans en faire une seconde copie.

Deux détails de contrat comptaient. `RegisterAsync` renvoie un résultat de connexion, parce que l'API
connecte directement un compte fraîchement créé — le succès se termine donc là où se termine une
connexion, plutôt que de renvoyer l'utilisateur retaper les identifiants qu'il vient de choisir. Et
une case d'invitation vide est envoyée comme `null`, pas `""`, parce que l'API lit un code présent
mais vide comme un code fourni et erroné.

Ce qui a immédiatement créé un nouveau problème : s'inscrire crée un compte, pas une adhésion, de
sorte qu'un utilisateur tout neuf atterrissait dans une application à cinq sections sans rien
derrière aucune section. Le shell ne construit désormais **que** la page Créer un club pour une
telle session, en fait la seule entrée de la barre latérale et du menu burger, et **refuse les
sections de club dans `Navigate` en plus de les masquer** — masquer un bouton n'est pas la même chose
que fermer une route.

La page commence par le message plutôt que par le formulaire : un accueil nommant l'utilisateur, puis
ce qui manque et pourquoi. Avec le reste de la navigation disparu, « pourquoi tout manque-t-il ? » est
la première question à laquelle l'écran doit répondre. Le sport se choisit dans le catalogue maître
plutôt qu'il ne se saisit, car l'API prend un *identifiant* de sport, et le sélecteur distingue
« encore en chargement » de « rien à afficher ».

Créer un club fait de son créateur son premier Admin, donc le shell lève une session mise à jour et
tout le shell est reconstruit autour d'elle — c'est ce qui met le reste de la navigation à l'écran.

## Intégration continue, conteneurs, et une étape de migration qui n'est pas une étape de démarrage

Deux workflows de build et de test ont atterri, un par moitié du dépôt, tous deux sur les pull
requests vers `main` et tous deux filtrés par chemins. Il n'y a délibérément aucun déclencheur
`push` : chaque changement atteint `main` via une PR, donc une exécution déclenchée par un push ne
ferait que dupliquer celle que la PR avait déjà.

Ils nomment des fichiers de projet individuels plutôt que la solution, car la solution porte aussi
les têtes iOS et Android — iOS exige un runner macOS avec un Xcode correspondant, et Android n'est
pas une cible prise en charge. La suite d'interface tourne en **Debug à dessein** : les identités de
connexion de développement sont derrière `#if DEBUG`, et les tests qui les couvrent aussi. La moitié
Release de ce garde est couverte par la build Release de la tête desktop dans le même job. La tête
navigateur est **publiée**, pas seulement compilée, car le SDK WebAssembly effectue son bundling et
sa réédition de liens natifs au moment de la publication — et la sortie publiée est exactement ce
que servira App Service.

Une note pour plus tard : comme les deux workflows utilisent des filtres de chemins, une PR
purement documentaire n'en exécute aucun. S'ils deviennent des vérifications requises, une exécution
filtrée est signalée comme ignorée et peut bloquer la PR.

En parallèle, le front end a enfin appris où se trouve son API. `ApiConfiguration.BaseUrl` résout
d'abord une constante compilée, puis l'environnement du processus (bureau uniquement), puis une
valeur localhost par défaut — et l'environnement ne peut pas être l'unique source, car un processus
iOS n'hérite d'aucun environnement du shell qui le lance et le navigateur n'a pas d'environnement
d'OS du tout. Une cible MSBuild écrit la constante depuis `CLUBMONITOR_API_URL` à la compilation.

Deux détails MSBuild ont coûté une build chacun et sont désormais commentés sur place. Un attribut
`Include` reconnaît les jokers, si bien que `public const string? Url` — qui contient un `?` — a été
lu comme un joker d'un caractère ne correspondant à aucun fichier, et la ligne a disparu de la sortie
générée sans avertissement. Et `IntermediateOutputPath` n'est pas défini avant l'exécution des cibles
communes, donc le calculer dans le corps du projet plaçait le fichier généré dans le répertoire du
projet, où le glob par défaut le compilait une seconde fois.

L'API a reçu une pile de conteneurs : SQL Server, l'API et — après réflexion — les migrations comme
service à part entière. La première version faisait migrer l'API elle-même au démarrage derrière un
interrupteur réservé au développement, car l'image d'exécution ne porte pas de SDK. Cela
fonctionnait, mais plaçait l'étape de schéma dans le chemin de démarrage de l'API : une migration
échouée se manifestait comme une API qui ne démarre pas plutôt que comme une étape avec son propre
code de sortie, et l'image livrée *pouvait* migrer une base de données, à une variable
d'environnement près de le faire là où elle ne devrait pas.

Désormais un service `migrate` à usage unique exécute un bundle de migrations EF puis se termine, et
l'API en dépend avec `condition: service_completed_successfully`, de sorte qu'une migration échouée
arrête la pile au lieu de livrer une API sur un schéma à moitié construit. La chaîne de connexion est
une ancre YAML partagée par les deux, si bien que ce qui migre et ce qui lit ne peuvent pas dériver
vers des bases différentes. Le code de migration au démarrage a été **supprimé** plutôt que
désactivé — le garde est l'absence du chemin de code, pas un contrôle d'environnement dessus.

Ces deux entrées se terminaient toutes deux par « non vérifié », car Docker ne tournait pas quand
elles ont été écrites. La pile a depuis été exercée de bout en bout : SQL devient sain, `migrate`
s'exécute et sort en 0, puis l'API démarre ; les huit migrations s'appliquent ; une seconde
exécution signale « No migrations were applied » et sort en 0 ; vingt tables existent dans la base
selon `sqlcmd`, et pas seulement selon le journal. Et le chemin d'échec — la raison d'être du service
— sort en 1 avec un mot de passe volontairement erroné, retenant l'API.

## Puis elle s'est réellement connectée

`ApiAuthenticationService` a remplacé le service de substitution dans toutes les têtes. La connexion
et l'inscription publient maintenant vers les vrais points de terminaison à l'URL de base compilée.

Les deux points de terminaison répondent avec la même forme, donc les deux passent par un lecteur de
réponse unique ; les différences entre se connecter et s'inscrire vivent dans l'API. La session est
construite à partir de la réponse plutôt que supposée — le rôle stocké est celui détenu dans le club
auquel le jeton est **rattaché**, pas le premier club listé, car un utilisateur présent dans deux
clubs peut y détenir des rôles différents et le jeton n'autorise que dans l'un d'eux. Un compte sans
club obtient un rôle null, ce qui met le shell sur son unique appui « créer un club ».

Rien ne lève d'exception sur un bouton de connexion. Chaque échec revient sous forme de résultat
portant un code : le code d'erreur stable de l'API quand elle a répondu, et quatre que ce client
lève quand elle n'a pas pu être interrogée — `NetworkUnavailable`, `TooManyAttempts` pour un 429
auquel le limiteur de débit répond sans corps, `UnexpectedResponse` pour un corps qui n'a pas pu
être analysé ou un 200 auquel manque quelque chose dont une session a besoin, et
`TwoFactorRequired`. L'annulation propre à l'appelant se propage toujours, car quitter un écran
n'est pas un identifiant refusé.

Le double facteur est **signalé, pas complété**. Un mot de passe correct sur un compte à double
facteur produit un jeton en attente et aucun jeton d'accès, et il n'existe pas encore d'écran pour
présenter le défi, donc cela remonte comme une erreur lisible plutôt que comme une session qui
n'existe pas.

Un bug discret est tombé du câblage : le view model de connexion mappait un code d'erreur que l'API
n'a jamais envoyé, de sorte qu'un mauvais mot de passe aurait affiché le générique « quelque chose
s'est mal passé » plutôt que « identifiants incorrects ».

## Et puis Safari a refusé, pour une raison qui n'était pas du CORS

Cliquer sur **Sign in** dans la tête WebAssembly échouait dans Safari avec :

```
Fetch API cannot load http://localhost:5239/api/auth/login due to access control checks.
```

Cela se lit comme du CORS, et ce n'en est pas. La politique a été vérifiée contre le conteneur en
cours d'exécution depuis les deux origines — le préflight renvoie `204` avec les bons en-têtes
d'autorisation, et un vrai `POST` obtient une réponse JSON normale avec les en-têtes CORS attachés.

Le blocage réel est du **contenu mixte**, côté client, avant même que la requête ne soit envoyée. Le
profil de lancement de la tête navigateur ouvrait `https://localhost:7169` en premier, et le point
de terminaison d'API compilé dans la tête est `http://localhost:5239`. La spécification Secure
Contexts considère `http://localhost` comme potentiellement digne de confiance et Chrome l'exempte
du blocage du contenu mixte ; WebKit non, et rapporte le refus avec sa formulation générique
« access control checks ». Rien n'atteint Kestrel, donc aucun changement côté serveur n'aurait pu y
remédier.

Le correctif consiste à servir la tête navigateur en **http** — `http://localhost:5235` arrive
maintenant en premier dans le profil de lancement. C'est un correctif et non un contournement :
l'API n'a pas d'écouteur https dans la pile locale, `http://localhost` reste un contexte sécurisé
dans tous les navigateurs, donc les passkeys et les autres chemins de connexion y fonctionnent
toujours, et l'alternative aurait été du https des deux côtés sans aucun gain.

La semaine s'est achevée sur 255 tests d'API et 280 tests d'interface headless au vert, une
application qui crée de vrais comptes contre une API conteneurisée, et une intégration continue qui
exécute les deux suites à chaque pull request.
