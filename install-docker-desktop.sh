#!/bin/bash

set -eu

arch=$(uname -m)
if [[ "$arch" == "x86_64" ]]; then
    arch="amd64"
elif [[ "$arch" == "aarch64" ]]; then
    arch="arm64"
else
    echo "❌ Architecture non supportée : $arch"
    exit 1
fi

# Fonction pour récupérer l'url de téléchargement avec la version en paramètre
get_download_url() {
    local latest_version="$1"
    local xml_url="https://desktop.docker.com/linux/main/amd64/appcast.xml"
    local DOWNLOAD_URL

    DOWNLOAD_URL=$(curl -sL "$xml_url" | \
        grep "<enclosure " | \
        grep "sparkle:shortVersionString=\"$latest_version\"" | \
        grep -oP 'url="\K[^"]+')

    echo "$DOWNLOAD_URL"
}

# Fonction pour récupérer la dernière version depuis le site officiel
get_latest_version() {
    local LATEST_VERSION=$(curl -sL https://desktop.docker.com/linux/main/amd64/appcast.xml | grep -oP "(?<=sparkle:shortVersionString=\")[^\"]+" | sort -V | tail -n 1)
    echo "$LATEST_VERSION"
}

echo "🔧 [1/5] Arrêt de Docker Engine..."
sudo systemctl stop docker
sudo systemctl disable docker

echo "🧹 [2/5] Suppression de Docker Engine et des composants..."
sudo apt remove --purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker /var/lib/containerd /etc/docker
sudo rm -f /var/run/docker.sock
sudo apt autoremove --purge -y

echo "📦 [3/5] Téléchargement de Docker Desktop..."
cd /tmp

latest_version=$(get_latest_version)
deb_url=$(get_download_url "$latest_version")

if [[ -z "$deb_url" ]]; then
    echo "❌ Impossible de récupérer l'URL de téléchargement."
    exit 1
fi

echo "🔗 URL de téléchargement : $deb_url"

deb_file="docker-desktop-${latest_version}.deb"

# wget -q https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -O docker-desktop.deb
curl -L -o "$deb_file" "$deb_url"

echo "📦 [4/5] Installation de Docker Desktop..."
sudo apt install ./$deb_file -y

echo "▶️ [5/5] Démarrage de Docker Desktop..."
systemctl --user daemon-reexec
systemctl --user start docker-desktop
systemctl --user enable docker-desktop

echo "💡 Configuration de la CLI Docker vers Docker Desktop..."
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker-desktop.sock' >> ~/.bashrc
source ~/.bashrc

echo "✅ Docker Desktop est installé et prêt !"
echo "Tu peux le lancer depuis ton menu d'applications."
