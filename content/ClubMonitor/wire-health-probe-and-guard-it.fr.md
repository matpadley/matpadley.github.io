---
title: "Connecter la Sonde de Santé et la Protéger contre les Dérives"
date: 2026-07-30T09:00:00+01:00
draft: false
description: "Pourquoi /health reste anonyme, pourquoi cela valait la peine de le connecter à App Service, et comment l'empêcher d'accumuler des chaînes de connexion comme le font toujours les endpoints de santé."
summary: "Pourquoi /health reste anonyme, pourquoi cela valait la peine de le connecter à App Service, et comment l'empêcher d'accumuler des chaînes de connexion comme le font toujours les endpoints de santé."
tags:
  - club-monitor
  - azure
  - bicep
  - security
  - observability
---

## Pourquoi

Suite à la question de savoir si `/health` devrait être verrouillé. Décision : **le garder anonyme.**

L'endpoint retourne un `{"status":"healthy"}` en dur, il ne divulgue donc rien qu'un attaquant n'apprenne déjà du handshake TLS ou en obtenant un 401 sur toute autre route. Pendant ce temps, les health checks d'App Service, les sondes d'équilibreur de charge et les moniteurs de disponibilité ne peuvent pas présenter un token bearer — le verrouiller supprimerait une capacité opérationnelle sans gain de sécurité, et laisserait le signal de santé ambigu (certaines sondes lisent 401 comme up, d'autres comme down), ce qui ferait passer plus longtemps inaperçues les vraies pannes.

Le vrai risque n'est pas l'endpoint actuel, c'est ce que les endpoints de santé deviennent : ils accumulent la connectivité base de données, l'état des migrations, les versions des dépendances et finalement du texte d'exception contenant des chaînes de connexion. La réponse a donc été de faire *gagner sa place* à l'endpoint et de le cloisonner contre cette dérive.

## Ce qui a changé

- **`infra/main.bicep`** : `healthCheckPath: '/health'` défini sur l'application API. Il était auparavant exposé mais sans sonde — le pire des deux mondes. Vérifié qu'il se compile dans la sortie ARM uniquement sur l'application API (le head web est du contenu statique sans cette route). Nécessite le plan de niveau Basic ou supérieur, que le template utilise déjà (`B1`).
- **`src/ClubMonitor.Api/Program.cs`** : commentaire sur l'endpoint enregistrant pourquoi il est anonyme et que la réponse doit rester une chaîne fixe. Aucun changement de comportement.
- **`Docs/main_spec.md`** et **`CLAUDE.md`** : ajout de la règle que `/health` ne doit jamais rapporter de détails sur la base de données, les dépendances, les migrations, la configuration ou les exceptions ; une vérification de disponibilité nécessitant l'un de ces éléments va sur une **route authentifiée séparée**. Il a également été noté que si la sonde elle-même doit être cachée, cela appartient à la couche **réseau** (restrictions d'accès App Service, ou ingress uniquement via Front Door) plutôt qu'à l'ajout d'une authentification qui casserait la sonde.

## Vérification

- Compilation du Bicep en ARM et assertion de `healthCheckPath=/health` sur le site API et non défini sur le site web.
- 50 tests NUnit passent. Le test Playwright existant `Only_the_sign_in_endpoints_and_health_are_anonymous` fixe déjà le comportement attendu : 401 sur toute la surface API, 200 sur `/health`.

## Fichiers modifiés

`infra/main.bicep`, `src/ClubMonitor.Api/Program.cs`, `Docs/main_spec.md`, `CLAUDE.md`, plus cette entrée.
