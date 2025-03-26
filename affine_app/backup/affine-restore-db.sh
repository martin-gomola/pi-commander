#!/bin/bash

# Define variables
AFFINE_CONTAINER=$(docker ps -aqf "name=affine_selfhosted")
DB_CONTAINER="affine_postgres"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
DB_BACKUP_DIR="/srv/backups"

# List available backups
echo "--> Available database backups:"
ls "$DB_BACKUP_DIR" | grep "affine-db" || { echo "No backups found!"; exit 1; }

# Ask user to select a backup
echo "--> Copy and paste the backup name from the list above and press [ENTER]:"
read -r SELECTED_BACKUP

# Validate selection
if [ ! -f "$DB_BACKUP_DIR/$SELECTED_BACKUP" ]; then
    echo "Error: Backup file not found!"
    exit 1
fi

echo "--> Stopping AFFiNE service..."
docker stop "$AFFINE_CONTAINER"

echo "--> Restoring database..."
docker exec -i "$DB_CONTAINER" bash -c "
  dropdb -U $DB_USER $DB_NAME &&
  createdb -U $DB_USER $DB_NAME &&
  gunzip -c < $DB_BACKUP_DIR/$SELECTED_BACKUP | psql -U $DB_USER $DB_NAME
"

echo "--> Database restoration complete."

echo "--> Starting AFFiNE service..."
docker start "$AFFINE_CONTAINER"
