#!/bin/bash

# AFFiNE Backup Script
# This script backs up AFFiNE application data & database and removes old backups (older than 30 days).

# Configuration
BACKUP_DIR="/srv/backups"
APP_DATA_DIR="/root/.affine/storage"
DB_BACKUP_DIR="/srv/backups"
DB_NAME="${DB_NAME}"
DB_USER="${DB_USER}"
BACKUP_RETENTION_DAYS=14
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M")

# Ensure backup directories exist
mkdir -p "$BACKUP_DIR" "$DB_BACKUP_DIR"

# Backup Application Data
APP_BACKUP_FILE="$BACKUP_DIR/affine-appdata-backup-${TIMESTAMP}.tar.gz"
echo "--> Backing up AFFiNE application data to $APP_BACKUP_FILE..."
tar -czf "$APP_BACKUP_FILE" -C "$APP_DATA_DIR" .

# Backup Database
DB_BACKUP_FILE="$DB_BACKUP_DIR/affine-db-backup-${TIMESTAMP}.sql.gz"
echo "--> Backing up PostgreSQL database to $DB_BACKUP_FILE..."
pg_dump -U "$DB_USER" -d "$DB_NAME" | gzip > "$DB_BACKUP_FILE"

# Delete backups older than 14 days
echo "--> Removing backups older than $BACKUP_RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -name "affine-appdata-backup-*.tar.gz" -mtime +$BACKUP_RETENTION_DAYS -delete
find "$DB_BACKUP_DIR" -type f -name "affine-db-backup-*.sql.gz" -mtime +$BACKUP_RETENTION_DAYS -delete

echo "--> Backup completed successfully!"

exit 0
