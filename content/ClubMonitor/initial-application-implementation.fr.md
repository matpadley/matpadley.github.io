---
title: "Implémentation Initiale de l'Application"
date: 2026-07-29T15:30:00+01:00
draft: false
description: "La première version fonctionnelle : une API minimale .NET 10 avec multi-tenancy EF Core, une interface UNO Platform avec thèmes interchangeables, une couverture NUnit et Playwright, une infrastructure Bicep et un CI."
summary: "La première version fonctionnelle : une API minimale .NET 10 avec multi-tenancy EF Core, une interface UNO Platform avec thèmes interchangeables, une couverture NUnit et Playwright, une infrastructure Bicep et un CI."
tags:
  - club-monitor
  - dotnet
  - ef-core
  - uno-platform
  - minimal-api
  - bicep
---

## Ce qui a changé

Implémentation de la première version fonctionnelle de l'application décrite dans `Docs/main_spec.md` :

### Backend — `src/ClubMonitor.Api` (API minimale .NET 10)
- Modèle code-first EF Core : `Sport`, `Club`, `ClubSport`, `User`, `Membership`, `Competition` (ligue/coupe, appartenant au club ou à la plateforme), `CompetitionClub`, `CompetitionEntry`, `Match`. Migration initiale créée (`Migrations/`).
- Multi-tenancy : `Club` est la frontière de tenant. Les filtres de requête globaux EF Core partitionnent les données par club via `ClubId` ; le Super Admin contourne le filtre ; les compétitions à l'échelle de la plateforme (`ClubId == null`) couvrent plusieurs clubs via `CompetitionClub` ; les compétitions dont les résultats sont définis comme Publics sont lisibles par tous.
- Méthodologie des handlers : une classe de handler distincte par fonctionnalité (`Handlers/…`) renvoyant un `HandlerResult<T>` indépendant du transport ; les endpoints (`Endpoints/ApiEndpoints.cs`) se contentent de lier, déléguer et traduire vers HTTP.
- Règles de domaine : rôles par club, flux d'adhésion par invitation + acceptation et demande d'adhésion + approbation, promotion admin, catalogue de sports géré par le Super Admin, sélection automatique du sport si le club n'en a qu'un, résultats et visibilité réservés aux admins (Privé/Public), classements calculés 3/1/0 avec départage par différence de score.
- Identité : `CurrentUserMiddleware` résout le contexte utilisateur/club à partir des en-têtes `X-User-Id`/`X-Club-Id` — un substitut de développement pour un vrai fournisseur d'authentification ; les handlers ne voient que `ITenantContext`.
- Observabilité : traces/métriques/logs OpenTelemetry avec exportateur sélectionné par la configuration `Telemetry:Exporter` (`console`/`otlp`/`none`) — interchangeable par environnement sans modification de code.

### Tests unitaires — `tests/ClubMonitor.Api.Tests` (NUnit + EF InMemory)
27 tests couvrant le catalogue de sports, les flux d'adhésion, l'isolation des rôles par club, la règle de sélection automatique du sport, les compétitions de plateforme, la visibilité, la planification/résultats des matchs et le calcul des classements. Tous passent.

### Interface — `src/ClubMonitor.App` (UNO Platform, WASM + bureau)
- Architecture de thème/template interchangeable : `Themes/OrganicTheme.xaml` et `Themes/NocturneTheme.xaml` définissent les mêmes clés de ressource ; `ThemeService` permute le dictionnaire fusionné à l'exécution (le Shell a un bouton « Changer de thème ») ; les pages ne changent jamais.
- Écrans conformes à la spec : Dashboard (message d'accueil, actions rapides, ligues et coupes avec étiquettes, prochains matchs, aperçu du classement), Membres (initiales d'avatar, étiquettes rôle/statut), Ligues, Classements, Profil de joueur.
- Navigation adaptative : barre latérale sur grand écran (web/bureau), barre de navigation inférieure sur petit écran (téléphone/tablette) via `AdaptiveTrigger`.
- Client typé `ApiClient` avec repli sur données d'exemple pour que l'interface fonctionne de façon autonome.
- **Note :** l'application UNO cible `net9.0-browserwasm`/`net9.0-desktop` — les templates Uno.Sdk installés ne supportent pas encore .NET 10. La règle .NET 10 s'applique à tout le code backend. À réviser quand Uno publiera les TFMs net10.
- Correction d'un crash au démarrage (initialiseur de type `FpsHelper`) : les bibliothèques natives du moteur de rendu Skia nécessitent `WasmBuildNative=true` ainsi que les workloads `wasm-tools`/`wasm-tools-net9`. Les deux workloads sont installés localement et dans le CI.

### Tests E2E — `tests/ClubMonitor.UiTests` (Playwright + NUnit)
Tests de fumée contre le head WASM en cours d'exécution (l'application se charge sans erreur, le canvas Skia s'affiche, redimensionnement du viewport téléphone/bureau). Localisé via `CLUBMONITOR_APP_URL` ; ignoré si non défini. Les 3 tests passent localement. Le moteur Skia dessine sur un canvas, donc les assertions sont au niveau du document plutôt que des requêtes de texte DOM.

### Infrastructure et CI/CD
- `infra/main.bicep` (+ `.bicepparam` staging/production) : plan App Service, application web API, application web statique pour le head UNO, serveur + base de données Azure SQL. Se compile avec `az bicep build`. Staging et production se déploient dans des abonnements séparés sélectionnés par les credentials OIDC de chaque environnement GitHub.
- `.github/workflows/build-test.yml` : build + NUnit sur PR/push ; job séparé qui démarre l'application WASM et exécute Playwright.
- `.github/workflows/deploy.yml` : connexion OIDC (sans secrets de longue durée), déploiement Bicep, migrations EF, déploiement zip de l'API et du head web. Staging à la fusion sur master ; production via dispatch manuel avec protection d'environnement.

### Contrôle des sources
Dépôt initialisé (`master` par défaut, sans commits directs) ; tout le travail est sur `feature/initial-application` pour revue par PR.

## Pourquoi
Premier passage d'implémentation couvrant toutes les règles obligatoires de `Docs/main_spec.md`.

## Fichiers modifiés
Tout sous `src/`, `tests/`, `infra/`, `.github/workflows/`, `ClubMonitor.slnx`, `.gitignore`, `README.md`, plus cette entrée.
