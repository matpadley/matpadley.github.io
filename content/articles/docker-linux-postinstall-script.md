---
title: "Docker Linux Post-Install Steps in One Script"
date: 2026-10-26T12:00:00+01:00
draft: false
tags: ["docker", "linux", "devops", "scripting"]
categories: ["articles"]
summary: "Docker's Linux post-installation steps — run without sudo, start on boot, stop logs eating the disk — rolled into a single idempotent shell script."
---

After installing Docker Engine on a fresh Linux box there's a handful of follow-up steps that I always end up doing by hand. They're all in Docker's [Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) page; this article summarises them and then wraps the lot into one script you can paste and run.

## What the steps are

### 1. Run Docker without `sudo`

The Docker daemon binds to a Unix socket owned by `root`, so by default every command needs `sudo`. The persistent fix is to put your user in the `docker` group:

```bash
sudo groupadd docker          # skip if the group already exists
sudo usermod -aG docker $USER
newgrp docker                 # or log out and back in
docker run hello-world
```

> **Heads up:** the `docker` group grants root-level privileges to its members. Docker's page also describes a password-gated alternative (`gpasswd docker` + `newgrp docker`) if you'd rather not leave your user in the group permanently. The script below uses the standard group method.

### 2. Start Docker on boot

On systemd distributions:

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

Debian and Ubuntu already do this by default.

### 3. Stop container logs filling the disk

The default `json-file` logging driver never rotates logs, so a chatty container can eventually exhaust disk space. Docker's page suggests enabling rotation, switching to the `local` driver (which rotates by default), or shipping logs to a remote aggregator. The simplest option is rotation via `/etc/docker/daemon.json`.

### 4. Fix a broken `~/.docker` directory

If you ran Docker with `sudo` before setting up the group, you may see:

```
WARNING: Error loading config file: ... permission denied
```

That's `~/.docker/` owned by root. Either delete it (you lose custom settings) or fix ownership:

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
```

Docker's page also points to [rootless mode](https://docs.docker.com/engine/security/rootless/) if you want to run the daemon without root at all — that's not covered by the script.

## The script

Save it as `docker-postinstall.sh`. It's idempotent, so running it twice is harmless, and it won't overwrite an existing `/etc/docker/daemon.json`.

```bash
#!/usr/bin/env bash
# docker-postinstall.sh — Docker's Linux post-install steps in one go.
# https://docs.docker.com/engine/install/linux-postinstall/
set -euo pipefail

# The user to grant access to (works whether run directly or via sudo)
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  SUDO="sudo"
fi

command -v docker >/dev/null 2>&1 || {
  echo "Docker isn't installed yet — install Docker Engine first." >&2
  exit 1
}

echo "==> Ensuring the 'docker' group exists"
$SUDO groupadd --force docker

echo "==> Adding $TARGET_USER to the 'docker' group"
$SUDO usermod -aG docker "$TARGET_USER"

echo "==> Enabling Docker and containerd on boot"
if command -v systemctl >/dev/null 2>&1; then
  $SUDO systemctl enable docker.service containerd.service
else
  echo "    systemctl not found — skipping (not a systemd distro?)"
fi

echo "==> Configuring log rotation"
DAEMON_JSON=/etc/docker/daemon.json
if [ -e "$DAEMON_JSON" ]; then
  echo "    $DAEMON_JSON already exists — leaving it alone."
  echo "    Add log-opts max-size/max-file yourself if you want rotation."
else
  $SUDO mkdir -p /etc/docker
  $SUDO tee "$DAEMON_JSON" >/dev/null <<'JSON'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
JSON
  $SUDO systemctl restart docker 2>/dev/null || true
fi

echo "==> Fixing ~/.docker ownership (if it was created by sudo)"
if [ -d "$TARGET_HOME/.docker" ]; then
  $SUDO chown -R "$TARGET_USER":"$TARGET_USER" "$TARGET_HOME/.docker"
  $SUDO chmod -R g+rwx "$TARGET_HOME/.docker"
fi

echo
echo "Done. Log out and back in (or run 'newgrp docker') for the group"
echo "change to take effect, then verify with:"
echo "    docker run --rm hello-world"
```

Run it:

```bash
chmod +x docker-postinstall.sh
./docker-postinstall.sh
```

Or straight from a file in one line:

```bash
bash docker-postinstall.sh && newgrp docker
```

## Verifying it worked

```bash
id -nG | tr ' ' '\n' | grep -x docker    # you're in the group
systemctl is-enabled docker              # prints "enabled"
docker run --rm hello-world              # no sudo needed
```

## Notes

- Group membership only applies to new login sessions, which is why `newgrp docker` (or logging out and in) is the last step. On a VM you may need a restart.
- The `10m` × `3` log limits are my own sensible default, not a value from Docker's page — tune to taste, or use `"log-driver": "local"` instead.
- Remember the security trade-off: anyone in the `docker` group can effectively become root on that machine.
