---
title: "Los pasos posteriores a la instalación de Docker en Linux en un solo script"
date: 2026-10-26T12:00:00+01:00
draft: false
tags: ["docker", "linux", "devops", "scripting"]
categories: ["articles"]
summary: "Los pasos posteriores a la instalación de Docker en Linux — usar Docker sin sudo, arranque al iniciar, logs que no llenen el disco — reunidos en un único script de shell idempotente."
---

Tras instalar Docker Engine en una máquina Linux recién creada, quedan unos cuantos pasos que siempre acabo haciendo a mano. Todos están en la página [Linux post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) de Docker; este artículo los resume y los reúne en un script que puedes copiar, pegar y ejecutar.

## Los pasos

### 1. Usar Docker sin `sudo`

El demonio de Docker escucha en un socket Unix propiedad de `root`, así que por defecto cada comando necesita `sudo`. La solución persistente es añadir tu usuario al grupo `docker`:

```bash
sudo groupadd docker          # omitir si el grupo ya existe
sudo usermod -aG docker $USER
newgrp docker                 # o cierra sesión y vuelve a entrar
docker run hello-world
```

> **Ojo:** el grupo `docker` concede privilegios equivalentes a root a sus miembros. La página de Docker también describe una alternativa protegida con contraseña (`gpasswd docker` + `newgrp docker`) si prefieres no dejar tu usuario en el grupo de forma permanente. El script de abajo usa el método estándar por grupo.

### 2. Arrancar Docker al iniciar el sistema

En distribuciones con systemd:

```bash
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
```

Debian y Ubuntu ya lo hacen por defecto.

### 3. Evitar que los logs de los contenedores llenen el disco

El controlador de logs por defecto, `json-file`, nunca rota los logs, así que un contenedor muy parlanchín puede acabar agotando el disco. La página de Docker sugiere activar la rotación, cambiar al controlador `local` (que rota por defecto) o enviar los logs a un agregador remoto. La opción más sencilla es la rotación mediante `/etc/docker/daemon.json`.

### 4. Arreglar un directorio `~/.docker` roto

Si ejecutaste Docker con `sudo` antes de configurar el grupo, puede que veas:

```
WARNING: Error loading config file: ... permission denied
```

Es que `~/.docker/` pertenece a root. Bórralo (pierdes la configuración personalizada) o corrige los permisos:

```bash
sudo chown "$USER":"$USER" /home/"$USER"/.docker -R
sudo chmod g+rwx "$HOME/.docker" -R
```

La página de Docker también apunta al [modo rootless](https://docs.docker.com/engine/security/rootless/) para ejecutar el demonio sin root — algo que el script no cubre.

## El script

Guárdalo como `docker-postinstall.sh`. Es idempotente: ejecutarlo dos veces no hace daño, y no sobrescribe un `/etc/docker/daemon.json` existente.

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

Para ejecutarlo:

```bash
chmod +x docker-postinstall.sh
./docker-postinstall.sh
```

## Comprobar que funcionó

```bash
id -nG | tr ' ' '\n' | grep -x docker    # estás en el grupo
systemctl is-enabled docker              # imprime "enabled"
docker run --rm hello-world              # sin sudo
```

## Notas

- La pertenencia a un grupo solo se aplica a sesiones nuevas, por eso `newgrp docker` (o cerrar y abrir sesión) es el último paso. En una VM puede hacer falta reiniciar.
- Los límites de logs de `10m` × `3` son mi valor por defecto, no uno de la página de Docker — ajústalos a tu gusto o usa `"log-driver": "local"`.
- Recuerda el equilibrio de seguridad: cualquiera del grupo `docker` puede, en la práctica, convertirse en root en esa máquina.
