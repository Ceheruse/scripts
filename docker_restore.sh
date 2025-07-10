#!/bin/bash
set -eu

BACKUP_DIR="$HOME/docker_backup/$(date +%Y%m%d-%H%M%S)"
read -rp "📁 Chemin vers le dossier de backup (ex: /home/christophe/docker_backup/20250710-221441) : " BACKUP_DIR

if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "❌ Le dossier $BACKUP_DIR n'existe pas"
  exit 1
fi

echo "📦 Restauration des images Docker..."
for image_tar in "$BACKUP_DIR/images/"*.tar; do
  echo "→ Chargement de $(basename "$image_tar")"
  docker load -i "$image_tar"
done

echo "🗃️ Restauration des volumes Docker..."
for volume_archive in "$BACKUP_DIR/volumes/"*.tar.gz; do
  volume_name=$(basename "$volume_archive" .tar.gz)
  echo "→ Volume: $volume_name"
  docker volume create "$volume_name" >/dev/null
  docker run --rm -v "${volume_name}:/volume" -v "$BACKUP_DIR/volumes:/backup" busybox \
    tar xzf "/backup/${volume_name}.tar.gz" -C /volume
done

echo "✅ Restauration terminée."
