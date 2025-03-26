#!/bin/bash

BACKUP_DIR="/srv/backups"
RETENTION_DAYS=30

echo "--> Deleting backups older than $RETENTION_DAYS days..."
find "$BACKUP_DIR" -type f -mtime +$RETENTION_DAYS -exec rm {} \;

echo "--> Cleanup complete!"
