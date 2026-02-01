#!/bin/bash
# Pi-Commander Auto-Deploy Script
# Pulls latest changes and automatically redeploys affected services

set -euo pipefail

# Configuration
REPO_DIR="/home/$(whoami)/pi-commander"
DOCKER_DIR="${REPO_DIR}/docker"
LOCKFILE="/tmp/pi-commander-deploy.lock"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] ✅ $1${NC}"; }
info() { echo -e "${BLUE}[$(date +'%H:%M:%S')] ℹ️  $1${NC}"; }
warn() { echo -e "${YELLOW}[$(date +'%H:%M:%S')] ⚠️  $1${NC}"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] ❌ $1${NC}"; exit 1; }

# Prevent concurrent runs
acquire_lock() {
    if [ -f "$LOCKFILE" ]; then
        error "Another deployment is running. If stuck, remove: $LOCKFILE"
    fi
    touch "$LOCKFILE"
    trap "rm -f $LOCKFILE" EXIT
}

# Get changed files from git
get_changed_services() {
    local current_commit=$(git rev-parse HEAD)
    
    # Pull latest
    info "Pulling latest changes from git..." >&2
    git fetch origin >&2
    
    local new_commit=$(git rev-parse origin/main)
    
    if [ "$current_commit" = "$new_commit" ]; then
        log "Already up to date" >&2
        return 0
    fi
    
    # Get changed files
    local changed_files=$(git diff --name-only "$current_commit" "$new_commit")
    
    info "Changes detected:" >&2
    echo "$changed_files" | sed 's/^/  📝 /' >&2
    
    # Pull changes
    git pull origin main >&2
    
    # Extract affected services (only output this to stdout)
    echo "$changed_files" | grep "^docker/" | cut -d'/' -f2 | sort -u
}

# Deploy a service
deploy_service() {
    local service="$1"
    local service_dir="${DOCKER_DIR}/${service}"
    
    if [ ! -d "$service_dir" ]; then
        warn "Service directory not found: $service_dir"
        return 1
    fi
    
    if [ ! -f "${service_dir}/docker compose.yml" ]; then
        warn "No docker compose.yml in $service_dir"
        return 1
    fi
    
    info "Deploying: $service"
    
    cd "$service_dir"
    
    # Pull latest images
    docker compose pull 2>&1 | grep -v "Warning" || true
    
    # Deploy with environment file if exists
    if [ -f "stack.env" ]; then
        docker compose --env-file stack.env up -d --remove-orphans
    elif [ -f ".env" ]; then
        docker compose --env-file .env up -d --remove-orphans
    else
        docker compose up -d --remove-orphans
    fi
    
    log "✓ $service deployed"
}

# Main deployment
main_deploy() {
    acquire_lock
    
    cd "$REPO_DIR" || error "Repository not found: $REPO_DIR"
    
    log "Starting Pi-Commander auto-deployment"
    
    # Get changed services
    local services=$(get_changed_services)
    
    if [ -z "$services" ] || [ "$services" = "" ]; then
        log "No service changes detected"
        exit 0
    fi
    
    echo ""
    info "Services to deploy:"
    # Filter out empty lines and log messages
    local clean_services=$(echo "$services" | grep -v "^$" | grep -v "^\[" || true)
    
    if [ -z "$clean_services" ]; then
        log "No service changes detected"
        exit 0
    fi
    
    echo "$clean_services" | sed 's/^/  🚀 /'
    echo ""
    
    # Deploy each service
    local deployed=0
    local failed=0
    
    while IFS= read -r service; do
        if [ -n "$service" ]; then
            if deploy_service "$service"; then
                ((deployed++))
            else
                ((failed++))
            fi
        fi
    done <<< "$clean_services"
    
    echo ""
    log "Deployment complete!"
    log "✓ Deployed: $deployed services"
    [ $failed -gt 0 ] && warn "⚠ Failed: $failed services"
    
    # Show status
    echo ""
    info "Container status:"
    docker ps --format "table {{.Names}}\t{{.Status}}" | head -20
}

# Force deploy all services
deploy_all() {
    acquire_lock
    
    cd "$REPO_DIR" || error "Repository not found: $REPO_DIR"
    
    log "Deploying ALL services"
    
    # Pull latest
    git pull origin main
    
    local deployed=0
    local failed=0
    
    for service_dir in "$DOCKER_DIR"/*/; do
        local service=$(basename "$service_dir")
        
        if deploy_service "$service"; then
            ((deployed++))
        else
            ((failed++))
        fi
    done
    
    log "Deployment complete!"
    log "✓ Deployed: $deployed services"
    [ $failed -gt 0 ] && warn "⚠ Failed: $failed services"
}

# Quick status
show_status() {
    cd "$REPO_DIR" || error "Repository not found: $REPO_DIR"
    
    info "Pi-Commander Status"
    echo ""
    
    # Git status
    info "Repository:"
    local current=$(git rev-parse --short HEAD)
    local branch=$(git branch --show-current)
    echo "  Branch: $branch"
    echo "  Commit: $current"
    
    # Check for updates
    git fetch origin --quiet
    local behind=$(git rev-list HEAD..origin/main --count 2>/dev/null || echo "0")
    if [ "$behind" -gt 0 ]; then
        warn "  Behind origin by $behind commits"
    else
        log "  Up to date"
    fi
    
    echo ""
    
    # Container status
    info "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
}

# Show help
show_help() {
    cat << 'EOF'
🚀 Pi-Commander Auto-Deploy

USAGE:
    ./deploy-auto.sh [command]

COMMANDS:
    deploy (default)   Pull git changes and deploy affected services
    deploy-all         Force deploy all services
    status             Show repository and container status
    help               Show this help

WORKFLOW:
    1. Pull latest changes from git
    2. Detect which services changed
    3. Automatically redeploy only affected services

EXAMPLES:
    ./deploy-auto.sh              # Auto-deploy changes
    ./deploy-auto.sh deploy-all   # Deploy everything
    ./deploy-auto.sh status       # Check status

SETUP (First Time):
    # Clone repo
    cd ~
    git clone https://github.com/yourusername/pi-commander.git

    # Configure
    cd pi-commander
    for dir in docker/*/; do
        [ -f "\$dir.env.example" ] && cp "\$dir.env.example" "\$dir.env"
    done
    # Edit .env files with your credentials

    # Deploy
    ./deploy-auto.sh deploy-all

CRON JOB (Optional):
    # Auto-update daily at 3 AM
    0 3 * * * /home/yourusername/pi-commander/deploy-auto.sh >> /var/log/pi-commander-deploy.log 2>&1

EOF
}

# Main
case "${1:-deploy}" in
    deploy)
        main_deploy
        ;;
    deploy-all)
        deploy_all
        ;;
    status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        error "Unknown command: $1. Use 'help' for usage."
        ;;
esac
