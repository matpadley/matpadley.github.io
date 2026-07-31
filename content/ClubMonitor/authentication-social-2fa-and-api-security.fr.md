---
title: "Authentification : Connexion Sociale, Double Facteur et Sécurisation de l'API"
date: 2026-07-29T17:30:00+01:00
draft: false
description: "ASP.NET Core Identity avec tokens JWT bearer, quatre fournisseurs externes et des passkeys utilisées comme second facteur — plus le piège de la version de schéma Identity qui supprime silencieusement la table de passkeys."
summary: "ASP.NET Core Identity avec tokens JWT bearer, quatre fournisseurs externes et des passkeys utilisées comme second facteur — plus le piège de la version de schéma Identity qui supprime silencieusement la table de passkeys."
tags:
  - club-monitor
  - dotnet
  - aspnet-core-identity
  - authentication
  - security
  - passkeys
---

## Ce qui a changé

Ajout d'un écran de connexion et sécurisation de toute l'application derrière celui-ci. L'API est désormais sécurisée par token et l'identité de développement basée sur les en-têtes a disparu.

### La spec d'abord
`Docs/main_spec.md` n'avait pas de section authentification, donc une a été ajoutée (et `CLAUDE.md` mis à jour en conséquence) avant d'écrire du code, conformément à l'accord de travail. Elle répertorie les méthodes de connexion, les règles de double facteur, le modèle de tokens/claims et les deux dérogations décrites ci-dessous.

### Modèle d'identité — `src/ClubMonitor.Api`
- `User` étend désormais `IdentityUser<int>` ; `ClubMonitorDbContext` étend `IdentityDbContext`. `DisplayName`, `IsSuperAdmin` et `Memberships` restent, plus un nouveau `TwoFactorMethod`.
- Nouvelle migration `AddIdentityAuthentication` (utilisateurs/rôles/logins/tokens/claims/passkeys). La base de données de développement a été supprimée et reconstruite.

### Connexion
- **Fournisseurs externes** : Google, Facebook, X (Twitter) et Apple. Chacun ne s'enregistre que si ses credentials sont configurés, donc l'application tourne localement sans aucun et l'écran de connexion n'affiche que les boutons qui fonctionneront.
- **Email + mot de passe** via Identity, avec verrouillage après 5 échecs et un mot de passe d'au moins 10 caractères.
- **Double facteur** sur le chemin mot de passe : **email**, **SMS** ou **passkey**. Email/SMS passent par `IEmailSender`/`ISmsSender` interchangeables ; le développement local journalise le code plutôt que de l'envoyer.
- **Connexion sans mot de passe par passkey** également, qui est le scénario de passkey supporté par le framework.

### Tokens et tenancy
- `JwtTokenService` émet des tokens d'accès portant l'id utilisateur, le club actif et le flag super-admin. Un mot de passe correct avec la 2FA activée ne retourne qu'un **token en attente** de courte durée, refusé partout sauf aux endpoints de complétion du double facteur.
- `CurrentUserMiddleware` ne lit plus `X-User-Id`/`X-Club-Id` ; il construit le contexte tenant à partir des claims de token vérifiés, de sorte qu'un appelant ne peut plus sélectionner un autre tenant en modifiant un en-tête. Le changement de club passe par `/api/auth/select-club/{id}`, qui vérifie l'adhésion côté serveur.

### Interface — `src/ClubMonitor.App`
- Nouvelle `LoginPage` (mot de passe, étape 2FA, passkey, boutons sociaux), `AuthService` gérant la session, et interopérabilité WebAuthn passkey pour le head WASM.
- La racine de l'application affiche l'écran de connexion jusqu'à ce qu'une session soit confirmée et bascule sur le shell à la connexion ; un bouton de déconnexion a été ajouté au shell.
- `ApiClient` envoie désormais le token bearer et **ne retombe plus sur des données d'exemple inventées** — ce repli masquait auparavant une connexion API complètement cassée, donc les échecs se manifestent désormais comme du contenu vide plutôt que fictif.

## Deux dérogations délibérées, toutes deux signalées dans la spec

1. **La passkey comme second facteur n'est pas supportée par ASP.NET Core Identity.** Sa documentation indique que les passkeys sont « traitées comme facteur d'authentification primaire, pas comme second facteur ». Le comportement demandé a été construit directement sur `PerformPasskeyAssertionAsync`, et sa sécurité repose sur `VerifyPasskeyTwoFactorHandler` qui vérifie que l'utilisateur asserté correspond à celui qui a passé l'étape mot de passe — sans cette vérification, n'importe quelle passkey valide terminerait la connexion de n'importe qui. Un test couvre ce cas.
2. **Les résultats publics restent lisibles de façon anonyme.** « Sécuriser l'API » est en conflit avec la règle de domaine existante qu'un Admin peut publier des résultats comme « publics (visibles par tous) ». Les endpoints de classements et de liste de matchs autorisent donc des appelants anonymes et le handler continue d'appliquer la visibilité ; tout le reste nécessite un token. Toutes les *pages* requièrent toujours une connexion.

## Un piège framework qui mérite d'être noté

Identity ne mappe la table de passkeys qu'à partir de la **version de schéma 3** ; les versions 1 et 2 appellent `Ignore` sur l'entité passkey, et **la version 1 est la valeur par défaut**. La version est lue depuis `IdentityOptions.Stores.SchemaVersion` via le *fournisseur de services de l'application*, qu'une factory design-time n'a pas — donc les migrations générées n'avaient pas de table de passkeys même après avoir défini l'option à l'exécution. Corrigé en le définissant dans `Program.cs` pour l'exécution et en donnant à `DesignTimeDbContextFactory` un fournisseur de services via `UseApplicationServiceProvider`. Surcharger la propriété `SchemaVersion` **ne fonctionne pas** : `OnModelCreating` lit les options directement et l'ignore.

## Vérification

- **49 tests NUnit** (contre 27 auparavant) : inscription, règles de mot de passe, réponses identiques pour email inconnu vs mauvais mot de passe, les flux 2FA pour email/SMS/passkey, verrouillage des configurations 2FA invalides, contenu des claims de tokens, et qu'un token en attente n'établit aucun contexte tenant.
- **6 tests Playwright** (contre 3 auparavant) : l'application ne demande aucune donnée de club avant la connexion, l'API retourne 401 sans token, et les résultats publiés ne sont pas derrière 401.
- **Exécuté en direct dans un navigateur** contre SQL Server : connexion → défi 2FA → code lu dans le log de développement → vérifié → tableau de bord chargé avec un appel authentifié à `/api/competitions`.

## Fichiers modifiés

Nouveaux `Handlers/Auth/*`, `Infrastructure/Auth/*`, `Infrastructure/Notifications/*`, `Endpoints/AuthEndpoints.cs`, `Endpoints/EndpointResults.cs` ; modifiés `Domain/User.cs`, `Data/*`, `Endpoints/ApiEndpoints.cs`, `Program.cs`, paramètres de l'application, `infra/main.bicep`, `.github/workflows/deploy.yml` ; nouvelles `Views/LoginPage.*` et `Services/*` dans l'application ; nouveaux tests ; `Docs/main_spec.md`, `CLAUDE.md`, `README.md`.
