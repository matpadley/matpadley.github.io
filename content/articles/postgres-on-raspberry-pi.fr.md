---
title: "Adieu les fichiers JSON : installer Postgres sur un Raspberry Pi pour mes petites applications"
date: 2026-10-09
draft: false
tags: ["postgres", "raspberry-pi", "linux", "databases"]
summary: "Plusieurs de mes petites applications stockaient leurs données dans des fichiers JSON. Je voulais une vraie base de données sans payer un service hébergé, alors j'ai installé Postgres sur un Raspberry Pi. Voici toute la configuration : installation, un utilisateur capable de créer des bases de données, et l'accès à distance depuis mon portable."
---

## Pourquoi s'embêter

Quelques-unes de mes petites applications conservent leurs données dans des fichiers JSON. C'est une très bonne approche pour commencer — aucune configuration, facile à lire, facile à versionner. Mais ça cesse d'être agréable dès qu'on veut interroger les données, modifier deux choses à la fois sans écraser un fichier, ou laisser plusieurs applications (ou plusieurs machines) toucher aux mêmes données.

J'avais un Raspberry Pi qui dormait dans un coin, et Postgres y tourne très bien. Une petite machine sur mon réseau domestique, une base de données par application, et plus de verrouillage de fichiers bricolé à la main.

## Installer Postgres

Sur Raspberry Pi OS (en 64 bits si possible), tout vient directement du gestionnaire de paquets :

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
psql --version
```

La version obtenue dépend de la version de l'OS — Bookworm fournit la 15, Trixie la 17. Pour de petites applications, l'une comme l'autre convient.

Un conseil pratique : placez les données sur un SSD plutôt que sur la carte SD si possible. Une base de données écrit en permanence, et les cartes SD n'apprécient pas du tout.

## Créer un utilisateur administrateur capable de créer des bases de données

Par défaut, seul le super-utilisateur `postgres` peut faire quelque chose d'utile. Je ne voulais pas me connecter avec ce compte à chaque fois, alors j'ai créé un utilisateur normal qui peut créer des bases de données (et d'autres utilisateurs) sans être super-utilisateur :

```bash
sudo -u postgres psql
```

```sql
CREATE ROLE mat WITH LOGIN PASSWORD 'un-long-mot-de-passe-aleatoire' CREATEDB CREATEROLE;
```

Avec cela, `mat` peut exécuter `CREATE DATABASE` et `CREATE ROLE` lui-même. Pour chaque application, je crée ensuite une base de données et un identifiant limité qui en est propriétaire :

```sql
CREATE ROLE myapp WITH LOGIN PASSWORD 'un-autre-long-mot-de-passe';
CREATE DATABASE myapp OWNER myapp;
```

Chaque application a ses propres identifiants : un mot de passe divulgué n'expose donc qu'une seule base de données.

## Autoriser les connexions depuis mon réseau

Par défaut, Postgres n'écoute que sur `localhost`. Deux fichiers de configuration contrôlent l'accès à distance (remplacez `15` par votre numéro de version — `ls /etc/postgresql` vous l'indiquera).

Dans `/etc/postgresql/15/main/postgresql.conf`, définissez :

```
listen_addresses = '*'
```

Dans `/etc/postgresql/15/main/pg_hba.conf`, ajoutez une ligne autorisant les connexions depuis votre réseau domestique uniquement :

```
# TYPE  DATABASE  USER  ADDRESS         METHOD
host    all       all   192.168.1.0/24  scram-sha-256
```

Adaptez le sous-réseau au vôtre. Redémarrez ensuite Postgres et n'ouvrez le port qu'au réseau local :

```bash
sudo systemctl restart postgresql
sudo apt install -y ufw
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw allow OpenSSH
sudo ufw enable
```

## Vérifier que ça fonctionne

Depuis une autre machine du réseau :

```bash
psql -h <adresse-ip-du-pi> -U mat -d postgres
```

Saisissez le mot de passe et vous devriez arriver sur une invite de commande. Essayez `CREATE DATABASE test;` puis `DROP DATABASE test;` pour confirmer que l'utilisateur administrateur remplit bien son rôle.

## L'utiliser depuis une application

Côté application, il suffit d'une chaîne de connexion. Dans une application .NET avec Npgsql, par exemple :

```csharp
var connString = "Host=<adresse-ip-du-pi>;Username=myapp;Password=un-autre-long-mot-de-passe;Database=myapp";
await using var conn = new NpgsqlConnection(connString);
await conn.OpenAsync();
```

Là où je lisais et écrivais un fichier JSON, j'exécute maintenant une requête. Les mêmes données, mais désormais filtrables, sûres en cas d'accès concurrent, et partagées entre plusieurs applications.

## Ne l'exposez pas sur Internet

Je l'ai volontairement limité à mon réseau domestique. Ne redirigez surtout pas le port 5432 sur votre box — un port Postgres ouvert sur Internet est martelé par des robots devineurs de mots de passe en quelques heures. Si vous avez besoin d'un accès depuis l'extérieur, placez le Pi derrière un VPN comme Tailscale, ou utilisez un tunnel SSH (`ssh -L 5433:localhost:5432 pi@<adresse-ip-du-pi>`) et connectez-vous à `localhost:5433`.

## N'oubliez pas les sauvegardes

Un Pi n'est pas un centre de données. Un export nocturne via cron suffit pour commencer :

```bash
0 2 * * * pg_dump -U myapp -h localhost myapp | gzip > /mnt/backup/myapp_$(date +\%F).sql.gz
```

Utilisez un fichier `~/.pgpass` pour que la commande ne s'arrête pas afin de demander un mot de passe, et copiez les exports ailleurs que sur le Pi.

## À retenir

Passer des fichiers JSON à Postgres m'a pris un après-midi : l'installation, un utilisateur administrateur capable de créer des bases de données, une base et un identifiant par application, et quelques lignes de configuration pour laisser entrer mon réseau. Le Pi remarque à peine la charge de petites applications, et je n'ai plus jamais à penser à un fichier JSON corrompu.
