#!/bin/bash

# Define variables
AFFINE_CONTAINER=$(docker ps -aqf "name=affine_selfhosted")
BACKUP_DIR="/srv/backups"
RESTORE_PATH="/root/.affine/storage"

# List available backups
echo "--> Available application data backups:"
ls "$BACKUP_DIR" | grep "affine-appdata" || { echo "No backups found!"; exit 1; }

# Ask user to select a backup
echo "--> Copy and paste the backup name from the list above and press [ENTER]:"
read -r SELECTED_BACKUP

# Validate selection
if [ ! -f "$BACKUP_DIR/$SELECTED_BACKUP" ]; then
    echo "Error: Backup file not found!"
    exit 1
fi

echo "--> Stopping AFFiNE service..."
docker stop "$AFFINE_CONTAINER"

echo "--> Restoring application data..."
rm -rf "${RESTORE_PATH:?}"/*  # Remove old data safely
tar -xzf "$BACKUP_DIR/$SELECTED_BACKUP" -C /

echo "--> Application data restoration complete."

echo "--> Starting AFFiNE service..."
docker start "$AFFINE_CONTAINER"
