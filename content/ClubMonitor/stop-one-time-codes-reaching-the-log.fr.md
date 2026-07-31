---
title: "Empêcher les Codes à Usage Unique d'Atteindre le Log Hors Développement"
date: 2026-07-31T09:30:00+01:00
draft: false
description: "Les émetteurs en mode log-only pour le double facteur étaient enregistrés inconditionnellement, si bien qu'en production chaque code aurait été écrit dans le log applicatif. Un commentaire n'est pas un contrôle."
summary: "Les émetteurs en mode log-only pour le double facteur étaient enregistrés inconditionnellement, si bien qu'en production chaque code aurait été écrit dans le log applicatif. Un commentaire n'est pas un contrôle."
tags:
  - club-monitor
  - dotnet
  - security
  - two-factor
  - configuration
---

## Le défaut

`Program.cs` enregistrait les émetteurs en mode log-only inconditionnellement :

```csharp
// Staging et production doivent enregistrer un vrai fournisseur ici...
builder.Services.AddScoped<IEmailSender, LoggingEmailSender>();
builder.Services.AddScoped<ISmsSender, LoggingSmsSender>();
```

Chaque environnement les héritait, donc un déploiement aurait écrit **chaque code de double facteur dans le log applicatif et OpenTelemetry** — annulant le second facteur pour quiconque pouvait lire les logs, tout en semblant fonctionner parfaitement. La seule protection était un commentaire, et un commentaire n'est pas un contrôle.

## La correction

La sélection de l'émetteur est désormais pilotée par la configuration avec des gardes au démarrage dans `NotificationExtensions`. L'idée directrice est qu'**une valeur par défaut non sécurisée doit être impossible, et tout opt-out doit être explicite** :

- Les fournisseurs `Logging` sont **refusés hors de Development** — l'application lève une exception au démarrage avec un message actionnable plutôt que de démarrer dans un état qui fuit.
- Hors de Development, un fournisseur **non défini** est une erreur, pas une valeur par défaut. C'est la moitié importante : le bug d'origine était un repli silencieux, donc le silence doit maintenant échouer bruyamment.
- La livraison peut être désactivée n'importe où, mais uniquement en indiquant `None`. Cela enregistre `UnavailableEmailSender`/`UnavailableSmsSender`, qui rapportent `IsConfigured = false` et **lèvent une exception** si invoqués — supprimer silencieusement un code bloquerait un utilisateur sans laisser de trace.
- `Smtp` est refusé au démarrage quand `Host` ou `FromAddress` est manquant, puisqu'il ne pourrait jamais délivrer.

`IEmailSender`/`ISmsSender` ont acquis `IsConfigured` pour que le cas de blocage soit géré correctement plutôt que par exception :

- `ConfigureTwoFactorHandler` refuse de laisser un utilisateur *activer* un facteur que ce déploiement ne peut pas délivrer.
- `SendTwoFactorCodeHandler` retourne une erreur de validation propre au lieu de laisser l'émetteur non disponible lever une exception.

`SmtpEmailSender` a été ajouté pour qu'il existe un vrai chemin de production, utilisant le client SMTP de la BCL (sans nouvelle dépendance). Sa journalisation omet délibérément le corps du message, qui contient le code.

## Vérification

Les tests unitaires couvrent les gardes (62 au total, contre 50 auparavant), mais les gardes ont aussi été exercées contre un vrai hôte — la tentative précédente n'avait rien exécuté silencieusement, parce que `timeout` n'existe pas sur macOS et que les greps correspondaient à un log vide. Refait correctement :

| Configuration | Résultat |
|---|---|
| Production + `Logging` (le bug d'origine) | refus de démarrer |
| Production, rien de configuré | refus de démarrer |
| Production + `None` explicite | démarré, health 200 |
| Production + `Smtp` entièrement configuré | démarré, health 200 |
| Development (log-only par défaut) | démarré, health 200 |

## Également mis à jour

`infra/main.bicep` a reçu les paramètres de notification (le fournisseur d'email est `None` par défaut, donc un déploiement est sûr mais la 2FA par email est désactivée jusqu'à ce qu'un relay SMTP soit configuré), et `deploy.yml` les transmet. La spec, `CLAUDE.md` et `README` enregistrent les règles, y compris une instruction explicite de ne pas « corriger » un échec au démarrage en réintroduisant une valeur par défaut.

## Non fait

Aucun transport SMS n'est implémenté — il n'y a pas d'équivalent BCL — donc le double facteur par SMS nécessite un fournisseur (Twilio, Azure Communication Services) derrière `ISmsSender`. `SmtpEmailSender` n'a pas été exercé contre un vrai serveur SMTP ; seules sa sélection et sa validation de configuration sont testées.

## Fichiers modifiés

`src/ClubMonitor.Api/Infrastructure/Notifications/*` (interfaces, émetteurs logging, nouveaux émetteurs indisponibles, nouvel émetteur SMTP, options, enregistrement), `Program.cs`, `Handlers/Auth/ConfigureTwoFactorHandler.cs`, `Handlers/Auth/SendTwoFactorCodeHandler.cs`, les deux fichiers appsettings, `infra/main.bicep`, `.github/workflows/deploy.yml`, `Docs/main_spec.md`, `CLAUDE.md`, `README.md`, tests, plus cette entrée.
