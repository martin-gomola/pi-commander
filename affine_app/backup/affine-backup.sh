#!/bin/bash

# Paths
BACKUP_DIR="/srv/backups"
APPDATA_SRC="/root/.affine/storage"
DB_CONTAINER="affine_postgres"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DATE=$(date +"%Y-%m-%d_%H-%M")

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

echo "--> Backing up application data..."
tar -czf "$BACKUP_DIR/affine-appdata-$DATE.tar.gz" -C "$APPDATA_SRC" .

echo "--> Backing up database..."
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_DIR/affine-db-$DATE.sql.gz"

echo "--> Backup completed!"
