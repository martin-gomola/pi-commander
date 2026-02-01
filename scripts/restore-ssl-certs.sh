#!/bin/bash

################################################################################
# SSL Certificate Restore Script
#
# Purpose: Restores Nginx Proxy Manager SSL certificates and database from backup
# Usage: sudo ./restore-ssl-certs.sh [backup-file]
#        If no backup file specified, lists available backups
################################################################################

set -e  # Exit on error

# Configuration
BACKUP_DIR="${BACKUP_DIR:-/srv/backups/ssl-certs}"
NPM_DATA="${NPM_DATA:-/srv/docker/nginx-proxy-manager}"
NPM_COMPOSE_DIR="${NPM_COMPOSE_DIR:-$HOME/pi-commander/docker/nginx-proxy-manager}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_info() {
    echo -e "[INFO] $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

# List available backups
list_backups() {
    echo ""
    echo "Available backups in $BACKUP_DIR:"
    echo "================================================"

    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "Backup directory not found: $BACKUP_DIR"
        exit 1
    fi

    BACKUPS=$(find "$BACKUP_DIR" -name "npm-ssl-backup-*.tar.gz" -type f | sort -r)

    if [ -z "$BACKUPS" ]; then
        log_warning "No backups found"
        exit 0
    fi

    INDEX=1
    while IFS= read -r backup; do
        FILENAME=$(basename "$backup")
        SIZE=$(du -h "$backup" | cut -f1)
        DATE=$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "$backup" 2>/dev/null || stat -c %y "$backup" 2>/dev/null)
        echo "$INDEX. $FILENAME"
        echo "   Size: $SIZE"
        echo "   Date: $DATE"
        echo "   Path: $backup"
        echo ""
        INDEX=$((INDEX + 1))
    done <<< "$BACKUPS"

    echo "================================================"
    echo ""
    echo "To restore a backup, run:"
    echo "  sudo $0 <backup-file-path>"
    echo ""
}

# Restore backup
restore_backup() {
    BACKUP_FILE="$1"

    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    log_info "Selected backup: $BACKUP_FILE"
    log_info "Size: $(du -h "$BACKUP_FILE" | cut -f1)"

    echo ""
    log_warning "This will OVERWRITE existing SSL certificates and NPM database!"
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r CONFIRM

    if [ "$CONFIRM" != "yes" ]; then
        log_info "Restore cancelled"
        exit 0
    fi

    # Stop NPM container
    log_info "Stopping Nginx Proxy Manager..."
    if [ -d "$NPM_COMPOSE_DIR" ]; then
        cd "$NPM_COMPOSE_DIR"
        docker-compose down 2>/dev/null || docker compose down 2>/dev/null || true
    else
        docker stop nginx-proxy-manager 2>/dev/null || true
    fi

    # Backup current data (just in case)
    if [ -d "$NPM_DATA" ]; then
        CURRENT_BACKUP="$NPM_DATA-backup-$(date +%Y%m%d-%H%M%S)"
        log_info "Creating backup of current data: $CURRENT_BACKUP"
        cp -r "$NPM_DATA" "$CURRENT_BACKUP"
    fi

    # Extract backup
    log_info "Restoring backup..."
    tar -xzf "$BACKUP_FILE" -C /

    # Fix permissions
    log_info "Fixing permissions..."
    chown -R root:root "$NPM_DATA"

    # Restart NPM
    log_info "Starting Nginx Proxy Manager..."
    if [ -d "$NPM_COMPOSE_DIR" ]; then
        cd "$NPM_COMPOSE_DIR"
        docker-compose up -d 2>/dev/null || docker compose up -d 2>/dev/null
    else
        docker start nginx-proxy-manager 2>/dev/null || true
    fi

    sleep 3

    # Check if NPM is running
    if docker ps | grep -q nginx-proxy-manager; then
        log_success "Restore completed successfully!"
        log_info "Nginx Proxy Manager is now running"
        log_info "Access it at: http://$(hostname -I | awk '{print $1}'):81"
    else
        log_error "NPM failed to start. Check logs: docker logs nginx-proxy-manager"
        exit 1
    fi
}

# Main
if [ $# -eq 0 ]; then
    list_backups
else
    restore_backup "$1"
fi
