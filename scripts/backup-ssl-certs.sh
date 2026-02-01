#!/bin/bash

################################################################################
# SSL Certificate Backup Script
#
# Purpose: Backs up Nginx Proxy Manager SSL certificates and database
# Schedule: Run daily at 3 AM via cron
# Retention: Keeps last 30 days of backups
#
# Installation:
#   sudo cp backup-ssl-certs.sh /usr/local/bin/
#   sudo chmod +x /usr/local/bin/backup-ssl-certs.sh
#   sudo crontab -e
#   Add: 0 3 * * * /usr/local/bin/backup-ssl-certs.sh >> /var/log/ssl-backup.log 2>&1
################################################################################

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/srv/backups/ssl-certs}"
NPM_DATA="${NPM_DATA:-/srv/docker/nginx-proxy-manager}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
DATE=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${LOG_FILE:-/var/log/ssl-backup.log}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"

log "Starting SSL certificate backup..."

# Check if NPM data directory exists
if [ ! -d "$NPM_DATA" ]; then
    log_error "Nginx Proxy Manager data directory not found: $NPM_DATA"
    exit 1
fi

# Backup file name
BACKUP_FILE="$BACKUP_DIR/npm-ssl-backup-$DATE.tar.gz"

# Create backup
log "Creating backup: $BACKUP_FILE"
tar -czf "$BACKUP_FILE" \
    -C / \
    "srv/docker/nginx-proxy-manager/data/database.sqlite" \
    "srv/docker/nginx-proxy-manager/letsencrypt" \
    2>/dev/null || log_warning "Some files may not exist, continuing..."

# Check if backup was created successfully
if [ -f "$BACKUP_FILE" ]; then
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    log_success "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE)"
else
    log_error "Backup creation failed"
    exit 1
fi

# Clean up old backups
log "Cleaning up backups older than $RETENTION_DAYS days..."
DELETED_COUNT=$(find "$BACKUP_DIR" -name "npm-ssl-backup-*.tar.gz" -mtime +$RETENTION_DAYS -delete -print | wc -l)

if [ "$DELETED_COUNT" -gt 0 ]; then
    log "Deleted $DELETED_COUNT old backup(s)"
else
    log "No old backups to delete"
fi

# Summary
TOTAL_BACKUPS=$(find "$BACKUP_DIR" -name "npm-ssl-backup-*.tar.gz" | wc -l)
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)

log "Backup summary:"
log "  - Total backups: $TOTAL_BACKUPS"
log "  - Total size: $TOTAL_SIZE"
log "  - Backup directory: $BACKUP_DIR"

log_success "SSL certificate backup completed successfully"

# Optional: Send notification (uncomment if you have mail configured)
# echo "SSL certificate backup completed at $(date)" | mail -s "SSL Backup Success" admin@yourdomain.com

exit 0
