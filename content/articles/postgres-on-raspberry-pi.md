---
title: "Ditching JSON Files: Setting Up Postgres on a Raspberry Pi for My Small Apps"
date: 2026-10-09
draft: false
tags: ["postgres", "raspberry-pi", "linux", "databases"]
summary: "A handful of my small apps were storing their data in JSON files. I wanted a proper database without paying for a hosted one, so I put Postgres on a Raspberry Pi. Here's the whole setup: install, a user that can create databases, and remote access from my laptop."
---

## Why bother

A few of my small apps keep their data in JSON files. It's a perfectly good approach to start with — no setup, easy to read, easy to commit. But it stops being fun the moment you want to query anything, update two things at once without clobbering a file, or let more than one app (or one machine) touch the same data.

I had a Raspberry Pi sitting idle, and Postgres runs happily on it. One small box on my home network, one database per app, and no more hand-rolled file locking.

## Install Postgres

On Raspberry Pi OS (64-bit if you can), it's straight from the package manager:

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
psql --version
```

Which version you get depends on the OS release — Bookworm ships 15, Trixie ships 17. For small apps either is fine.

One practical tip: put the data on an SSD rather than the SD card if you can. Databases write constantly, and SD cards don't enjoy that.

## Create an admin user that can create databases

By default only the `postgres` superuser can do anything useful. I didn't want to log in as that every time, so I made a normal user who can create databases (and other users) but isn't a superuser:

```bash
sudo -u postgres psql
```

```sql
CREATE ROLE mat WITH LOGIN PASSWORD 'a-long-random-password' CREATEDB CREATEROLE;
```

With that, `mat` can run `CREATE DATABASE` and `CREATE ROLE` for itself. For each app I then create a database and a limited login that owns just that database:

```sql
CREATE ROLE myapp WITH LOGIN PASSWORD 'another-long-password';
CREATE DATABASE myapp OWNER myapp;
```

Each app gets its own credentials, so one leaked password only exposes one database.

## Allow connections from my network

Out of the box Postgres only listens on `localhost`. Two config files control remote access (swap `15` for your version number — `ls /etc/postgresql` will tell you).

In `/etc/postgresql/15/main/postgresql.conf`, set:

```
listen_addresses = '*'
```

In `/etc/postgresql/15/main/pg_hba.conf`, add a line allowing logins from your home network only:

```
# TYPE  DATABASE  USER  ADDRESS         METHOD
host    all       all   192.168.1.0/24  scram-sha-256
```

Adjust the subnet to match your network. Then restart Postgres and open the port to the LAN only:

```bash
sudo systemctl restart postgresql
sudo apt install -y ufw
sudo ufw allow from 192.168.1.0/24 to any port 5432
sudo ufw allow OpenSSH
sudo ufw enable
```

## Check it works

From another machine on the network:

```bash
psql -h <pi-ip-address> -U mat -d postgres
```

Enter the password and you should land at a prompt. Try `CREATE DATABASE test;` and then `DROP DATABASE test;` to confirm the admin user can do its job.

## Using it from an app

The app's side is just a connection string. In a .NET app with Npgsql, for example:

```csharp
var connString = "Host=<pi-ip-address>;Username=myapp;Password=another-long-password;Database=myapp";
await using var conn = new NpgsqlConnection(connString);
await conn.OpenAsync();
```

Where I used to read and write a JSON file, I now run a query. Same data, but now it's filterable, concurrent-safe, and shared between apps.

## Don't expose it to the internet

I kept this to my home network on purpose. Please don't port-forward 5432 on your router — a Postgres port on the open internet gets hammered by password guessers within hours. If you need access from outside, put the Pi behind a VPN such as Tailscale, or use an SSH tunnel (`ssh -L 5433:localhost:5432 pi@<pi-ip-address>`) and connect to `localhost:5433`.

## Don't forget backups

A Pi is not a data centre. A nightly dump from cron is enough to start with:

```bash
0 2 * * * pg_dump -U myapp -h localhost myapp | gzip > /mnt/backup/myapp_$(date +\%F).sql.gz
```

Use a `~/.pgpass` file so it doesn't stop to ask for a password, and copy the dumps somewhere that isn't the Pi.

## The takeaway

Moving from JSON files to Postgres took an afternoon: install, one admin user that can create databases, one database and login per app, and a couple of lines of config to let my network in. The Pi barely notices the load from small apps, and I never have to think about a corrupted JSON file again.
