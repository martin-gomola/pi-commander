#!/bin/bash
# Automated backup script for pi-commander
# Add to crontab: 0 2 * * 0 /path/to/pi-commander/scripts/backup-cron.sh
# Runs weekly on Sunday at 2 AM (before 4 AM reboot)

set -e

# Configuration
BACKUP_DIR="/srv/backups"
RETENTION_DAYS=49  # 7 weeks
LOG_FILE="/var/log/pi-commander-backup.log"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Source directories to backup
DOCKER_DATA="/srv/docker"
PI_COMMANDER_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Create backup directory
mkdir -p "$BACKUP_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting automated backup..."

# Full backup
BACKUP_FILE="$BACKUP_DIR/pi-commander-$TIMESTAMP.tar.gz"

log "Creating backup: $BACKUP_FILE"

tar -czf "$BACKUP_FILE" \
    --exclude='*.log' \
    --exclude='*/logs/*' \
    --exclude='*/cache/*' \
    "$DOCKER_DATA/nginx-proxy-manager" \
    "$DOCKER_DATA/adguard" \
    "$PI_COMMANDER_DIR/docker/*/.env" \
    2>/dev/null || true

# Get backup size
BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
log "Backup created: $BACKUP_FILE ($BACKUP_SIZE)"

# Cleanup old backups (keep 7 weeks)
log "Cleaning up backups older than 7 weeks..."
find "$BACKUP_DIR" -name "pi-commander-*.tar.gz" -mtime +$RETENTION_DAYS -delete

# List remaining backups
BACKUP_COUNT=$(find "$BACKUP_DIR" -name "pi-commander-*.tar.gz" | wc -l)
log "Backup complete. Total backups: $BACKUP_COUNT"

# Optional: Send notification (uncomment and configure)
# curl -s "http://localhost:8040/pi-commander" -d "Backup complete: $BACKUP_SIZE"

log "Automated backup finished successfully"
