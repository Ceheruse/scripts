#!/bin/bash

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
wget -q https://desktop.docker.com/linux/main/amd64/docker-desktop-amd64.deb -O docker-desktop.deb

echo "📦 [4/5] Installation de Docker Desktop..."
sudo apt install ./docker-desktop.deb -y

echo "▶️ [5/5] Démarrage de Docker Desktop..."
systemctl --user daemon-reexec
systemctl --user start docker-desktop
systemctl --user enable docker-desktop

echo "💡 Configuration de la CLI Docker vers Docker Desktop..."
echo 'export DOCKER_HOST=unix:///run/user/$(id -u)/docker-desktop.sock' >> ~/.bashrc
source ~/.bashrc

echo "✅ Docker Desktop est installé et prêt !"
echo "Tu peux le lancer depuis ton menu d'applications."
