#!/usr/bin/env bash

# Shared Pi-Commander modules: service catalog, operator, backup policy, probes.

PC_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PC_REPO_DIR="${PC_REPO_DIR:-$(cd "$PC_LIB_DIR/../.." && pwd)}"
PC_DOCKER_DIR="${PC_DOCKER_DIR:-$PC_REPO_DIR/docker}"
PC_BACKUP_DIR="${PC_BACKUP_DIR:-/srv/backups}"
PC_DOCKER_DATA="${PC_DOCKER_DATA:-/srv/docker}"
PC_NPM_DATA="${PC_NPM_DATA:-$PC_DOCKER_DATA/nginx-proxy-manager}"
PC_FULL_RETENTION_DAYS="${PC_FULL_RETENTION_DAYS:-49}"
PC_SSL_RETENTION_DAYS="${PC_SSL_RETENTION_DAYS:-30}"
PC_LOG_FILE="${PC_LOG_FILE:-/var/log/pi-commander-backup.log}"

PC_RED='\033[0;31m'
PC_GREEN='\033[0;32m'
PC_YELLOW='\033[1;33m'
PC_BLUE='\033[0;34m'
PC_NC='\033[0m'

pc_log() { echo -e "${PC_GREEN}[$(date +'%H:%M:%S')] $1${PC_NC}"; }
pc_info() { echo -e "${PC_BLUE}[$(date +'%H:%M:%S')] $1${PC_NC}"; }
pc_warn() { echo -e "${PC_YELLOW}[$(date +'%H:%M:%S')] $1${PC_NC}"; }
pc_error() { echo -e "${PC_RED}[$(date +'%H:%M:%S')] $1${PC_NC}"; exit 1; }

pc_backup_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$PC_LOG_FILE"
}

pc_require_root() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        pc_error "This command must be run as root (use sudo)"
    fi
}

pc_service_dir() {
    printf '%s/%s\n' "$PC_DOCKER_DIR" "$1"
}

pc_service_exists() {
    [ -f "$(pc_service_dir "$1")/docker-compose.yml" ]
}

pc_service_container() {
    case "$1" in
        nginx-proxy-manager) printf '%s\n' "nginx-proxy-manager" ;;
        adguard) printf '%s\n' "adguard-home" ;;
        twingate) printf '%s\n' "twingate-connector" ;;
        cloudflare-ddns) printf '%s\n' "cloudflare-ddns" ;;
        duckdns) printf '%s\n' "duckdns" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

pc_service_label() {
    case "$1" in
        nginx-proxy-manager) printf '%s\n' "Nginx Proxy Manager" ;;
        adguard) printf '%s\n' "AdGuard Home" ;;
        twingate) printf '%s\n' "Twingate Connector" ;;
        cloudflare-ddns) printf '%s\n' "Cloudflare DDNS" ;;
        duckdns) printf '%s\n' "DuckDNS" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

pc_service_is_configured() {
    [ -s "$(pc_service_dir "$1")/.env" ] || [ -s "$(pc_service_dir "$1")/stack.env" ]
}

pc_catalog_services() {
    find "$PC_DOCKER_DIR" -mindepth 1 -maxdepth 1 -type d -exec sh -c \
        'for d do [ -f "$d/docker-compose.yml" ] && basename "$d"; done' sh {} + | sort
}

pc_configured_services() {
    local service
    pc_catalog_services | while IFS= read -r service; do
        if pc_service_is_configured "$service"; then
            printf '%s\n' "$service"
        fi
    done
}

pc_active_ddns_service() {
    if pc_service_is_configured "cloudflare-ddns"; then
        printf '%s\n' "cloudflare-ddns"
    elif pc_service_is_configured "duckdns"; then
        printf '%s\n' "duckdns"
    fi
}

pc_core_deploy_services() {
    printf '%s\n' "nginx-proxy-manager" "adguard" "twingate"
    pc_active_ddns_service
}

pc_compose() {
    local service="$1"
    shift
    local service_dir
    service_dir="$(pc_service_dir "$service")"

    if ! pc_service_exists "$service"; then
        pc_warn "Service directory or compose file not found: $service"
        return 1
    fi

    (
        cd "$service_dir"
        if [ -f "stack.env" ]; then
            docker compose --env-file stack.env "$@"
        elif [ -f ".env" ]; then
            docker compose --env-file .env "$@"
        else
            docker compose "$@"
        fi
    )
}

pc_compose_config() {
    local service="$1"
    local service_dir tmp_dir
    service_dir="$(pc_service_dir "$service")"

    if ! pc_service_exists "$service"; then
        pc_warn "Service directory or compose file not found: $service"
        return 1
    fi

    (
        cd "$service_dir"
        if [ -f "stack.env" ]; then
            docker compose --env-file stack.env config
        elif [ -f ".env" ]; then
            docker compose --env-file .env config
        elif [ -f ".env.example" ]; then
            tmp_dir="$(mktemp -d)"
            cp docker-compose.yml "$tmp_dir/docker-compose.yml"
            cp .env.example "$tmp_dir/.env"
            (
                cd "$tmp_dir"
                docker compose config
            )
            rm -rf "$tmp_dir"
        else
            docker compose config
        fi
    )
}

pc_deploy_service() {
    local service="$1"
    pc_info "Deploying $(pc_service_label "$service")"
    pc_compose "$service" pull 2>&1 | grep -v "Warning" || true
    pc_compose "$service" up -d --remove-orphans
    pc_log "$(pc_service_label "$service") deployed"
}

pc_upgrade_service() {
    local service="$1"
    pc_info "Upgrading $(pc_service_label "$service")"
    pc_compose "$service" pull
    pc_compose "$service" up -d --force-recreate --remove-orphans
    pc_log "$(pc_service_label "$service") upgraded"
}

pc_update_service() {
    local service="$1"
    pc_deploy_service "$service"
    pc_compose "$service" ps
}

pc_deploy_all() {
    local service
    pc_info "Deploying core infrastructure services"
    pc_core_deploy_services | while IFS= read -r service; do
        [ -n "$service" ] && pc_deploy_service "$service"
    done
    pc_log "Core infrastructure deployed"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

pc_upgrade_all() {
    local service
    pc_info "Upgrading configured services"
    pc_configured_services | while IFS= read -r service; do
        pc_upgrade_service "$service"
    done
    pc_log "Configured services upgraded"
}

pc_start_all() {
    local service
    pc_info "Starting configured services"
    pc_configured_services | while IFS= read -r service; do
        pc_compose "$service" up -d
    done
    pc_log "Configured services started"
}

pc_test_config_all() {
    local service failed=0
    while IFS= read -r service; do
        printf "%s: " "$service"
        if pc_compose_config "$service" >/dev/null 2>&1; then
            echo -e "${PC_GREEN}valid${PC_NC}"
        else
            echo -e "${PC_RED}invalid${PC_NC}"
            failed=1
        fi
    done < <(pc_catalog_services)
    return "$failed"
}

pc_test_pull_all() {
    local service
    pc_catalog_services | while IFS= read -r service; do
        pc_info "Pulling $(pc_service_label "$service")"
        pc_compose "$service" pull || true
    done
}

pc_test_dry_run_all() {
    local service
    pc_catalog_services | while IFS= read -r service; do
        pc_info "Testing $(pc_service_label "$service")"
        pc_compose "$service" up -d
        sleep 5
        pc_compose "$service" ps
        pc_compose "$service" down
    done
}

pc_container_exists() {
    docker ps -a --format "{{.Names}}" | grep -q "^$1$"
}

pc_container_logs_errors() {
    local container="$1"
    if pc_container_exists "$container"; then
        echo ""
        echo "=== $container ==="
        docker logs "$container" --tail 20 2>&1 | grep -iE "error|fail|fatal" || echo "No errors found"
    fi
}

pc_probe_docker() {
    printf "  Docker:            "
    if systemctl is-active docker >/dev/null 2>&1; then
        echo -e "${PC_GREEN}OK${PC_NC}"
    else
        echo -e "${PC_RED}FAIL${PC_NC}"
    fi
}

pc_probe_http() {
    local label="$1"
    local url="$2"
    printf "  %-18s" "$label:"
    if curl -sf "$url" >/dev/null 2>&1; then
        echo -e "${PC_GREEN}OK${PC_NC}"
    else
        echo -e "${PC_RED}FAIL${PC_NC}"
    fi
}

pc_probe_dns() {
    printf "  %-18s" "AdGuard DNS:"
    if dig @localhost google.com +short >/dev/null 2>&1; then
        echo -e "${PC_GREEN}OK${PC_NC}"
    else
        echo -e "${PC_RED}FAIL${PC_NC}"
    fi
}

pc_run_health() {
    echo "=== System Health Check ==="
    echo ""
    echo "Docker Status:"
    pc_probe_docker
    echo ""
    echo "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}"
    echo ""
    echo "Service Health:"
    pc_probe_http "NPM Admin" "http://localhost:81/api"
    pc_probe_dns
    pc_probe_http "AdGuard Web" "http://localhost:3001"
    echo ""
    echo "Disk Usage:"
    df -h /srv/docker 2>/dev/null || df -h /
    echo ""
    echo "Memory Usage:"
    free -h | grep -E "Mem|Swap"
    echo ""
}

pc_list_config_status() {
    local service
    pc_catalog_services | while IFS= read -r service; do
        if pc_service_is_configured "$service"; then
            echo "OK $service configured"
        else
            echo "MISSING $service .env"
        fi
    done
}

pc_list_container_errors() {
    local service container
    pc_catalog_services | while IFS= read -r service; do
        container="$(pc_service_container "$service")"
        pc_container_logs_errors "$container"
    done
}

pc_create_full_backup() {
    pc_require_root
    mkdir -p "$PC_BACKUP_DIR"

    local timestamp backup_file
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_file="$PC_BACKUP_DIR/pi-commander-$timestamp.tar.gz"

    pc_backup_log "Creating backup: $backup_file"
    tar -czf "$backup_file" \
        --exclude='*.log' \
        --exclude='*/logs/*' \
        --exclude='*/cache/*' \
        "$PC_DOCKER_DATA/nginx-proxy-manager" \
        "$PC_DOCKER_DATA/adguard" \
        "$PC_DOCKER_DIR"/*/.env \
        2>/dev/null || true

    if [ ! -f "$backup_file" ]; then
        pc_error "Backup creation failed"
    fi

    pc_backup_log "Backup created: $backup_file ($(du -h "$backup_file" | cut -f1))"
    find "$PC_BACKUP_DIR" -name "pi-commander-*.tar.gz" -mtime +"$PC_FULL_RETENTION_DAYS" -delete
    pc_backup_log "Backup complete. Total backups: $(find "$PC_BACKUP_DIR" -name "pi-commander-*.tar.gz" | wc -l)"
    printf '%s\n' "$backup_file"
}

pc_create_ssl_backup() {
    pc_require_root
    mkdir -p "$PC_BACKUP_DIR/ssl-certs"

    if [ ! -d "$PC_NPM_DATA" ]; then
        pc_error "Nginx Proxy Manager data directory not found: $PC_NPM_DATA"
    fi

    local timestamp backup_file
    timestamp="$(date +%Y%m%d-%H%M%S)"
    backup_file="$PC_BACKUP_DIR/ssl-certs/npm-ssl-backup-$timestamp.tar.gz"

    pc_backup_log "Creating SSL backup: $backup_file"
    tar -czf "$backup_file" \
        -C / \
        "srv/docker/nginx-proxy-manager/data/database.sqlite" \
        "srv/docker/nginx-proxy-manager/letsencrypt" \
        2>/dev/null || pc_warn "Some SSL files may not exist, continuing"

    if [ ! -f "$backup_file" ]; then
        pc_error "SSL backup creation failed"
    fi

    pc_backup_log "SSL backup created: $backup_file ($(du -h "$backup_file" | cut -f1))"
    find "$PC_BACKUP_DIR/ssl-certs" -name "npm-ssl-backup-*.tar.gz" -mtime +"$PC_SSL_RETENTION_DAYS" -delete
    pc_backup_log "SSL backup complete. Total SSL backups: $(find "$PC_BACKUP_DIR/ssl-certs" -name "npm-ssl-backup-*.tar.gz" | wc -l)"
    printf '%s\n' "$backup_file"
}

pc_list_ssl_backups() {
    local dir="${1:-$PC_BACKUP_DIR/ssl-certs}"
    echo ""
    echo "Available backups in $dir:"
    echo "================================================"

    if [ ! -d "$dir" ]; then
        pc_warn "Backup directory not found: $dir"
        return 0
    fi

    local backups
    backups="$(find "$dir" -name "npm-ssl-backup-*.tar.gz" -type f | sort -r)"
    if [ -z "$backups" ]; then
        pc_warn "No backups found"
        return 0
    fi

    local index=1 backup filename size mtime
    while IFS= read -r backup; do
        filename="$(basename "$backup")"
        size="$(du -h "$backup" | cut -f1)"
        mtime="$(stat -f %Sm -t "%Y-%m-%d %H:%M:%S" "$backup" 2>/dev/null || stat -c %y "$backup" 2>/dev/null)"
        echo "$index. $filename"
        echo "   Size: $size"
        echo "   Date: $mtime"
        echo "   Path: $backup"
        echo ""
        index=$((index + 1))
    done <<< "$backups"
}

pc_restore_full_backup() {
    local backup_file="$1"
    pc_require_root
    [ -f "$backup_file" ] || pc_error "Backup file not found: $backup_file"
    pc_info "Restoring full backup: $backup_file"
    docker ps -q | xargs -r docker stop
    tar -xzf "$backup_file" -C /
    pc_start_all
    pc_log "Full restore complete"
}

pc_restore_ssl_backup() {
    local backup_file="$1"
    pc_require_root
    [ -f "$backup_file" ] || pc_error "Backup file not found: $backup_file"

    pc_info "Selected backup: $backup_file"
    pc_info "Size: $(du -h "$backup_file" | cut -f1)"

    echo ""
    pc_warn "This will OVERWRITE existing SSL certificates and NPM database."
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r confirm
    if [ "$confirm" != "yes" ]; then
        pc_info "Restore cancelled"
        return 0
    fi

    pc_info "Stopping Nginx Proxy Manager"
    pc_compose "nginx-proxy-manager" down 2>/dev/null || docker stop nginx-proxy-manager 2>/dev/null || true

    if [ -d "$PC_NPM_DATA" ]; then
        local current_backup="$PC_NPM_DATA-backup-$(date +%Y%m%d-%H%M%S)"
        pc_info "Creating backup of current data: $current_backup"
        cp -r "$PC_NPM_DATA" "$current_backup"
    fi

    pc_info "Restoring backup"
    tar -xzf "$backup_file" -C /
    chown -R root:root "$PC_NPM_DATA"

    pc_info "Starting Nginx Proxy Manager"
    pc_compose "nginx-proxy-manager" up -d
    sleep 3

    if docker ps --format "{{.Names}}" | grep -q "^nginx-proxy-manager$"; then
        pc_log "SSL restore complete"
    else
        pc_error "Nginx Proxy Manager failed to start. Check logs: docker logs nginx-proxy-manager"
    fi
}
