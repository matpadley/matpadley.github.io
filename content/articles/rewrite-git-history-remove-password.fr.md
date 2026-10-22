---
title: "Supprimer un mot de passe commité de l'historique Git"
date: 2026-10-21T12:00:00+01:00
draft: false
tags: ["git", "security", "secrets", "docker"]
categories: ["articles"]
summary: "J'avais commité un mot de passe de base de données dans appsettings.json. Voici comment je l'ai déplacé dans un secret Docker, puis effacé de l'historique avec git-filter-repo."
---

En ajoutant un endpoint protégé par clé d'API à un projet perso, j'ai remarqué qu'une vraie chaîne de connexion à la base de données — mot de passe compris — traînait dans `appsettings.json`, commitée dans git. La supprimer dans un nouveau commit ne suffit pas : le mot de passe reste dans tous les commits précédents. Voici comment j'ai corrigé le code actuel et l'historique.

## Étape 1 : empêcher que ça se reproduise

D'abord, sortir le secret du code. Dans `docker-compose.yml`, j'ai remplacé la valeur en dur par un secret Docker lu depuis un fichier qui n'est jamais commité :

```yaml
services:
  app:
    secrets:
      - ConnectionStrings__DefaultConnection

secrets:
  ConnectionStrings__DefaultConnection:
    file: ./secrets/connection_string.txt   # ne jamais commiter
```

Ajoutez `secrets/` au `.gitignore`, puis placez la chaîne de connexion dans ce fichier. ASP.NET Core peut la lire avec :

```csharp
builder.Configuration.AddKeyPerFile("/run/secrets/", optional: true);
```

`AddKeyPerFile` transforme le nom de fichier `ConnectionStrings__DefaultConnection` en clé de configuration `ConnectionStrings:DefaultConnection`, donc aucun autre changement de code. Dans `appsettings.json`, j'ai laissé une valeur factice inoffensive (`Password=changeme`).

## Étape 2 : changer le mot de passe

À faire avant tout le reste. Réécrire l'historique ne garantit pas que personne n'en a une copie — il a pu être cloné, mis en cache ou aspiré. Considérez l'ancien mot de passe comme compromis et changez-le sur la base de données.

## Étape 3 : réécrire l'historique avec git-filter-repo

`git filter-branch` est obsolète ; [`git-filter-repo`](https://github.com/newren/git-filter-repo) est l'outil recommandé.

Travaillez dans un clone miroir tout neuf pour ne pas toucher à votre copie de travail :

```bash
git clone --mirror <url-du-depot> myrepo-mirror.git
cd myrepo-mirror.git
brew install git-filter-repo
```

Créez un fichier de remplacements **en dehors du dépôt** (les apostrophes simples évitent que le shell déforme les caractères spéciaux comme `^`) :

```bash
printf '%s\n' 'ANCIEN-MOT-DE-PASSE==>REMOVED' > ../replacements.txt
```

Puis réécrivez chaque commit de chaque branche et tag :

```bash
git filter-repo --replace-text ../replacements.txt
```

Vérifiez que le mot de passe a bien disparu — la commande ne doit rien afficher :

```bash
git log --all -p -S'ANCIEN-MOT-DE-PASSE' | head
```

## Étape 4 : push forcé

Par sécurité, `filter-repo` supprime le remote `origin` ; remettez-le puis poussez :

```bash
git remote add origin <url-du-depot>
git push --force --all
git push --force --tags
```

Chaque commit à partir du premier concerné reçoit un nouveau hash, donc toute personne ayant un clone doit le recloner. Sinon, elle peut repousser l'ancien historique.

## Étape 5 : nettoyer le dépôt distant

- GitHub conserve les anciens commits accessibles par leur hash, dans des vues en cache, et via les forks et les références de pull requests (`refs/pull/*`). Demandez au support GitHub de lancer un garbage collection et de purger les vues en cache.
- Vérifiez les forks et les PR ouvertes qui contiennent encore les anciens commits.
- Supprimez votre ancien clone local et reclonez.
- Supprimez `replacements.txt` — il contient le mot de passe.

## La leçon

Réécrire l'historique, c'est du nettoyage, pas de la protection. La vraie solution est de changer l'identifiant et de s'assurer que les secrets n'atteignent jamais le dépôt : dans un fichier ignoré ou un gestionnaire de secrets, avec uniquement des valeurs factices dans ce qui est commité.
