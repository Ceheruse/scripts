#!/bin/bash
set -eu

# On créé un répertoire de sauvegarde avec la date et l'heure
BACKUP_DIR="$HOME/docker_backup/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR/images" "$BACKUP_DIR/volumes"

echo "📦 Sauvegarde des images Docker..."
docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
  safe_name=$(echo "$image" | tr "/:" "_")
  echo "→ Sauvegarde de $image"
  docker save "$image" -o "$BACKUP_DIR/images/${safe_name}.tar"
done

echo "🗃️ Sauvegarde des volumes Docker..."
for volume in $(docker volume ls -q); do
  echo "→ Volume: $volume"
  docker run --rm -v "${volume}:/volume" -v "$BACKUP_DIR/volumes:/backup" busybox \
    tar czf "/backup/${volume}.tar.gz" -C /volume .
done

echo "✅ Sauvegarde terminée dans : $BACKUP_DIR"
