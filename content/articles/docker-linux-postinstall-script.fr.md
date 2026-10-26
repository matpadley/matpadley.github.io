---
title: "Les étapes post-installation de Docker sous Linux en un seul script"
date: 2026-10-26T12:00:00+01:00
draft: false
tags: ["docker", "linux", "devops", "scripting"]
categories: ["articles"]
summary: "Les étapes post-installation de Docker sous Linux — utiliser Docker sans sudo, démarrage au boot, logs qui ne saturent pas le disque — regroupées dans un seul script shell idempotent."
---

Après l'installation de Docker Engine sur une machine Linux toute neuve, il reste une poignée d'étapes que je finis toujours par refaire à la main. Elles figurent toutes dans la page [Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) de Docker ; cet article les résume puis les regroupe dans un script à copier-coller et exécuter.

## Les étapes

### 1. Utiliser Docker sans `sudo`

Le démon Docker écoute sur un socket Unix appartenant à `root`, donc chaque commande nécessite `sudo` par défaut. La solution persistante consiste à ajouter votre utilisateur au groupe `docker` :

```bash
sudo groupadd docker          # inutile si le groupe existe déjà
sudo usermod -aG docker $USER
newgrp docker                 # ou déconnexion/reconnexion
docker run hello-world
```

> **Attention :** le groupe `docker` accorde des privilèges équivalents à root à ses membres. La page de Docker décrit aussi une alternative protégée par mot de passe (`gpasswd docker` + `newgrp docker`) si vous ne voulez pas laisser votre utilisateur dans le groupe en permanence. Le script ci-dessous utilise la méthode standard par groupe.

### 2. Démarrer Docker au boot

Sur les distributions avec systemd :

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

Debian et Ubuntu le font déjà par défaut.

### 3. Empêcher les logs des conteneurs de remplir le disque

Le pilote de logs par défaut `json-file` ne fait jamais de rotation : un conteneur bavard peut finir par saturer le disque. La page de Docker suggère d'activer la rotation, de passer au pilote `local` (qui fait la rotation par défaut) ou d'envoyer les logs vers un agrégateur distant. L'option la plus simple est la rotation via `/etc/docker/daemon.json`.

### 4. Réparer un répertoire `~/.docker` cassé

Si vous avez utilisé Docker avec `sudo` avant de configurer le groupe, vous pouvez voir :

```
WARNING: Error loading config file: ... permission denied
```

C'est que `~/.docker/` appartient à root. Supprimez-le (vous perdez vos réglages personnalisés) ou corrigez les droits :

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
```

La page de Docker renvoie aussi vers le [mode rootless](https://docs.docker.com/engine/security/rootless/) pour exécuter le démon sans root — non couvert par le script.

## Le script

Enregistrez-le sous `docker-postinstall.sh`. Il est idempotent : l'exécuter deux fois est sans danger, et il n'écrase pas un `/etc/docker/daemon.json` existant.

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

Exécution :

```bash
chmod +x docker-postinstall.sh
./docker-postinstall.sh
```

## Vérifier que ça a fonctionné

```bash
id -nG | tr ' ' '\n' | grep -x docker    # vous êtes dans le groupe
systemctl is-enabled docker              # affiche "enabled"
docker run --rm hello-world              # sans sudo
```

## Remarques

- L'appartenance à un groupe ne s'applique qu'aux nouvelles sessions, d'où `newgrp docker` (ou la reconnexion) en dernière étape. Sur une VM, un redémarrage peut être nécessaire.
- Les limites de logs `10m` × `3` sont mon choix par défaut, pas une valeur de la page de Docker — à ajuster, ou utilisez `"log-driver": "local"`.
- Gardez en tête le compromis de sécurité : tout membre du groupe `docker` peut en pratique devenir root sur la machine.
