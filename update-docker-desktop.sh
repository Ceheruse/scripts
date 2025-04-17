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

# Fonction pour récupérer la dernière version depuis le site officiel
get_latest_version() {
    local LATEST_VERSION=$(curl -sL https://desktop.docker.com/linux/main/$arch/appcast.xml | grep -oPm1 "(?<=sparkle:shortVersionString=\")[^\"]+")
    echo "$LATEST_VERSION"
}

# Fonction pour récupérer la version installée
get_installed_version() {
    local version_file="/opt/docker-desktop/componentsVersion.json"
    if [[ -f "$version_file" ]]; then
        echo $(grep '"appVersion":' "$version_file" | sed -E 's/.*"appVersion": *"([^"]+)".*/\1/')
    else
        echo "Aucune"
    fi
}

# Étape 1 : Récupération des versions
echo "🔍 Recherche de la dernière version de Docker Desktop..."
latest_version=$(get_latest_version)
if [[ -z "$latest_version" ]]; then
    echo "❌ Impossible de récupérer le numéro de dernière version."
    exit 1
fi
echo "🔄 Dernière version disponible : ${latest_version}"

echo "📦 Vérification de la version installée localement..."
installed_version=$(get_installed_version)
if [[ -z "$installed_version" ]]; then
    echo "❌ Impossible de récupérer le numéro de dernière version."
    exit 1
fi
echo "💻 Version installée : ${installed_version}"

# Étape 2 : Comparaison
if [[ "$installed_version" == "$latest_version" ]]; then
    echo "✅ Docker Desktop est déjà à jour."
    exit 0
fi

# Étape 3 : Confirmation utilisateur
read -p "❗ Une nouvelle version est disponible. Souhaitez-vous l'installer ? (o/N) : " confirm
if [[ ! "$confirm" =~ ^[oOyY]$ ]]; then
    echo "⛔ Mise à jour annulée."
    exit 0
fi

# Étape 4 : Fermeture de Docker Desktop si en cours d'exécution
echo "🛑 Fermeture de Docker Desktop (si lancé)..."
if pgrep -x "Docker Desktop" > /dev/null; then
    echo "⚠️  Docker Desktop est en cours d'exécution, arrêt en cours..."
    pkill -x "Docker Desktop"
    sleep 5  # Attendre que le processus soit bien terminé
else
    echo "✅ Docker Desktop n'est pas en cours d'exécution."
fi

# Étape 5 : Téléchargement du fichier .deb

# Création du dossier temporaire
tmp_dir="/tmp/docker-desktop"
mkdir -p "$tmp_dir"
cd "$tmp_dir"

# deb_url="https://desktop.docker.com/linux/main/${arch}/docker-desktop-${latest_version}-amd64.deb"
deb_url="https://desktop.docker.com/linux/main/${arch}/docker-desktop-${arch}.deb"
deb_file="docker-desktop-${latest_version}.deb"

echo "📥 Téléchargement de la version $latest_version..."
curl -L -o "$deb_file" "$deb_url"

if [[ ! -s "$deb_file" ]]; then
    echo "❌ Échec du téléchargement ou fichier vide."
    exit 1
fi
echo "✅ Téléchargement terminé : $deb_file"
echo "🔍 Vérification de l'intégrité du fichier..."
# Vérification de l'intégrité du fichier
if ! dpkg-deb --info "$deb_file" > /dev/null 2>&1; then
    echo "❌ Le fichier .deb est corrompu ou invalide."
    rm -f "$deb_file"
    exit 1
fi
echo "✅ Le fichier .deb est valide."

# Étape 6 : Installation
echo "⚙️ Installation en cours..."
sudo apt install ./$deb_file -y

# Étape 7 : Vérification
installed_version=$(get_installed_version)
if [[ "$installed_version" == "$latest_version" ]]; then
    echo "🎉 Docker Desktop a été mis à jour avec succès à la version $latest_version."
else
    echo "❌ La mise à jour a échoué."
    exit 1
fi

# Étape 8 : Lancement de Docker Desktop
echo "🚀 Lancement de Docker Desktop..."
systemctl --user start docker-desktop
echo "✅ Docker Desktop est lancé."
echo "🔄 Mise à jour terminée."

# Étape 9 : Nettoyage
echo "🧹 Nettoyage des fichiers temporaires..."
rm -f "$deb_file"
echo "✅ Fichiers temporaires supprimés."
echo "🔚 Script terminé."