---
title: "Tuer un processus par son port sur macOS"
date: 2026-08-21T12:00:00+01:00
draft: false
tags: ["macos", "dotnet", "dev-environment", "terminal"]
categories: ["articles"]
summary: "Un pense-bête pour trouver et tuer ce qui squatte un port sur macOS — écrit après avoir perdu du temps à traquer un environnement de dev dotnet fantôme."
---

Je note celui-ci parce que je viens de perdre dix minutes à essayer de comprendre *lequel* de mes environnements de dev `dotnet` en cours d'exécution bloquait un port, sans réussir à le rattacher à un projet ou à une fenêtre de terminal précise. Plutôt que de creuser sérieusement, je l'ai simplement tué par son port et je suis passé à autre chose — alors voici le pense-bête pour la prochaine fois.

## Trouver ce qui utilise le port

```bash
lsof -i :3000
```

Cette commande liste le processus qui détient le port, avec son PID :

```
COMMAND   PID   USER   FD   TYPE ...
dotnet   1234   mat    23u  IPv4 ...
```

## Le tuer

Une fois que vous avez le PID :

```bash
kill -9 1234
```

Ou allez droit au but en une seule ligne :

```bash
kill -9 $(lsof -ti:3000)
```

Une alternative avec `fuser` :

```bash
sudo fuser -k 3000/tcp
```

## Une remarque sur `-9`

`kill -9` est un arrêt brutal (`SIGKILL`) — il ne laisse aucune chance au processus de faire le ménage. Pour un `dotnet watch` ou un serveur de dev coincé, c'est très bien, mais si vous préférez tenter d'abord un arrêt propre :

```bash
kill -15 1234
```

et n'escaladez vers `-9` que s'il ne répond pas.

## La vraie leçon

Tuer par le port est un contournement, pas une solution. Si ça se reproduit régulièrement, en particulier avec des projets `dotnet`, il vaut la peine de jeter un œil à `dotnet-trace` — ou simplement d'être plus discipliné et d'arrêter les serveurs de dev avec `Ctrl+C` au lieu de fermer les onglets du terminal, ce qui est presque certainement la façon dont je me suis retrouvé avec un processus orphelin au départ.
