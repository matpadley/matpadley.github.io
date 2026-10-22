---
title: "Removing a Committed Password from Git History"
date: 2026-10-21T12:00:00+01:00
draft: false
tags: ["git", "security", "secrets", "docker"]
categories: ["articles"]
summary: "I committed a database password in appsettings.json. Here's how I moved it into a Docker secret, and how to scrub it from history with git-filter-repo."
---

While adding an API-key-protected endpoint to a side project, I noticed a real database connection string — password included — sitting in `appsettings.json`, committed to git. Deleting it in a new commit isn't enough: the password stays in every earlier commit. This is how I fixed both the current code and the history.

## Step 1: stop it happening again

First, get the secret out of the code. In `docker-compose.yml` I replaced the inline value with a Docker secret read from a file that is never committed:

```yaml
services:
  app:
    secrets:
      - ConnectionStrings__DefaultConnection

secrets:
  ConnectionStrings__DefaultConnection:
    file: ./secrets/connection_string.txt   # never commit
```

Add `secrets/` to `.gitignore`, then put the connection string in that file. ASP.NET Core can read it with:

```csharp
builder.Configuration.AddKeyPerFile("/run/secrets/", optional: true);
```

`AddKeyPerFile` turns the file name `ConnectionStrings__DefaultConnection` into the config key `ConnectionStrings:DefaultConnection`, so no other code changes. In `appsettings.json` I left a harmless placeholder (`Password=changeme`).

## Step 2: rotate the password

Do this before anything else. Rewriting history doesn't guarantee nobody has a copy — it may already have been cloned, cached or scraped. Treat the old password as compromised and change it on the database.

## Step 3: rewrite history with git-filter-repo

`git filter-branch` is deprecated; [`git-filter-repo`](https://github.com/newren/git-filter-repo) is the recommended tool.

Work in a fresh mirror clone so your normal checkout is untouched:

```bash
git clone --mirror <remote-url> myrepo-mirror.git
cd myrepo-mirror.git
brew install git-filter-repo
```

Create a replacements file **outside the repo** (single quotes stop the shell mangling special characters like `^`):

```bash
printf '%s\n' 'THE-OLD-PASSWORD==>REMOVED' > ../replacements.txt
```

Then rewrite every commit on every branch and tag:

```bash
git filter-repo --replace-text ../replacements.txt
```

Check the password is really gone — this should print nothing:

```bash
git log --all -p -S'THE-OLD-PASSWORD' | head
```

## Step 4: force-push

`filter-repo` removes the `origin` remote as a safety measure, so add it back and push:

```bash
git remote add origin <remote-url>
git push --force --all
git push --force --tags
```

Every commit from the first affected one onward gets a new hash, so anyone else with a clone must re-clone. Otherwise they can push the old history straight back.

## Step 5: clean up the remote

- GitHub keeps old commits reachable by hash, in cached views, and via forks and pull-request refs (`refs/pull/*`). Ask GitHub Support to run garbage collection and purge cached views.
- Check for forks and open PRs that still contain the old commits.
- Delete your old local checkout and re-clone.
- Delete `replacements.txt` — it contains the password.

## The lesson

Rewriting history is clean-up, not protection. The real fix is rotating the credential and making sure secrets never reach the repo: keep them in an ignored file or a secret store, and leave only placeholders in anything committed.
